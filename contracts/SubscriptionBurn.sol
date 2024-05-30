// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GemAiSubscriptionService is AccessControl, Ownable {
    using SafeERC20 for ERC20Burnable;

    ERC20Burnable public token;

    struct RoleInfo {
        uint256 price;
        uint256 duration;
    }

    bytes32[] private roles; // Array to store roles for iteration
    mapping(bytes32 => RoleInfo) public rolesInfo;
    mapping(address => mapping(bytes32 => uint256)) public roleExpirations;

    event NewSubscription(address indexed subscriber, bytes32 indexed role, uint256 price, uint256 duration);

    constructor(ERC20Burnable tokenAddress) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = tokenAddress;
    }

    function subscribe(bytes32 role) public returns (bool) {
        require(rolesInfo[role].price > 0, "Role does not exist");

        uint256 rolePrice = rolesInfo[role].price;
        token.safeTransferFrom(msg.sender, address(this), rolePrice);
        token.burn(rolePrice); // Burn function directly from ERC20Burnable

        _grantRole(role, msg.sender);
        roleExpirations[msg.sender][role] = block.timestamp + rolesInfo[role].duration;

        emit NewSubscription(msg.sender, role, rolePrice, rolesInfo[role].duration);

        return true;
    }

    // Add a new role or update existing one
    function addOrUpdateRole(bytes32 role, uint256 price, uint256 duration) public onlyOwner {
        rolesInfo[role] = RoleInfo(price, duration);
        if (!_isRole(role)) {
            roles.push(role); // Add role to array for iteration if it's new
            _setRoleAdmin(role, DEFAULT_ADMIN_ROLE); // Define role admin for new roles
        }
    }

    function hasActiveRole(address account, bytes32 role) public view returns (bool) {
        return hasRole(role, account) && block.timestamp <= roleExpirations[account][role];
    }

    // Helper function to check if a role exists
    function _isRole(bytes32 role) private view returns (bool) {
        for (uint i = 0; i < roles.length; i++) {
            if (roles[i] == role) {
                return true;
            }
        }
        return false;
    }

    // Change the price of an existing role
    function changeRolePrice(bytes32 role, uint256 newPrice) public onlyOwner {
        require(_isRole(role), "Role does not exist");
        rolesInfo[role].price = newPrice;
    }

    function checkManyRoles(address account, bytes32[] memory rolesToCheck) public view returns (bool) {
        for (uint i = 0; i < rolesToCheck.length; i++) {
            if (hasActiveRole(account, rolesToCheck[i])) {
                return true;
            }
        }
        return false;
    }

    // List all roles - mainly for external visibility or UI components
    function listRoles() public view returns (bytes32[] memory) {
        return roles;
    }

    // Function to get the expiration time of a specific role for an account
    function getRoleExpiration(address account, bytes32 role) public view returns (uint256) {
        return roleExpirations[account][role];
    }

    // Override _grantRole to set the role expiration
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool) {
        bool granted = super._grantRole(role, account);
        if (granted && rolesInfo[role].duration > 0) {
            roleExpirations[account][role] = block.timestamp + rolesInfo[role].duration;
        }
        return granted;
    }

    // Public function to grant role and set expiration (for admin)
    function grantRoleWithExpiration(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }
}