// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

import { IERC20 } from "hyperdrive/src/interfaces/IERC20.sol";
import { IHyperdrive } from "hyperdrive/src/interfaces/IHyperdrive.sol";
import { ERC4626 } from "solady/tokens/ERC4626.sol";
import { IMomo } from "./interfaces/IMomo.sol";
import { MOMO_KIND, VERSION } from "./libraries/Constants.sol";

/// @author DELV
/// @title Momo
/// @notice A principal protected vault powered by Hyperdrive. This vault gives
///         multiplied exposure by taking advantage of fixed rate spreads.
/// @custom:disclaimer The language used in this code is for coding convenience
///                    only, and is not intended to, and does not, have any
///                    particular legal or regulatory significance.
contract Momo is IMomo, ERC4626 {
    // ╭─────────────────────────────────────────────────────────╮
    // │ Storage                                                 │
    // ╰─────────────────────────────────────────────────────────╯

    // ───────────────────────── Constants ───────────────────────

    /// @notice The kind of the Momo vault.
    string public constant kind = MOMO_KIND;

    /// @notice The version of the Momo vault.
    string public constant version = VERSION;

    // ───────────────────────── Immutables ──────────────────────

    /// @notice The Hyperdrive pool to buy longs from.
    IHyperdrive public immutable longPositionSource;

    /// @notice The Hyperdrive pool to buy shorts from.
    IHyperdrive public immutable shortPositionSource;

    /// @dev The decimals of the Momo token.
    uint8 internal immutable _decimals;

    /// @dev The asset underlying all of the investments.
    IERC20 internal immutable _asset;

    // ─────────────────────────── State ────────────────────────

    /// @notice The admin address.
    address public admin;

    /// @dev The name of the Momo token.
    string internal _name;

    /// @dev The symbol of the Momo token.
    string internal _symbol;

    // ╭─────────────────────────────────────────────────────────╮
    // │ Modifiers                                               │
    // ╰─────────────────────────────────────────────────────────╯

    /// @dev Ensures that the contract is being called by admin.
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert IMomo.Unauthorized();
        }
        _;
    }

    // ╭─────────────────────────────────────────────────────────╮
    // │ Constructor                                             │
    // ╰─────────────────────────────────────────────────────────╯

    /// @notice Instantiates the Momo vault.
    /// @param __name Name of the Momo vault token.
    /// @param __symbol Symbol of the Momo vault token.
    /// @param __decimals The Momo vault token decimals.
    /// @param _longPositionSource The Hyperdrive pool to buy long positions from.
    /// @param _shortPositionSource The Hyperdrive pool to buy short positions from.
    /// @param __asset The asset underlying both the long and short sources.
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        IHyperdrive _longPositionSource,
        IHyperdrive _shortPositionSource,
        IERC20 __asset
    ) {
        // Set the name and symbol.
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;

        // Set the position sources.
        longPositionSource = _longPositionSource;
        shortPositionSource = _shortPositionSource;

        // TODO: We'll need to generalize this quite a bit to support real
        // integrations.
        //
        // Set the asset.
        _asset = __asset;

        // Set the admin to the contract deployer.
        admin = msg.sender;
    }

    // ╭─────────────────────────────────────────────────────────╮
    // │ Getters                                                 │
    // ╰─────────────────────────────────────────────────────────╯

    // ───────────────────────── ERC20 ───────────────────────────

    /// @notice Returns the name of the Momo token.
    /// @return The name of the Momo token.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the Momo token.
    /// @return The symbol of the Momo token.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the decimals places of the Momo token.
    /// @return The Momo token decimals.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // ───────────────────────── ERC4626 ─────────────────────────

    /// @notice Returns the asset underlying all of the investments.
    /// @return The asset.
    function asset() public view override returns (address) {
        return address(_asset);
    }

    // TODO: This needs to be updated with the Momo portfolio valuation.
    //
    /// @notice Returns the total value of Momo's portfolio measured in the
    ///         underlying asset.
    /// @return The total value of Momo's portfolio.
    function totalAssets() public view override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /// @dev The number of decimals of the underlying asset.
    /// @return The number of underlying decimals.
    function _underlyingDecimals() internal view override returns (uint8) {
        return _decimals;
    }

    // TODO: Is this sufficient?
    //
    /// @dev The number of decimals of the virtual shares. This helps to avoid
    ///      inflation attacks.
    function _decimalsOffset() internal view override returns (uint8) {
        return _decimals > 6 ? _decimals - 3 : _decimals;
    }
}
