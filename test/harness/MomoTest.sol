// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";
import { ERC4626Hyperdrive } from "hyperdrive/src/instances/erc4626/ERC4626Hyperdrive.sol";
import { ERC4626Target0 } from "hyperdrive/src/instances/erc4626/ERC4626Target0.sol";
import { ERC4626Target1 } from "hyperdrive/src/instances/erc4626/ERC4626Target1.sol";
import { ERC4626Target2 } from "hyperdrive/src/instances/erc4626/ERC4626Target2.sol";
import { ERC4626Target3 } from "hyperdrive/src/instances/erc4626/ERC4626Target3.sol";
import { ERC4626Target4 } from "hyperdrive/src/instances/erc4626/ERC4626Target4.sol";
import { IERC20 } from "hyperdrive/src/interfaces/IERC20.sol";
import { IHyperdrive } from "hyperdrive/src/interfaces/IHyperdrive.sol";
import { IHyperdriveAdminController } from "hyperdrive/src/interfaces/IHyperdriveAdminController.sol";
import { ONE } from "hyperdrive/src/libraries/HyperdriveMath.sol";
import { HyperdriveMath } from "hyperdrive/src/libraries/HyperdriveMath.sol";
import { ERC20ForwarderFactory } from "hyperdrive/src/token/ERC20ForwarderFactory.sol";
import { ERC20Mintable } from "hyperdrive/test/ERC20Mintable.sol";
import { MockERC4626 } from "hyperdrive/test/MockERC4626.sol";
import { MockHyperdriveAdminController } from "hyperdrive/test/MockHyperdrive.sol";

/// @dev The default minimum share reserves.
uint256 constant MINIMUM_SHARE_RESERVES = 1e15;

/// @dev The default minimum transaction amount.
uint256 constant MINIMUM_TRANSACTION_AMOUNT = 1e15;

/// @dev The default circuit breaker delta. This is a large value to make it
///      possible to test with extreme cases.
uint256 constant CIRCUIT_BREAKER_DELTA = 2e18;

/// @dev The default checkpoint duration of 1 day.
uint256 constant CHECKPOINT_DURATION = 1 days;

/// @title MomoTest
/// @author DELV
/// @dev The test harness for the Momo vault. This harness includes utilities
///      for deploying and interacting with Momo vaults and Hyperdrive pools.
contract MomoTest is Test {
    /// @dev The shared base token between all of the Hyperdrive pools.
    ERC20Mintable internal baseToken;

    /// @dev The ERC20 forwarder factory.
    ERC20ForwarderFactory internal forwarderFactory;

    /// @dev The Hyperdrive admin controller.
    IHyperdriveAdminController internal adminController;

    /// @dev A set of Hyperdrive instances.
    IHyperdrive[] internal hyperdriveInstances;

    /// @dev A mapping of names to Hyperdrive instances.
    mapping(string => IHyperdrive) internal hyperdriveInstancesByName;

    /// @dev A set of test accounts that are pre-funded.
    address internal alice;
    address internal bob;
    address internal celine;
    address internal dan;
    address internal eve;
    address internal feeCollector;
    address internal sweepCollector;
    address internal checkpointRewarder;
    address internal governance;
    address internal pauser;

    /// @notice Sets up the Momo test harness.
    function setUp() external {
        // Set up a list of accounts.
        alice = createUser("alice");
        bob = createUser("bob");
        celine = createUser("celine");
        dan = createUser("dan");
        eve = createUser("eve");
        feeCollector = createUser("feeCollector");
        sweepCollector = createUser("sweepCollector");
        checkpointRewarder = createUser("checkpointRewarder");
        governance = createUser("governance");
        pauser = createUser("pauser");

        // Deploy the base token.
        baseToken = new ERC20Mintable(
            "Base Token",
            "BASE",
            18,
            address(0),
            false,
            type(uint256).max
        );

        // Deploy an admin controller.
        address[] memory pausers = new address[](1);
        pausers[0] = pauser;
        adminController = IHyperdriveAdminController(
            address(
                new MockHyperdriveAdminController(
                    governance,
                    feeCollector,
                    sweepCollector,
                    checkpointRewarder,
                    pausers
                )
            )
        );
    }

    /// @dev Creates a funded user for testing purposes.
    /// @param _name The user's name.
    /// @param user The funded user.
    function createUser(string memory _name) internal returns (address user) {
        user = address(uint160(uint256(keccak256(abi.encode(_name)))));
        vm.label(user, _name);
        vm.deal(user, 10000 ether);
    }

    // ── Deployments ─────────────────────────────────────────────────────

    /// @dev Gets a default test config.
    function hyperdriveConfig(
        uint256 fixedRate,
        uint256 positionDuration
    ) internal returns (IHyperdrive.PoolConfig memory) {
        // Deploy a mock ERC4626 vault.
        MockERC4626 vault = new MockERC4626(
            baseToken,
            "Vault Shares Token",
            "VAULT",
            0,
            address(0),
            false,
            type(uint256).max
        );

        // Create a pool config.
        IHyperdrive.Fees memory fees = IHyperdrive.Fees({
            curve: 0,
            flat: 0,
            governanceLP: 0,
            governanceZombie: 0
        });
        return
            IHyperdrive.PoolConfig({
                baseToken: IERC20(address(baseToken)),
                vaultSharesToken: IERC20(address(vault)),
                linkerFactory: address(forwarderFactory),
                linkerCodeHash: forwarderFactory.ERC20LINK_HASH(),
                initialVaultSharePrice: ONE,
                minimumShareReserves: MINIMUM_SHARE_RESERVES,
                minimumTransactionAmount: MINIMUM_TRANSACTION_AMOUNT,
                circuitBreakerDelta: CIRCUIT_BREAKER_DELTA,
                positionDuration: positionDuration,
                checkpointDuration: CHECKPOINT_DURATION,
                timeStretch: HyperdriveMath.calculateTimeStretch(
                    fixedRate,
                    positionDuration
                ),
                governance: adminController.hyperdriveGovernance(),
                feeCollector: adminController.feeCollector(),
                sweepCollector: adminController.sweepCollector(),
                checkpointRewarder: adminController.checkpointRewarder(),
                fees: fees
            });
    }

    /// @dev Deploy a Hyperdrive instance with a mock ERC4626 yield source.
    /// @param _name The name of the instance.
    /// @param _config The pool config.
    /// @return The Hyperdrive instance.
    function deployHyperdriveInstance(
        string memory _name,
        IHyperdrive.PoolConfig memory _config
    ) internal returns (IHyperdrive) {
        // Deploy the Hyperdrive instance.
        IHyperdrive hyperdrive = IHyperdrive(
            address(
                new ERC4626Hyperdrive(
                    _name,
                    _config,
                    adminController,
                    address(new ERC4626Target0(_config, adminController)),
                    address(new ERC4626Target1(_config, adminController)),
                    address(new ERC4626Target2(_config, adminController)),
                    address(new ERC4626Target3(_config, adminController)),
                    address(new ERC4626Target4(_config, adminController))
                )
            )
        );

        // Add it to the list of instances and the mapping.
        hyperdriveInstances.push(hyperdrive);
        hyperdriveInstancesByName[_name] = hyperdrive;

        return hyperdrive;
    }

    /// @dev Gets Hyperdrive instances by name.
    /// @param _name The name of the instance.
    /// @return The Hyperdrive instance.
    function getHyperdriveInstance(
        string memory _name
    ) external view returns (IHyperdrive) {
        return hyperdriveInstancesByName[_name];
    }

    // ── Interest ────────────────────────────────────────────────────────

    // FIXME: Add an advance time function.

    // ── Trading ─────────────────────────────────────────────────────────

    // FIXME: Add trading functions.
}
