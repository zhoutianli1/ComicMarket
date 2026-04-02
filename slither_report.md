**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [incorrect-exp](#incorrect-exp) (1 results) (High)
 - [reentrancy-eth](#reentrancy-eth) (1 results) (High)
 - [uninitialized-state](#uninitialized-state) (17 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (9 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (1 results) (Medium)
 - [unused-return](#unused-return) (3 results) (Medium)
 - [shadowing-local](#shadowing-local) (1 results) (Low)
 - [calls-loop](#calls-loop) (1 results) (Low)
 - [reentrancy-events](#reentrancy-events) (1 results) (Low)
 - [assembly](#assembly) (52 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (1 results) (Informational)
 - [dead-code](#dead-code) (7 results) (Informational)
 - [solc-version](#solc-version) (8 results) (Informational)
 - [missing-inheritance](#missing-inheritance) (5 results) (Informational)
 - [naming-convention](#naming-convention) (22 results) (Informational)
 - [too-many-digits](#too-many-digits) (6 results) (Informational)
 - [unimplemented-functions](#unimplemented-functions) (1 results) (Informational)
 - [unused-state](#unused-state) (3 results) (Informational)
 - [constable-states](#constable-states) (11 results) (Optimization)
## incorrect-exp
Impact: High
Confidence: Medium
 - [ ] ID-0
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inverse = (3 * denominator) ^ 2](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L259)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


## reentrancy-eth
Impact: High
Confidence: Medium
 - [ ] ID-1
Reentrancy in [RoyaltySplitter.batchWithdraw(address[])](src/core/RoyaltySplitter.sol#L184-L203):
	External calls:
	- [(ok,None) = address(msg.sender).call{value: amount}()](src/core/RoyaltySplitter.sol#L193)
	State variables written after the call(s):
	- [pendingWithdrawals[msg.sender][token] = 0](src/core/RoyaltySplitter.sol#L190)
	[RoyaltySplitter.pendingWithdrawals](src/core/RoyaltySplitter.sol#L49) can be used in cross function reentrancies:
	- [RoyaltySplitter.pendingWithdrawals](src/core/RoyaltySplitter.sol#L49)

src/core/RoyaltySplitter.sol#L184-L203


## uninitialized-state
Impact: High
Confidence: High
 - [ ] ID-2
[BountyBoard._applicants](src/bounty/BountyBoard.sol#L47) is never initialized. It is used in:
	- [BountyBoard.getApplicants(uint256)](src/bounty/BountyBoard.sol#L281-L283)
	- [BountyBoard.getApplicantsCount(uint256)](src/bounty/BountyBoard.sol#L285-L287)

src/bounty/BountyBoard.sol#L47


 - [ ] ID-3
[Marketplace._auctions](src/core/Marketplace.sol#L54) is never initialized. It is used in:
	- [Marketplace.bid(uint256,uint256)](src/core/Marketplace.sol#L316-L354)
	- [Marketplace.settleAuction(uint256)](src/core/Marketplace.sol#L359-L404)
	- [Marketplace.getAuction(uint256)](src/core/Marketplace.sol#L469-L471)

src/core/Marketplace.sol#L54


 - [ ] ID-4
[Marketplace._listings](src/core/Marketplace.sol#L52) is never initialized. It is used in:
	- [Marketplace.cancelListing(uint256)](src/core/Marketplace.sol#L134-L142)
	- [Marketplace._executeBuy(uint256,address)](src/core/Marketplace.sol#L173-L209)
	- [Marketplace.acceptOffer(uint256,address)](src/core/Marketplace.sol#L241-L268)
	- [Marketplace.getListing(uint256)](src/core/Marketplace.sol#L465-L467)

src/core/Marketplace.sol#L52


 - [ ] ID-5
[CrossChainBridge.uniswapRouter](src/crosschain/CrossChainBridge.sol#L40) is never initialized. It is used in:
	- [CrossChainBridge.swapForBridgeFee(address,address,uint256,uint256,uint24)](src/crosschain/CrossChainBridge.sol#L285-L309)

src/crosschain/CrossChainBridge.sol#L40


 - [ ] ID-6
[BountyBoard._bounties](src/bounty/BountyBoard.sol#L44) is never initialized. It is used in:
	- [BountyBoard.applyBounty(uint256)](src/bounty/BountyBoard.sol#L128-L149)
	- [BountyBoard.assignBounty(uint256,address)](src/bounty/BountyBoard.sol#L153-L162)
	- [BountyBoard.withdrawDeposit(uint256)](src/bounty/BountyBoard.sol#L167-L185)
	- [BountyBoard.submitBounty(uint256,string)](src/bounty/BountyBoard.sol#L189-L200)
	- [BountyBoard.approveBounty(uint256)](src/bounty/BountyBoard.sol#L205-L215)
	- [BountyBoard.claimByTimeout(uint256)](src/bounty/BountyBoard.sol#L220-L234)
	- [BountyBoard.cancelBounty(uint256)](src/bounty/BountyBoard.sol#L238-L249)
	- [BountyBoard.getBounty(uint256)](src/bounty/BountyBoard.sol#L277-L279)

src/bounty/BountyBoard.sol#L44


 - [ ] ID-7
[CrossChainBridge.comicNFTContract](src/crosschain/CrossChainBridge.sol#L41) is never initialized. It is used in:
	- [CrossChainBridge._getMetadataURI(uint256)](src/crosschain/CrossChainBridge.sol#L335-L337)
	- [CrossChainBridge._getCreator(uint256)](src/crosschain/CrossChainBridge.sol#L339-L342)
	- [CrossChainBridge._getSecondaryRoyalty(uint256)](src/crosschain/CrossChainBridge.sol#L344-L347)

src/crosschain/CrossChainBridge.sol#L41


 - [ ] ID-8
[ComicNFT._ipFamilies](src/core/ComicNFT.sol#L43) is never initialized. It is used in:
	- [ComicNFT.getIPFamily(uint256)](src/core/ComicNFT.sol#L260-L262)

src/core/ComicNFT.sol#L43


 - [ ] ID-9
[Marketplace._offers](src/core/Marketplace.sol#L56) is never initialized. It is used in:
	- [Marketplace.getOffer(uint256,address)](src/core/Marketplace.sol#L473-L475)

src/core/Marketplace.sol#L56


 - [ ] ID-10
[CrossChainBridge.processedMessages](src/crosschain/CrossChainBridge.sol#L50) is never initialized. It is used in:
	- [CrossChainBridge.isMessageProcessed(bytes32)](src/crosschain/CrossChainBridge.sol#L317-L319)

src/crosschain/CrossChainBridge.sol#L50


 - [ ] ID-11
[CrossChainBridge.bridgeLocks](src/crosschain/CrossChainBridge.sol#L47) is never initialized. It is used in:
	- [CrossChainBridge.rollback(uint256)](src/crosschain/CrossChainBridge.sol#L265-L275)
	- [CrossChainBridge.getBridgeLock(uint256)](src/crosschain/CrossChainBridge.sol#L313-L315)

src/crosschain/CrossChainBridge.sol#L47


 - [ ] ID-12
[ComicNFT.bridgeContract](src/core/ComicNFT.sol#L56) is never initialized. It is used in:
	- [ComicNFT.burn(uint256)](src/core/ComicNFT.sol#L168-L173)

src/core/ComicNFT.sol#L56


 - [ ] ID-13
[RoyaltySplitter.comicNFTContract](src/core/RoyaltySplitter.sol#L37) is never initialized. It is used in:
	- [RoyaltySplitter.distribute(uint256,address,address,uint256,address)](src/core/RoyaltySplitter.sol#L92-L161)

src/core/RoyaltySplitter.sol#L37


 - [ ] ID-14
[Marketplace.royaltySplitter](src/core/Marketplace.sol#L47) is never initialized. It is used in:
	- [Marketplace._processPaymentAndSplit(uint256,address,address,uint256,address,address,bool)](src/core/Marketplace.sol#L410-L461)

src/core/Marketplace.sol#L47


 - [ ] ID-15
[RoyaltySplitter.marketplaceContract](src/core/RoyaltySplitter.sol#L39) is never initialized. It is used in:

src/core/RoyaltySplitter.sol#L39


 - [ ] ID-16
[BountyBoard._applied](src/bounty/BountyBoard.sol#L50) is never initialized. It is used in:
	- [BountyBoard.hasApplied(uint256,address)](src/bounty/BountyBoard.sol#L289-L291)

src/bounty/BountyBoard.sol#L50


 - [ ] ID-17
[RoyaltySplitter.platformTreasury](src/core/RoyaltySplitter.sol#L38) is never initialized. It is used in:
	- [RoyaltySplitter.distribute(uint256,address,address,uint256,address)](src/core/RoyaltySplitter.sol#L92-L161)

src/core/RoyaltySplitter.sol#L38


 - [ ] ID-18
[CrossChainBridge.ccipRouter](src/crosschain/CrossChainBridge.sol#L39) is never initialized. It is used in:
	- [CrossChainBridge.ccipReceive(bytes32,uint64,bytes)](src/crosschain/CrossChainBridge.sol#L220-L259)

src/crosschain/CrossChainBridge.sol#L39


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-19
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse = (3 * denominator) ^ 2](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L259)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-20
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [low = low / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L247)
	- [result = low * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L274)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-21
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L265)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-22
[Math.invMod(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L317-L363) performs a multiplication on the result of a division:
	- [quotient = gcd / remainder](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L339)
	- [(gcd,remainder) = (remainder,gcd - remainder * quotient)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L341-L348)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L317-L363


 - [ ] ID-23
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L264)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-24
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L266)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-25
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L267)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-26
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L263)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-27
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L244)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L268)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-28
[PercentageMath.validateBpsSum(uint16[]).total](src/libraries/PercentageMath.sol#L22) is a local variable never initialized

src/libraries/PercentageMath.sol#L22


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-29
[ERC1967Utils.upgradeBeaconToAndCall(address,bytes)](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L157-L166) ignores return value by [Address.functionDelegateCall(IBeacon(newBeacon).implementation(),data)](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L162)

lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L157-L166


 - [ ] ID-30
[ERC1967Utils.upgradeToAndCall(address,bytes)](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L67-L76) ignores return value by [Address.functionDelegateCall(newImplementation,data)](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L72)

lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L67-L76


 - [ ] ID-31
[CrossChainBridge.swapForBridgeFee(address,address,uint256,uint256,uint24)](src/crosschain/CrossChainBridge.sol#L285-L309) ignores return value by [IERC20(tokenIn).approve(address(uniswapRouter),amountIn)](src/crosschain/CrossChainBridge.sol#L293)

src/crosschain/CrossChainBridge.sol#L285-L309


## shadowing-local
Impact: Low
Confidence: High
 - [ ] ID-32
[ComicNFT.reviewLicense(uint256,bool).approve](src/core/ComicNFT.sol#L231) shadows:
	- [ERC721Upgradeable.approve(address,uint256)](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L115-L117) (function)
	- [IERC721.approve(address,uint256)](lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#L106) (function)

src/core/ComicNFT.sol#L231


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-33
[RoyaltySplitter.batchWithdraw(address[])](src/core/RoyaltySplitter.sol#L184-L203) has external calls inside a loop: [(ok,None) = address(msg.sender).call{value: amount}()](src/core/RoyaltySplitter.sol#L193)

src/core/RoyaltySplitter.sol#L184-L203


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-34
Reentrancy in [CrossChainBridge.swapForBridgeFee(address,address,uint256,uint256,uint24)](src/crosschain/CrossChainBridge.sol#L285-L309):
	External calls:
	- [IERC20(tokenIn).approve(address(uniswapRouter),amountIn)](src/crosschain/CrossChainBridge.sol#L293)
	- [amountOut = uniswapRouter.exactInputSingle(IUniswapRouter.ExactInputSingleParams({tokenIn:tokenIn,tokenOut:tokenOut,fee:fee,recipient:msg.sender,deadline:block.timestamp + 900,amountIn:amountIn,amountOutMinimum:amountOutMin,sqrtPriceLimitX96:0}))](src/crosschain/CrossChainBridge.sol#L295-L306)
	Event emitted after the call(s):
	- [TokenSwapped(msg.sender,tokenIn,tokenOut,amountIn,amountOut)](src/crosschain/CrossChainBridge.sol#L308)

src/crosschain/CrossChainBridge.sol#L285-L309


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-35
[Strings.toChecksumHexString(address)](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L108-L126) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L113-L115)

lib/openzeppelin-contracts/contracts/utils/Strings.sol#L108-L126


 - [ ] ID-36
[Math.tryMul(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L76-L80)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84


 - [ ] ID-37
[Math._zeroBytes(bytes)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L478-L490) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L482-L484)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L478-L490


 - [ ] ID-38
[LowLevelCall.callReturn64Bytes(address,uint256,bytes)](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L38-L48) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L43-L47)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L38-L48


 - [ ] ID-39
[StorageSlot.getAddressSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L66-L70) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L67-L69)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L66-L70


 - [ ] ID-40
[Math.mul512(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L41-L45)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46


 - [ ] ID-41
[LowLevelCall.callNoReturn(address,uint256,bytes)](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L19-L23) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L20-L22)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L19-L23


 - [ ] ID-42
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L229-L236)
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242-L251)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L206-L277


 - [ ] ID-43
[Math.add512(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L26-L29)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30


 - [ ] ID-44
[LowLevelCall.bubbleRevert()](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L114-L120) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L115-L119)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L114-L120


 - [ ] ID-45
[Proxy._delegate(address)](lib/openzeppelin-contracts/contracts/proxy/Proxy.sol#L22-L45) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/proxy/Proxy.sol#L23-L44)

lib/openzeppelin-contracts/contracts/proxy/Proxy.sol#L22-L45


 - [ ] ID-46
[SafeCast.toUint(bool)](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1158-L1160)

lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161


 - [ ] ID-47
[StorageSlot.getInt256Slot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L102-L106) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L103-L105)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L102-L106


 - [ ] ID-48
[Math.tryModExp(bytes,bytes,bytes)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L451-L473) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L463-L472)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L451-L473


 - [ ] ID-49
[Bytes.concat(bytes[])](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L183-L203) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L194-L196)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L183-L203


 - [ ] ID-50
[Math.tryModExp(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L411-L435) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L413-L434)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L411-L435


 - [ ] ID-51
[LowLevelCall.returnData()](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L104-L111) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L105-L110)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L104-L111


 - [ ] ID-52
[OwnableUpgradeable._getOwnableStorage()](lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L30-L34) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L31-L33)

lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L30-L34


 - [ ] ID-53
[Panic.panic(uint256)](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L51-L55)

lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56


 - [ ] ID-54
[SafeERC20._safeTransfer(IERC20,address,uint256,bool)](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L176-L200) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L179-L199)

lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L176-L200


 - [ ] ID-55
[StorageSlot.getBytesSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L129-L133) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L130-L132)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L129-L133


 - [ ] ID-56
[ERC721URIStorageUpgradeable._getERC721URIStorageStorage()](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L29-L33) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L30-L32)

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L29-L33


 - [ ] ID-57
[LowLevelCall.delegatecallReturn64Bytes(address,bytes)](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L85-L94) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L89-L93)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L85-L94


 - [ ] ID-58
[Math.log2(uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L655-L657)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658


 - [ ] ID-59
[LowLevelCall.staticcallReturn64Bytes(address,bytes)](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L62-L71) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L66-L70)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L62-L71


 - [ ] ID-60
[StorageSlot.getStringSlot(string)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L120-L124) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L121-L123)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L120-L124


 - [ ] ID-61
[Bytes.slice(bytes,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L86-L98) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L93-L95)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L86-L98


 - [ ] ID-62
[Strings.toString(uint256)](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L42-L60) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L47-L49)
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L52-L54)

lib/openzeppelin-contracts/contracts/utils/Strings.sol#L42-L60


 - [ ] ID-63
[StorageSlot.getBytes32Slot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L84-L88) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L85-L87)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L84-L88


 - [ ] ID-64
[Math.tryMod(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L105-L108)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110


 - [ ] ID-65
[StorageSlot.getBytesSlot(bytes)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L138-L142) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L139-L141)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L138-L142


 - [ ] ID-66
[Strings._unsafeWriteBytesOffset(bytes,uint256,bytes1)](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L526-L531) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L528-L530)

lib/openzeppelin-contracts/contracts/utils/Strings.sol#L526-L531


 - [ ] ID-67
[Math.tryDiv(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L92-L95)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97


 - [ ] ID-68
[PausableUpgradeable._getPausableStorage()](lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L27-L31) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L28-L30)

lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L27-L31


 - [ ] ID-69
[LowLevelCall.staticcallNoReturn(address,bytes)](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L51-L55) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L52-L54)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L51-L55


 - [ ] ID-70
[LowLevelCall.delegatecallNoReturn(address,bytes)](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L74-L78) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L75-L77)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L74-L78


 - [ ] ID-71
[Bytes.splice(bytes,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L117-L129) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L123-L126)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L117-L129


 - [ ] ID-72
[ERC721Utils.checkOnERC721Received(address,address,address,uint256,bytes)](lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#L25-L49) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#L43-L45)

lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#L25-L49


 - [ ] ID-73
[StorageSlot.getBooleanSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L75-L79) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L76-L78)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L75-L79


 - [ ] ID-74
[SafeERC20._safeApprove(IERC20,address,uint256,bool)](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L255-L279) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L258-L278)

lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L255-L279


 - [ ] ID-75
[StorageSlot.getStringSlot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L111-L115) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L112-L114)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L111-L115


 - [ ] ID-76
[Bytes.toNibbles(bytes)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L211-L244)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245


 - [ ] ID-77
[LowLevelCall.bubbleRevert(bytes)](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L122-L126) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L123-L125)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L122-L126


 - [ ] ID-78
[Bytes.replace(bytes,uint256,bytes,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L154-L172) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L167-L169)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L154-L172


 - [ ] ID-79
[Bytes._unsafeReadBytesOffset(bytes,uint256)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L326-L331) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L328-L330)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L326-L331


 - [ ] ID-80
[Strings._unsafeReadBytesOffset(bytes,uint256)](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L513-L518) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L515-L517)

lib/openzeppelin-contracts/contracts/utils/Strings.sol#L513-L518


 - [ ] ID-81
[Initializable._getInitializableStorage()](lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L232-L237) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L234-L236)

lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L232-L237


 - [ ] ID-82
[SafeERC20._safeTransferFrom(IERC20,address,address,uint256,bool)](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L212-L244) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L221-L243)

lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L212-L244


 - [ ] ID-83
[Strings.escapeJSON(string)](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L461-L505) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L468-L470)
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L499-L502)

lib/openzeppelin-contracts/contracts/utils/Strings.sol#L461-L505


 - [ ] ID-84
[LowLevelCall.returnDataSize()](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L97-L101) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L98-L100)

lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L97-L101


 - [ ] ID-85
[StorageSlot.getUint256Slot(bytes32)](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L93-L97) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L94-L96)

lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L93-L97


 - [ ] ID-86
[ERC721Upgradeable._getERC721Storage()](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L44-L48) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L45-L47)

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L44-L48


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-87
9 different versions of Solidity are used:
	- Version constraint >=0.6.2 is used by:
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC4906.sol#L4)
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol#L4)
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#L4)
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4)
	- Version constraint >=0.4.16 is used by:
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)
	- Version constraint >=0.4.11 is used by:
		-[>=0.4.11](lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L4)
	- Version constraint >=0.8.4 is used by:
		-[>=0.8.4](lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L4)
	- Version constraint ^0.8.22 is used by:
		-[^0.8.22](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol#L4)
		-[^0.8.22](lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L4)
		-[^0.8.22](lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol#L3)
	- Version constraint ^0.8.21 is used by:
		-[^0.8.21](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L4)
	- Version constraint ^0.8.20 is used by:
		-[^0.8.20](lib/openzeppelin-contracts/contracts/proxy/Proxy.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/Address.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/Errors.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L5)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol#L3)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol#L4)
		-[^0.8.20](src/bounty/BountyBoard.sol#L2)
		-[^0.8.20](src/core/ComicNFT.sol#L2)
		-[^0.8.20](src/core/Marketplace.sol#L2)
		-[^0.8.20](src/core/RoyaltySplitter.sol#L2)
		-[^0.8.20](src/crosschain/CrossChainBridge.sol#L2)
		-[^0.8.20](src/interfaces/IAll.sol#L2)
		-[^0.8.20](src/libraries/DataTypes.sol#L2)
		-[^0.8.20](src/libraries/Errors.sol#L2)
		-[^0.8.20](src/libraries/PercentageMath.sol#L2)
		-[^0.8.20](src/proxy/BountyBoardProxy.sol#L2)
		-[^0.8.20](src/proxy/ComicNFTProxy.sol#L2)
		-[^0.8.20](src/proxy/CrossChainBridgeProxy.sol#L2)
		-[^0.8.20](src/proxy/MarketplaceProxy.sol#L2)
		-[^0.8.20](src/proxy/RoyaltySplitterProxy.sol#L2)
	- Version constraint >=0.5.0 is used by:
		-[>=0.5.0](lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#L4)
	- Version constraint ^0.8.24 is used by:
		-[^0.8.24](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L4)
		-[^0.8.24](lib/openzeppelin-contracts/contracts/utils/Strings.sol#L4)
		-[^0.8.24](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L4)
		-[^0.8.24](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L4)

lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4


## cyclomatic-complexity
Impact: Informational
Confidence: High
 - [ ] ID-88
[ComicNFT.mint(address,string,uint16,uint16,bool,uint256)](src/core/ComicNFT.sol#L102-L165) has a high cyclomatic complexity (12).

src/core/ComicNFT.sol#L102-L165


## dead-code
Impact: Informational
Confidence: Medium
 - [ ] ID-89
[Marketplace._processPaymentAndSplit(uint256,address,address,uint256,address,address,bool)](src/core/Marketplace.sol#L410-L461) is never used and should be removed

src/core/Marketplace.sol#L410-L461


 - [ ] ID-90
[RoyaltySplitter._credit(address,address,uint256)](src/core/RoyaltySplitter.sol#L207-L211) is never used and should be removed

src/core/RoyaltySplitter.sol#L207-L211


 - [ ] ID-91
[CrossChainBridge._getMetadataURI(uint256)](src/crosschain/CrossChainBridge.sol#L335-L337) is never used and should be removed

src/crosschain/CrossChainBridge.sol#L335-L337


 - [ ] ID-92
[BountyBoard._payAssignee(DataTypes.BountyTask,uint256)](src/bounty/BountyBoard.sol#L253-L264) is never used and should be removed

src/bounty/BountyBoard.sol#L253-L264


 - [ ] ID-93
[BountyBoard._refund(address,address,uint256)](src/bounty/BountyBoard.sol#L266-L273) is never used and should be removed

src/bounty/BountyBoard.sol#L266-L273


 - [ ] ID-94
[CrossChainBridge._getCreator(uint256)](src/crosschain/CrossChainBridge.sol#L339-L342) is never used and should be removed

src/crosschain/CrossChainBridge.sol#L339-L342


 - [ ] ID-95
[CrossChainBridge._getSecondaryRoyalty(uint256)](src/crosschain/CrossChainBridge.sol#L344-L347) is never used and should be removed

src/crosschain/CrossChainBridge.sol#L344-L347


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-96
Version constraint ^0.8.22 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication.
It is used by:
	- [^0.8.22](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol#L4)
	- [^0.8.22](lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L4)
	- [^0.8.22](lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol#L3)

lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol#L4


 - [ ] ID-97
Version constraint >=0.5.0 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- ABIEncoderV2StorageArrayWithMultiSlotElement
	- DynamicConstructorArgumentsClippedABIV2
	- UninitializedFunctionPointerInConstructor
	- IncorrectEventSignatureInLibraries
	- ABIEncoderV2PackedStorage.
It is used by:
	- [>=0.5.0](lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#L4)

lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#L4


 - [ ] ID-98
Version constraint >=0.4.11 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- UninitializedFunctionPointerInConstructor_0.4.x
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector
	- DelegateCallReturnValue
	- ECRecoverMalformedInput
	- SkipEmptyStringLiteral.
It is used by:
	- [>=0.4.11](lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L4)

lib/openzeppelin-contracts/contracts/interfaces/IERC1967.sol#L4


 - [ ] ID-99
Version constraint >=0.8.4 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- DataLocationChangeInInternalOverride
	- NestedCalldataArrayAbiReencodingSizeValidation
	- SignedImmutables.
It is used by:
	- [>=0.8.4](lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L4)

lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L4


 - [ ] ID-100
Version constraint >=0.4.16 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- ABIEncoderV2StorageArrayWithMultiSlotElement
	- DynamicConstructorArgumentsClippedABIV2
	- UninitializedFunctionPointerInConstructor_0.4.x
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector.
It is used by:
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)

lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4


 - [ ] ID-101
Version constraint ^0.8.21 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication.
It is used by:
	- [^0.8.21](lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L4)

lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol#L4


 - [ ] ID-102
Version constraint >=0.6.2 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- NestedCalldataArrayAbiReencodingSizeValidation
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- MissingEscapingInFormatting
	- ArraySliceDynamicallyEncodedBaseType
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow.
It is used by:
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC4906.sol#L4)
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol#L4)
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#L4)
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4)

lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4


 - [ ] ID-103
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- [^0.8.20](lib/openzeppelin-contracts/contracts/proxy/Proxy.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Address.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Errors.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/LowLevelCall.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol#L5)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol#L3)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol#L4)
	- [^0.8.20](src/bounty/BountyBoard.sol#L2)
	- [^0.8.20](src/core/ComicNFT.sol#L2)
	- [^0.8.20](src/core/Marketplace.sol#L2)
	- [^0.8.20](src/core/RoyaltySplitter.sol#L2)
	- [^0.8.20](src/crosschain/CrossChainBridge.sol#L2)
	- [^0.8.20](src/interfaces/IAll.sol#L2)
	- [^0.8.20](src/libraries/DataTypes.sol#L2)
	- [^0.8.20](src/libraries/Errors.sol#L2)
	- [^0.8.20](src/libraries/PercentageMath.sol#L2)
	- [^0.8.20](src/proxy/BountyBoardProxy.sol#L2)
	- [^0.8.20](src/proxy/ComicNFTProxy.sol#L2)
	- [^0.8.20](src/proxy/CrossChainBridgeProxy.sol#L2)
	- [^0.8.20](src/proxy/MarketplaceProxy.sol#L2)
	- [^0.8.20](src/proxy/RoyaltySplitterProxy.sol#L2)

lib/openzeppelin-contracts/contracts/proxy/Proxy.sol#L4


## missing-inheritance
Impact: Informational
Confidence: High
 - [ ] ID-104
[BountyBoardProxy](src/proxy/BountyBoardProxy.sol#L11-L22) should inherit from [IBeacon](lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L9-L16)

src/proxy/BountyBoardProxy.sol#L11-L22


 - [ ] ID-105
[MarketplaceProxy](src/proxy/MarketplaceProxy.sol#L12-L23) should inherit from [IBeacon](lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L9-L16)

src/proxy/MarketplaceProxy.sol#L12-L23


 - [ ] ID-106
[RoyaltySplitterProxy](src/proxy/RoyaltySplitterProxy.sol#L11-L22) should inherit from [IBeacon](lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L9-L16)

src/proxy/RoyaltySplitterProxy.sol#L11-L22


 - [ ] ID-107
[ComicNFTProxy](src/proxy/ComicNFTProxy.sol#L23-L37) should inherit from [IBeacon](lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L9-L16)

src/proxy/ComicNFTProxy.sol#L23-L37


 - [ ] ID-108
[CrossChainBridgeProxy](src/proxy/CrossChainBridgeProxy.sol#L12-L23) should inherit from [IBeacon](lib/openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol#L9-L16)

src/proxy/CrossChainBridgeProxy.sol#L12-L23


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-109
Parameter [RoyaltySplitter.initialize(address,address,address,address)._comicNFTContract](src/core/RoyaltySplitter.sol#L59) is not in mixedCase

src/core/RoyaltySplitter.sol#L59


 - [ ] ID-110
Function [ERC721URIStorageUpgradeable.__ERC721URIStorage_init_unchained()](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L38-L39) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L38-L39


 - [ ] ID-111
Parameter [RoyaltySplitter.initialize(address,address,address,address)._platformTreasury](src/core/RoyaltySplitter.sol#L60) is not in mixedCase

src/core/RoyaltySplitter.sol#L60


 - [ ] ID-112
Constant [OwnableUpgradeable.OwnableStorageLocation](lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L28) is not in UPPER_CASE_WITH_UNDERSCORES

lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L28


 - [ ] ID-113
Parameter [Marketplace.initialize(address,address)._royaltySplitter](src/core/Marketplace.sol#L81) is not in mixedCase

src/core/Marketplace.sol#L81


 - [ ] ID-114
Function [OwnableUpgradeable.__Ownable_init(address)](lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L51-L53) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L51-L53


 - [ ] ID-115
Function [ERC721Upgradeable.__ERC721_init_unchained(string,string)](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L57-L61) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L57-L61


 - [ ] ID-116
Function [OwnableUpgradeable.__Ownable_init_unchained(address)](lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L55-L60) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol#L55-L60


 - [ ] ID-117
Function [ERC165Upgradeable.__ERC165_init_unchained()](lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol#L25-L26) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol#L25-L26


 - [ ] ID-118
Function [ContextUpgradeable.__Context_init_unchained()](lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol#L21-L22) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol#L21-L22


 - [ ] ID-119
Function [ERC721URIStorageUpgradeable.__ERC721URIStorage_init()](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L35-L36) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L35-L36


 - [ ] ID-120
Constant [ERC721Upgradeable.ERC721StorageLocation](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L42) is not in UPPER_CASE_WITH_UNDERSCORES

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L42


 - [ ] ID-121
Variable [UUPSUpgradeable.__self](lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L23) is not in mixedCase

lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol#L23


 - [ ] ID-122
Constant [ERC721URIStorageUpgradeable.ERC721URIStorageStorageLocation](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L27) is not in UPPER_CASE_WITH_UNDERSCORES

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol#L27


 - [ ] ID-123
Parameter [CrossChainBridge.initialize(address,address,address,address)._ccipRouter](src/crosschain/CrossChainBridge.sol#L59) is not in mixedCase

src/crosschain/CrossChainBridge.sol#L59


 - [ ] ID-124
Parameter [CrossChainBridge.initialize(address,address,address,address)._comicNFTContract](src/crosschain/CrossChainBridge.sol#L61) is not in mixedCase

src/crosschain/CrossChainBridge.sol#L61


 - [ ] ID-125
Function [PausableUpgradeable.__Pausable_init()](lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L77-L78) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L77-L78


 - [ ] ID-126
Function [ContextUpgradeable.__Context_init()](lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol#L18-L19) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol#L18-L19


 - [ ] ID-127
Function [ERC165Upgradeable.__ERC165_init()](lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol#L22-L23) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol#L22-L23


 - [ ] ID-128
Constant [PausableUpgradeable.PausableStorageLocation](lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L25) is not in UPPER_CASE_WITH_UNDERSCORES

lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L25


 - [ ] ID-129
Function [PausableUpgradeable.__Pausable_init_unchained()](lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L80-L81) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol#L80-L81


 - [ ] ID-130
Function [ERC721Upgradeable.__ERC721_init(string,string)](lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L53-L55) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol#L53-L55


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-131
[Bytes.reverseBytes16(bytes16)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L275-L286) uses literals with too many digits:
	- [value = ((value & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((value & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L282-L284)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L275-L286


 - [ ] ID-132
[Math.log2(uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658) uses literals with too many digits:
	- [r = r | byte(uint256,uint256)(x >> r,0x0000010102020202030303030303030300000000000000000000000000000000)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L656)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L619-L658


 - [ ] ID-133
[Bytes.reverseBytes32(bytes32)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272) uses literals with too many digits:
	- [value = ((value >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) | ((value & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L265-L267)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272


 - [ ] ID-134
[Bytes.toNibbles(bytes)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245) uses literals with too many digits:
	- [chunk_toNibbles_asm_0 = 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff & chunk_toNibbles_asm_0 << 64 | chunk_toNibbles_asm_0](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L222-L225)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245


 - [ ] ID-135
[Bytes.toNibbles(bytes)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245) uses literals with too many digits:
	- [chunk_toNibbles_asm_0 = 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff & chunk_toNibbles_asm_0 << 32 | chunk_toNibbles_asm_0](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L226-L229)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L210-L245


 - [ ] ID-136
[Bytes.reverseBytes32(bytes32)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272) uses literals with too many digits:
	- [value = ((value >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) | ((value & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64)](lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L268-L270)

lib/openzeppelin-contracts/contracts/utils/Bytes.sol#L258-L272


## unimplemented-functions
Impact: Informational
Confidence: High
 - [ ] ID-137
[ComicNFT](src/core/ComicNFT.sol#L24-L337) does not implement functions:
	- [IComicNFT.tokenURI(uint256)](src/interfaces/IAll.sol#L46)

src/core/ComicNFT.sol#L24-L337


## unused-state
Impact: Informational
Confidence: High
 - [ ] ID-138
[Marketplace._nextAuctionId](src/core/Marketplace.sol#L50) is never used in [Marketplace](src/core/Marketplace.sol#L29-L497)

src/core/Marketplace.sol#L50


 - [ ] ID-139
[Marketplace._nextListingId](src/core/Marketplace.sol#L49) is never used in [Marketplace](src/core/Marketplace.sol#L29-L497)

src/core/Marketplace.sol#L49


 - [ ] ID-140
[BountyBoard._submittedAt](src/bounty/BountyBoard.sol#L56) is never used in [BountyBoard](src/bounty/BountyBoard.sol#L26-L317)

src/bounty/BountyBoard.sol#L56


## constable-states
Impact: Optimization
Confidence: High
 - [ ] ID-141
[RoyaltySplitter.comicNFTContract](src/core/RoyaltySplitter.sol#L37) should be constant 

src/core/RoyaltySplitter.sol#L37


 - [ ] ID-142
[RoyaltySplitter.platformTreasury](src/core/RoyaltySplitter.sol#L38) should be constant 

src/core/RoyaltySplitter.sol#L38


 - [ ] ID-143
[RoyaltySplitter.marketplaceContract](src/core/RoyaltySplitter.sol#L39) should be constant 

src/core/RoyaltySplitter.sol#L39


 - [ ] ID-144
[ComicNFT.bridgeContract](src/core/ComicNFT.sol#L56) should be constant 

src/core/ComicNFT.sol#L56


 - [ ] ID-145
[CrossChainBridge.ccipRouter](src/crosschain/CrossChainBridge.sol#L39) should be constant 

src/crosschain/CrossChainBridge.sol#L39


 - [ ] ID-146
[CrossChainBridge.uniswapRouter](src/crosschain/CrossChainBridge.sol#L40) should be constant 

src/crosschain/CrossChainBridge.sol#L40


 - [ ] ID-147
[Marketplace.royaltySplitter](src/core/Marketplace.sol#L47) should be constant 

src/core/Marketplace.sol#L47


 - [ ] ID-148
[ComicNFT.marketplaceContract](src/core/ComicNFT.sol#L53) should be constant 

src/core/ComicNFT.sol#L53


 - [ ] ID-149
[Marketplace._nextListingId](src/core/Marketplace.sol#L49) should be constant 

src/core/Marketplace.sol#L49


 - [ ] ID-150
[CrossChainBridge.comicNFTContract](src/crosschain/CrossChainBridge.sol#L41) should be constant 

src/crosschain/CrossChainBridge.sol#L41


 - [ ] ID-151
[Marketplace._nextAuctionId](src/core/Marketplace.sol#L50) should be constant 

src/core/Marketplace.sol#L50


