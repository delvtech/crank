// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

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

    // ───────────────────────── Immutables ──────────────────────

    /// @dev Name of the Momo token.
    string public _name;

    /// @dev Symbol of the Momo token.
    string internal _symbol;

    /// @notice The kind of the Momo vault.
    string public constant kind = MOMO_KIND;

    /// @notice The version of the Momo vault.
    string public constant version = VERSION;

    // ─────────────────────────── State ────────────────────────

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
    /// @param __name Name of the Momo vault token.
    /// @param __symbol Symbol of the Momo vault token.
    constructor(string memory __name, string memory __symbol) {
        // Set the name and symbol.
        _name = __name;
        _symbol = __symbol;

        // Set the admin to the contract deployer.
        admin = msg.sender;
    }
}
