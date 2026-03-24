// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { DataTypes } from "../libraries/DataTypes.sol";
import { Errors }    from "../libraries/Errors.sol";

/// @title BountyBoard
/// @notice 协作悬赏合约：发布者锁定奖金 → 贡献者认领 → 验收后自动释放
/// @dev
///   流程：
///   1. 发布者调用 createBounty，锁定奖金（ETH/USDC）
///   2. 贡献者调用 applyBounty 申请
///   3. 发布者调用 assignBounty 选定中标者
///   4. 中标者完成后调用 submitBounty 提交
///   5. 发布者调用 approveBounty 验收 → 奖金自动转给中标者
///   6. 若超过 reviewPeriod 未验收，中标者可调用 claimByTimeout 强制领取
///   7. 发布者可取消（仅 Open 状态）
contract BountyBoard is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    // ─── 常量 ──────────────────────────────────────────────────────────────

    uint64 public constant MIN_REVIEW_PERIOD = 7  days;
    uint64 public constant MAX_REVIEW_PERIOD = 30 days;

    // ─── 存储 ──────────────────────────────────────────────────────────────
    /// @dev 悬赏任务 ID 自增计数器
    uint256 private _nextBountyId;
    /// @dev 悬赏任务 ID => 任务详情
    mapping(uint256 => DataTypes.BountyTask) private _bounties;

    // bountyId => 申请者列表
    mapping(uint256 => address[]) private _applicants;

    // bountyId => 申请者 => 是否已申请
    mapping(uint256 => mapping(address => bool)) private _applied;

    // bountyId => 申请者 => 保证金金额
    mapping(uint256 => mapping(address => uint256)) private _deposits;

    // bountyId => 提交时间戳（用于超时解锁）
    mapping(uint256 => uint64) private _submittedAt;

    // ─── 初始化 ────────────────────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();
        _nextBountyId = 1;
    }

    // ─── 暂停机制 ──────────────────────────────────────────────────────────

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ─── 1. 发布悬赏 ──────────────────────────────────────────────────────

    /// @notice 发布者创建悬赏任务，同时锁定奖金
    /// @param tokenId        关联漫画 Token ID
    /// @param taskType       任务类型（翻译/上色/配音/其他）
    /// @param reward         奖金金额（wei）
    /// @param paymentToken   奖金代币（address(0) = ETH）
    /// @param deadline       截止时间
    /// @param reviewPeriod   验收等待期（7-30天）
    /// @param requirementURI IPFS URI，存储任务详细要求
    function createBounty(
        uint256              tokenId,
        DataTypes.BountyType taskType,
        uint256              reward,
        address              paymentToken,
        uint64               deadline,
        uint64               reviewPeriod,
        string calldata      requirementURI
    ) external payable whenNotPaused returns (uint256 bountyId) {
        if (reward == 0) revert Errors.ZeroAmount();
        if (deadline <= block.timestamp) revert Errors.InvalidParameter("deadline");
        if (reviewPeriod < MIN_REVIEW_PERIOD || reviewPeriod > MAX_REVIEW_PERIOD)
            revert Errors.InvalidReviewPeriod(reviewPeriod, 7, 30);
        if (bytes(requirementURI).length == 0) revert Errors.InvalidParameter("requirementURI");

        // 锁定奖金
        if (paymentToken == address(0)) {
            if (msg.value < reward) revert Errors.InsufficientPayment(msg.value, reward);
        } else {
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), reward);
        }

        bountyId = _nextBountyId++;
        _bounties[bountyId] = DataTypes.BountyTask({
            publisher:      msg.sender,
            tokenId:        tokenId,
            taskType:       taskType,
            status:         DataTypes.BountyStatus.Open,
            reward:         reward,
            paymentToken:   paymentToken,
            assignee:       address(0),
            deadline:       deadline,
            reviewPeriod:   reviewPeriod,
            requirementURI: requirementURI,
            submissionURI:  ""
        });

        emit BountyCreated(bountyId, msg.sender, tokenId, taskType, reward, paymentToken, deadline);
    }

    // ─── 2. 申请悬赏任务 ──────────────────────────────────────────────────────

    /// @notice 贡献者申请认领，需支付赏金 1/10 作为保证金，在调用函数时附带保证金金额
    /// @param bountyId 悬赏任务 ID
    function applyBounty(uint256 bountyId) external payable whenNotPaused {
        DataTypes.BountyTask storage bounty = _bounties[bountyId];
        if (bounty.status != DataTypes.BountyStatus.Open)
            revert Errors.BountyNotOpen(bountyId);
        if (block.timestamp > bounty.deadline)
            revert Errors.BountyDeadlinePassed(bountyId);
        if (_applied[bountyId][msg.sender]) revert Errors.InvalidParameter("alreadyApplied");

        // 计算并校验保证金 (1/10)
        uint256 deposit = bounty.reward / 10;
        if (bounty.paymentToken == address(0)) {
            if (msg.value < deposit) revert Errors.InsufficientPayment(msg.value, deposit);
        } else {
            IERC20(bounty.paymentToken).safeTransferFrom(msg.sender, address(this), deposit);
        }

        _applied[bountyId][msg.sender] = true;
        _applicants[bountyId].push(msg.sender);
        _deposits[bountyId][msg.sender] = deposit;

        emit BountyApplied(bountyId, msg.sender);
    }

    // ─── 3. 指定中标者 ────────────────────────────────────────────────────

    function assignBounty(uint256 bountyId, address assignee) external whenNotPaused {
        DataTypes.BountyTask storage bounty = _bounties[bountyId];
        if (bounty.publisher != msg.sender) revert Errors.NotBountyPublisher(msg.sender, bountyId);
        if (bounty.status != DataTypes.BountyStatus.Open) revert Errors.BountyNotOpen(bountyId);
        if (!_applied[bountyId][assignee]) revert Errors.InvalidParameter("assigneeNotApplied");

        bounty.assignee = assignee;

        emit BountyAssigned(bountyId, assignee);
    }

    // ─── 3.1 保证金退还 ──────────────────────────────────────────────────

    /// @notice 未中标者、或悬赏取消后申请人退还保证金
    function withdrawDeposit(uint256 bountyId) external nonReentrant {
        DataTypes.BountyTask storage bounty = _bounties[bountyId];
        uint256 deposit = _deposits[bountyId][msg.sender];
        if (deposit == 0) revert Errors.ZeroAmount();

        // 只有以下情况可以退还：
        // 1. 悬赏已取消
        // 2. 悬赏已指定中标者且自己不是中标者
        // 3. 悬赏已完成（说明自己肯定不是中标者，因为中标者的保证金在结算时处理，或者这里统一处理非中标者）
        bool canWithdraw = (bounty.status == DataTypes.BountyStatus.Cancelled) ||
                           (bounty.assignee != address(0) && bounty.assignee != msg.sender);

        if (!canWithdraw) revert Errors.Unauthorized();

        _deposits[bountyId][msg.sender] = 0;
        _refund(msg.sender, bounty.paymentToken, deposit);

        emit DepositRefunded(bountyId, msg.sender, deposit);
    }

    // ─── 4. 中标者提交作品 ────────────────────────────────────────────────

    function submitBounty(uint256 bountyId, string calldata submissionURI) external whenNotPaused {
        DataTypes.BountyTask storage bounty = _bounties[bountyId];
        if (bounty.assignee != msg.sender) revert Errors.NotBountyAssignee(msg.sender, bountyId);
        if (bounty.status != DataTypes.BountyStatus.Open) revert Errors.BountyNotOpen(bountyId);
        if (bytes(submissionURI).length == 0) revert Errors.InvalidParameter("submissionURI");

        bounty.status        = DataTypes.BountyStatus.InReview;
        bounty.submissionURI = submissionURI;
        _submittedAt[bountyId] = uint64(block.timestamp);

        emit BountySubmitted(bountyId, msg.sender, submissionURI);
    }

    // ─── 5. 发布者验收 ────────────────────────────────────────────────────

    /// @notice 发布者验收通过，奖金自动转给中标者
    function approveBounty(uint256 bountyId) external nonReentrant {
        DataTypes.BountyTask storage bounty = _bounties[bountyId];
        if (bounty.publisher != msg.sender) revert Errors.NotBountyPublisher(msg.sender, bountyId);
        if (bounty.status != DataTypes.BountyStatus.InReview)
            revert Errors.InvalidParameter("notInReview");

        bounty.status = DataTypes.BountyStatus.Completed;
        _payAssignee(bounty, bountyId);

        emit BountyCompleted(bountyId, bounty.assignee, bounty.reward);
    }

    // ─── 6. 超时强制领取（保护贡献者权益）───────────────────────────────────

    /// @notice 若发布者超过 reviewPeriod 未验收，中标者可强制领取奖金
    function claimByTimeout(uint256 bountyId) external nonReentrant {
        DataTypes.BountyTask storage bounty = _bounties[bountyId];
        if (bounty.assignee != msg.sender) revert Errors.NotBountyAssignee(msg.sender, bountyId);
        if (bounty.status != DataTypes.BountyStatus.InReview)
            revert Errors.InvalidParameter("notInReview");

        uint64 reviewDeadline = _submittedAt[bountyId] + bounty.reviewPeriod;
        if (block.timestamp < reviewDeadline)
            revert Errors.BountyReviewPeriodNotElapsed(bountyId);

        bounty.status = DataTypes.BountyStatus.Completed;
        _payAssignee(bounty, bountyId);

        emit BountyCompletedByTimeout(bountyId, bounty.assignee, bounty.reward);
    }

    // ─── 7. 发布者取消（仅 Open 状态）────────────────────────────────────

    function cancelBounty(uint256 bountyId) external nonReentrant {
        DataTypes.BountyTask storage bounty = _bounties[bountyId];
        if (bounty.publisher != msg.sender) revert Errors.NotBountyPublisher(msg.sender, bountyId);
        if (bounty.status != DataTypes.BountyStatus.Open) revert Errors.BountyNotOpen(bountyId);

        bounty.status = DataTypes.BountyStatus.Cancelled;

        // 退还奖金给发布者
        _refund(bounty.publisher, bounty.paymentToken, bounty.reward);

        emit BountyCancelled(bountyId);
    }

    // ─── 内部支付工具 ─────────────────────────────────────────────────────

    function _payAssignee(DataTypes.BountyTask storage bounty, uint256 bountyId) internal {
        uint256 deposit = _deposits[bountyId][bounty.assignee];
        uint256 total = bounty.reward + deposit;
        _deposits[bountyId][bounty.assignee] = 0;

        if (bounty.paymentToken == address(0)) {
            (bool ok,) = payable(bounty.assignee).call{value: total}("");
            if (!ok) revert Errors.TransferFailed(bounty.assignee, total);
        } else {
            IERC20(bounty.paymentToken).safeTransfer(bounty.assignee, total);
        }
    }

    function _refund(address to, address token, uint256 amount) internal {
        if (token == address(0)) {
            (bool ok,) = payable(to).call{value: amount}("");
            if (!ok) revert Errors.TransferFailed(to, amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    // ─── 查询 ─────────────────────────────────────────────────────────────

    function getBounty(uint256 bountyId) external view returns (DataTypes.BountyTask memory) {
        return _bounties[bountyId];
    }

    function getApplicants(uint256 bountyId) external view returns (address[] memory) {
        return _applicants[bountyId];
    }

    function getApplicantsCount(uint256 bountyId) external view returns (uint256) {
        return _applicants[bountyId].length;
    }

    function hasApplied(uint256 bountyId, address applicant) external view returns (bool) {
        return _applied[bountyId][applicant];
    }

    // ─── UUPS 升级 ────────────────────────────────────────────────────────

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}

    // ─── 事件 ─────────────────────────────────────────────────────────────

    event BountyCreated(
        uint256 indexed bountyId,
        address indexed publisher,
        uint256 tokenId,
        DataTypes.BountyType taskType,
        uint256 reward,
        address paymentToken,
        uint64  deadline
    );
    event BountyApplied(uint256 indexed bountyId, address indexed applicant);
    event BountyAssigned(uint256 indexed bountyId, address indexed assignee);
    event BountySubmitted(uint256 indexed bountyId, address indexed assignee, string submissionURI);
    event BountyCompleted(uint256 indexed bountyId, address indexed assignee, uint256 reward);
    event BountyCompletedByTimeout(uint256 indexed bountyId, address indexed assignee, uint256 reward);
    event BountyCancelled(uint256 indexed bountyId);
    event DepositRefunded(uint256 indexed bountyId, address indexed applicant, uint256 amount);
}
