// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

import { IHyperdrive } from "hyperdrive/src/interfaces/IHyperdrive.sol";
import { IMomo } from "./interfaces/IMomo.sol";
import { MOMO_KIND, VERSION } from "./libraries/Constants.sol";

/// @author DELV
/// @title Momo
/// @notice A principal protected vault powered by Hyperdrive. This vault gives
///         multiplied exposure by taking advantage of fixed rate spreads.
/// @custom:disclaimer The language used in this code is for coding convenience
///                    only, and is not intended to, and does not, have any
///                    particular legal or regulatory significance.
contract Momo is IMomo {
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

    // ─────────────────────────── State ────────────────────────

    /// @dev Name of the Momo token.
    string public name;

    /// @dev Symbol of the Momo token.
    string public symbol;

    /// @dev Address of the contract admin.
    address public admin;

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
    /// @param _name Name of the Momo vault token.
    /// @param _symbol Symbol of the Momo vault token.
    /// @param _longPositionSource The Hyperdrive pool to buy long positions from.
    /// @param _shortPositionSource The Hyperdrive pool to buy short positions from.
    constructor(
        string memory _name,
        string memory _symbol,
        IHyperdrive _longPositionSource,
        IHyperdrive _shortPositionSource
    ) {
        // Set the name and symbol.
        name = _name;
        symbol = _symbol;

        // Set the position sources.
        longPositionSource = _longPositionSource;
        shortPositionSource = _shortPositionSource;

        // Set the admin to the contract deployer.
        admin = msg.sender;
    }
}
