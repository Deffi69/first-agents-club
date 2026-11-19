// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal read interface for the SPACE ID Agent ID contract (BSC).
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

/// @notice Minimal ERC-20 surface used to pay the claim reward.
interface IERC20Reward {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title First Agents Club (FAC)
/// @notice The Pioneer Badge of First Agents Club: a free, one-per-wallet
///         badge NFT that only Binance Agent ID holders can claim. The badge
///         contract checks ownership of an Agent ID on BNB Chain (SPACE ID
///         Agent ID, 0x60b9262456de011f7d15a54cdd8c48baaa8b022f) at claim
///         time. No fee, no sale, no transfer function: the badge is a
///         proof-of-participation keepsake, nothing more.
///         Each successful claim also pays 8,000 FAC (the First Agents Club
///         Token) out of this contract's own FAC balance, in the same
///         transaction. If this contract holds less than 8,000 FAC, the
///         badge claim still succeeds and simply pays 0 FAC. FAC can only
///         ever leave this contract through claim payouts: there is no
///         withdrawal or sweep function.
///         The total badge supply is capped at deployment (production:
///         1,000 badges); once the cap is reached, further claims revert
///         as sold out.
contract AgentIDPioneerBadge {
    // --- ERC-721 metadata -------------------------------------------------
    string public constant name = "First Agents Club";
    string public constant symbol = "FAC";

    // --- State ------------------------------------------------------------
    /// @notice The Agent ID contract checked at claim time (immutable).
    address public immutable agentIDContract;
    /// @notice The FAC token paid out on each claim (immutable; the zero
    ///         address disables rewards).
    IERC20Reward public immutable facToken;
    /// @notice FAC paid per badge claim: 8,000 FAC.
    uint256 public constant CLAIM_REWARD = 8000 * 10 ** 18;
    /// @notice Maximum number of badges that can ever be claimed
    ///         (set once at deployment; production: 1,000).
    uint256 public immutable maxSupply;
    /// @notice Deployer; may only update the metadata base URI.
    address public owner;

    string private _baseURI;

    /// @notice Total badges claimed so far; also the latest token id.
    uint256 public totalClaimed;
    /// @notice True once an address has claimed its badge.
    mapping(address => bool) public hasClaimed;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    // --- Events -----------------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event BadgeClaimed(address indexed claimer, uint256 indexed tokenId);
    event TokenRewardPaid(address indexed claimer, uint256 amount);
    event BaseURISet(string newBaseURI);

    constructor(
        address agentIDContract_,
        string memory baseURI_,
        address facToken_,
        uint256 maxSupply_
    ) {
        require(agentIDContract_ != address(0), "agent id = zero address");
        require(maxSupply_ > 0, "max supply = 0");
        agentIDContract = agentIDContract_;
        facToken = IERC20Reward(facToken_);
        maxSupply = maxSupply_;
        owner = msg.sender;
        _baseURI = baseURI_;
    }

    // --- Claim ------------------------------------------------------------
    /// @notice Claim your badge. Requires holding at least one Agent ID.
    ///         One badge per wallet, ever. Free: no fee is taken.
    ///         Reverts "sold out" once maxSupply badges have been claimed.
    ///         Pays 8,000 FAC in the same transaction when this contract
    ///         holds at least 8,000 FAC; otherwise pays 0 FAC (the badge
    ///         claim itself never fails because of the reward).
    function claim() external {
        require(!hasClaimed[msg.sender], "already claimed");
        require(totalClaimed < maxSupply, "sold out");
        require(
            IAgentID(agentIDContract).balanceOf(msg.sender) > 0,
            "no Agent ID held"
        );
        hasClaimed[msg.sender] = true;
        uint256 tokenId = ++totalClaimed;
        _owners[tokenId] = msg.sender;
        _balances[msg.sender] = 1;
        emit Transfer(address(0), msg.sender, tokenId);
        emit BadgeClaimed(msg.sender, tokenId);
        uint256 paid = _payReward(msg.sender);
        emit TokenRewardPaid(msg.sender, paid);
    }

    /// @notice Pay the FAC claim reward out of this contract's own FAC
    ///         balance. Returns the amount actually paid (0 when rewards
    ///         are disabled, the balance is below 8,000 FAC, or the token
    ///         call fails for any reason) so a reward problem can never
    ///         block a badge claim.
    function _payReward(address claimer) internal returns (uint256 paid) {
        if (address(facToken) == address(0)) return 0;
        uint256 available;
        try facToken.balanceOf(address(this)) returns (uint256 bal) {
            available = bal;
        } catch {
            return 0;
        }
        if (available < CLAIM_REWARD) return 0;
        try facToken.transfer(claimer, CLAIM_REWARD) returns (bool ok) {
            if (ok) return CLAIM_REWARD;
        } catch {}
        return 0;
    }

    // --- Owner (metadata only) -------------------------------------------
    /// @notice Point tokenURI at a new metadata host. Settable by owner only.
    function setBaseURI(string calldata newBaseURI) external {
        require(msg.sender == owner, "not owner");
        _baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    // --- ERC-721 read surface --------------------------------------------
    // Transfers and approvals are intentionally NOT implemented: a Pioneer
    // Badge is a personal keepsake and cannot change hands.
    function balanceOf(address account) external view returns (uint256) {
        require(account != address(0), "zero address");
        return _balances[account];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address o = _owners[tokenId];
        require(o != address(0), "nonexistent token");
        return o;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_owners[tokenId] != address(0), "nonexistent token");
        return string(abi.encodePacked(_baseURI, _toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC-721
            interfaceId == 0x5b5e139f || // ERC-721 Metadata
            interfaceId == 0x01ffc9a7;   // ERC-165
    }

    // --- Internal ---------------------------------------------------------
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
