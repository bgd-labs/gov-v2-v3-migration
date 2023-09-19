// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMediator {
  error InvalidCaller();

  // error - cancelled

  // error - already executed

  /**
   * @notice return the execution state of the goverment v2-v3 migration
   **/
  function getIsExecuted() external returns (bool);

  /**
   * @notice return wether the migration was cancelled
   **/
  function getIsCancelled() external returns (bool);

  /**
   * @notice accept short executor admin permission
   **/
  function acceptShortAdmin() external;

  /**
   * @notice accept long executor admin permission
   **/
  function acceptLongAdmin() external;

  /**
   * @notice execute governance v2-v3 migration
   * @dev contract must hold both short and long executor admin permissions
   **/
  function execute() external;

  /**
   * @notice cancel the migration and revert short/long executor permissions back to Governance v2
   * @dev emergency admin is able to cancel the migration
   **/
  function cancel() external;
}
