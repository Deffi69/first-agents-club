// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title First Agents Club Token (FAC)
/// @notice The companion ERC-20 of First Agents Club. Fixed supply of
///         10,000,000 FAC, minted once to the deployer in the constructor.
///         There is deliberately NO mint function, no burn, no tax or fee,
///         no blacklist, no pause switch and no owner: after deployment
///         nobody can create more FAC, destroy it, or interfere with any
///         holder's balance. The Pioneer Badge contract pays 8,000 FAC to
///         each badge claimer out of the FAC balance it is funded with.
contract FAC {
    // --- ERC-20 metadata --------------------------------------------------
    string public constant name = "First Agents Club Token";
    string public constant symbol = "FAC";
    uint8 public constant decimals = 18;

    /// @notice Fixed forever: 10,000,000 FAC, created once at deployment.
    uint256 public constant totalSupply = 10_000_000 * 10 ** 18;

    // --- State ------------------------------------------------------------
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Events -----------------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // --- ERC-20 surface ---------------------------------------------------
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        returns (bool)
    {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance too low");
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    // --- Internal ---------------------------------------------------------
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "transfer to zero address");
        uint256 bal = balanceOf[from];
        require(bal >= amount, "insufficient balance");
        unchecked {
            balanceOf[from] = bal - amount;
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}
