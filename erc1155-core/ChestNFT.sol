// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./../model/ChestInfo.sol";
import "./../utils/SigUtil.sol";

contract ChestNFT is
    Context,
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Burnable,
    EIP712,
    SigUtil
{
    using Counters for Counters.Counter;

    mapping(uint256 => ChestInfo) internal _chests;
    mapping(address => Counters.Counter) internal _nonces;

    event UpdateChest(uint256 indexed chestId, string name);
    event OpenChest(
        address indexed owner,
        uint256 indexed chestId,
        uint256 amount
    );
    event MintChest(
        address indexed owner,
        uint256 indexed id,
        uint256 amount,
        bytes32 indexed ticketId
    );
    event CancelMintChest(address indexed owner, bytes32 indexed ticketId);

    constructor(string memory name)
        ERC1155("https://api.kingdomquest.io/")
        EIP712(name, "1")
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateChest(
        uint256 chestId,
        uint256 fee,
        string memory name
    ) public onlyOwner {
        _chests[chestId] = ChestInfo(chestId, fee, name, true);
        emit UpdateChest(chestId, name);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _increaseNonce(address owner) internal {
        _nonces[owner].increment();
    }

    function _currentNonce(address owner) internal view returns (uint256) {
        return _nonces[owner].current();
    }

    function _recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(hash, signature);
    }
}
