// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

/// @title IMomo
/// @author DELV
/// @notice The Momo vault interface.
interface IMomo {
    /// @notice Thrown when an unauthorized user attempts to access admin
    ///         functionality.
    error Unauthorized();

    // FIXME: Can this be pure?
    //
    /// @notice Gets the kind of the Momo vault.
    /// @return The kind of the Momo vault.
    function kind() external view returns (string memory);

    // FIXME: Can this be pure?
    //
    /// @notice Gets the version of the Momo vault.
    /// @return The version of the Momo vault.
    function version() external view returns (string memory);
}
