
# 去中心化漫画市场 - Solidity合约开发文档（修订版）

## 1. 技术选型与架构设计

### 1.1 开发环境
- **语言**：Solidity ^0.8.20
- **框架**：Foundry (Forge + Cast + Anvil)
- **网络**：ABR链（兼容EVM）
- **依赖库**：
  - OpenZeppelin v5.0（合约标准库）
  - Uniswap V3 Periphery（跨链Swap集成）
  - Chainlink CCIP（跨链通信）

### 1.2 架构设计原则
- **可升级性**：核心合约采用ERC1967Proxy代理模式
- **模块化**：功能拆分为独立合约，通过接口交互
- **Gas优化**：使用自定义错误、数据结构优化、库函数
- **安全性**：遵循检查-效果-交互模式，重入锁保护
## 合约架构

```
contracts/
├── libraries/
│   ├── DataTypes.sol        # 全局数据结构（所有 struct/enum）
│   ├── Errors.sol           # 全局自定义错误（节省 ~50% Gas）
│   └── PercentageMath.sol   # 版税 basis points 安全计算
├── interfaces/
│   └── IAll.sol             # IComicNFT / IMarketplace /         IRoyaltySplitter / ICCIP / IUniswap
├── core/
│   ├── ComicNFT.sol         # ERC721 漫画 NFT（铸造、IP家族、授权）
│   ├── Marketplace.sol      # 市场交易（挂单/购买/出价/拍卖）
│   └── RoyaltySplitter.sol  # 版税自动拆分（pull 模式）
├── bounty/
│   └── BountyBoard.sol      # 协作悬赏（锁定-提交-验收-超时保护）
└── crosschain/
    └── CrossChainBridge.sol # 跨链桥（CCIP + Uniswap 代币兑换）
script/
└── Deploy.s.sol             # Foundry 一键部署脚本
test/
└── ComicMarket.t.sol        # 核心流程测试
```

## 经济模型参数

| 参数  | 数值                                                            |
|------|---------------------------------------------------------------- |
| 平台费              | 2.5%（固定，`PercentageMath.PLATFORM_FEE_BPS = 250`）|
| 一级市场版税上限     | 30%（`MAX_PRIMARY_BPS = 3000`）                      |
| 二级市场版税上限     | 10%（`MAX_SECONDARY_BPS = 1000`）                    |
| 衍生品原作分成默认   | 5%（`DEFAULT_DERIVATIVE_BPS = 500`）                  |
| 悬赏验收期          | 7-30 天                                             |

## 暂停机制（安全关键）

所有核心合约均继承 `PausableUpgradeable`：

- `ComicNFT.pause()` — 停止所有铸造和 NFT 转移
- `Marketplace.pause()` — 停止所有挂单、购买、拍卖
- `RoyaltySplitter.pause()` — 停止版税分配
- `BountyBoard.pause()` — 停止悬赏发布和领取
- `CrossChainBridge.pause()` — 停止跨链操作

只有 `owner`（建议设为多签合约）可调用 pause/unpause。

## 快速开始

```bash
# 安装依赖
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
forge install OpenZeppelin/openzeppelin-contracts
forge install smartcontractkit/ccip
Uniswap 不需要单独安装。你用到的只是 IUniswapRouter 这个接口，已经在 interfaces/IAll.sol 里自己定义了，不需要引入整个 Uniswap 仓库。
# 编译
forge build

# 测试
forge test -vvv

# Gas 报告
forge test --gas-report

# 部署（测试网）
cp .env.example .env  # 填写环境变量
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $ABR_TESTNET_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## 环境变量

```env
PRIVATE_KEY=0x...
OWNER_ADDRESS=0x...
PLATFORM_TREASURY=0x...
ABR_TESTNET_RPC=https://...
ABR_MAINNET_RPC=https://...
CCIP_ROUTER=0x...         # Chainlink CCIP Router 地址
UNISWAP_ROUTER=0x...      # Uniswap V3 Router 地址
ABRSCAN_API_KEY=...
ABRSCAN_URL=https://...
```

## 合约升级

所有合约采用 **UUPS (ERC1967)** 代理模式：
- 用户始终与代理地址交互（地址永不变）
- 升级逻辑：部署新实现 → 调用 `upgradeTo(newImpl)`
- 只有 owner 可升级

## 安全注意事项

1. **检查-效果-交互（CEI）**：所有状态变更在外部调用前完成
2. **ReentrancyGuard**：所有涉及资金转移的函数都有重入锁
3. **Pull 模式**：版税不主动 push，通过 `withdraw()` 主动提取
4. **owner 建议使用多签**（Gnosis Safe）
5. **上线前必须完成第三方审计**
