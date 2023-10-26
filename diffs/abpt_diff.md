```diff
diff --git a/src/ABPT/ABPT_current.sol b/src/ABPT/ABPT.sol
index 2223baa..436eaf7 100644
--- a/src/ABPT/ABPT_current.sol
+++ b/src/ABPT/ABPT.sol
@@ -1,5 +1,5 @@
 // SPDX-License-Identifier: GPL-3.0
-pragma solidity 0.6.12;
+pragma solidity ~0.8.19;
 
 // Needed to handle structures externally
 pragma experimental ABIEncoderV2;
@@ -118,7 +118,7 @@ library BalancerConstants {
   // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
   uint public constant MIN_ASSET_LIMIT = 2;
   uint public constant MAX_ASSET_LIMIT = 8;
-  uint public constant MAX_UINT = uint(-1);
+  uint public constant MAX_UINT = type(uint256).max;
 }
 
 /**
@@ -365,8 +365,8 @@ contract PCToken is IERC20 {
   // Event declarations
 
   // See definitions above; must be redeclared to be emitted from this contract
-  event Approval(address indexed owner, address indexed spender, uint value);
-  event Transfer(address indexed from, address indexed to, uint value);
+  // event Approval(address indexed owner, address indexed spender, uint value);
+  // event Transfer(address indexed from, address indexed to, uint value);
 
   // Function declarations
 
@@ -506,7 +506,7 @@ contract PCToken is IERC20 {
     uint oldAllowance = _allowance[sender][msg.sender];
 
     // If the sender is not the caller, adjust the allowance by the amount transferred
-    if (msg.sender != sender && oldAllowance != uint(-1)) {
+    if (msg.sender != sender && oldAllowance != type(uint256).max) {
       _allowance[sender][msg.sender] = BalancerSafeMath.bsub(oldAllowance, amount);
 
       emit Approval(msg.sender, recipient, _allowance[sender][msg.sender]);
@@ -721,6 +721,14 @@ contract BalancerOwnable {
     _owner = msg.sender;
   }
 
+  /**
+   * @dev Initializes the contract setting the deployer as the initial owner.
+   * @param newOwner - address of new owner
+   */
+  function _setOwner(address newOwner) internal {
+    _owner = newOwner;
+  }
+
   /**
    * @notice Transfers ownership of the contract to a new account (`newOwner`).
    *         Can only be called by the current owner
@@ -1673,7 +1681,7 @@ contract ConfigurableRightsPool is
 
   // State variables
 
-  uint256 public constant REVISION = 1;
+  uint256 public constant REVISION = 2;
 
   IBFactory public bFactory;
   IBPool public bPool;
@@ -1765,65 +1773,9 @@ contract ConfigurableRightsPool is
    *      and create pool, and should not be used thereafter! _initialTokens is destroyed in
    *      createPool to prevent this, and _swapFee is kept in sync (defensively), but
    *      should never be used except in this constructor and createPool()
-   * @param factoryAddress - the BPoolFactory used to create the underlying pool
-   * @param poolParams - struct containing pool parameters
-   * @param rightsStruct - Set of permissions we are assigning to this smart pool
    */
-  function initialize(
-    address factoryAddress,
-    PoolParams memory poolParams,
-    RightsManager.Rights memory rightsStruct
-  ) external initializer {
-    _initializeOwner();
-    _initializeReentrancyGuard();
-    _initializePCToken(poolParams.poolTokenSymbol, poolParams.poolTokenName);
-
-    // We don't have a pool yet; check now or it will fail later (in order of likelihood to fail)
-    // (and be unrecoverable if they don't have permission set to change it)
-    // Most likely to fail, so check first
-    require(poolParams.swapFee >= BalancerConstants.MIN_FEE, 'ERR_INVALID_SWAP_FEE');
-    require(poolParams.swapFee <= BalancerConstants.MAX_FEE, 'ERR_INVALID_SWAP_FEE');
-
-    // Arrays must be parallel
-    require(
-      poolParams.tokenBalances.length == poolParams.constituentTokens.length,
-      'ERR_START_BALANCES_MISMATCH'
-    );
-    require(
-      poolParams.tokenWeights.length == poolParams.constituentTokens.length,
-      'ERR_START_WEIGHTS_MISMATCH'
-    );
-    // Cannot have too many or too few - technically redundant, since BPool.bind() would fail later
-    // But if we don't check now, we could have a useless contract with no way to create a pool
-
-    require(
-      poolParams.constituentTokens.length >= BalancerConstants.MIN_ASSET_LIMIT,
-      'ERR_TOO_FEW_TOKENS'
-    );
-    require(
-      poolParams.constituentTokens.length <= BalancerConstants.MAX_ASSET_LIMIT,
-      'ERR_TOO_MANY_TOKENS'
-    );
-    // There are further possible checks (e.g., if they use the same token twice), but
-    // we can let bind() catch things like that (i.e., not things that might reasonably work)
-
-    SmartPoolManager.verifyTokenCompliance(poolParams.constituentTokens);
-
-    bFactory = IBFactory(factoryAddress);
-    rights = rightsStruct;
-    _initialTokens = poolParams.constituentTokens;
-    _initialBalances = poolParams.tokenBalances;
-    _initialSwapFee = poolParams.swapFee;
-
-    // These default block time parameters can be overridden in createPool
-    minimumWeightChangeBlockPeriod = DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD;
-    addTokenTimeLockInBlocks = DEFAULT_ADD_TOKEN_TIME_LOCK_IN_BLOCKS;
-
-    gradualUpdate.startWeights = poolParams.tokenWeights;
-    // Initializing (unnecessarily) for documentation - 0 means no gradual weight change has been initiated
-    gradualUpdate.startBlock = 0;
-    // By default, there is no cap (unlimited pool token minting)
-    bspCap = BalancerConstants.MAX_UINT;
+  function initialize(address owner) external initializer {
+    _setOwner(owner);
   }
 
   // External functions
```
