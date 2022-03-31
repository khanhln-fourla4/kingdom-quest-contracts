// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./../erc1155-core/ChestNFT.sol";
import "./../model/ChestInfo.sol";

contract HeroChestNFT is ChestNFT {
    using SafeERC20 for IERC20;

    bytes32 private immutable _TYPE_HASH;

    IERC20 private _kgc;
    address private _feeRecipient;

    constructor(address kgcAddress, address feeRecipient)
        ChestNFT("Hero Chest")
    {
        _TYPE_HASH = keccak256(
            "MintChest(address owner,uint256 chestId,uint256 amount,uint256 nonce)"
        );
        _kgc = IERC20(kgcAddress);
        _feeRecipient = feeRecipient;
    }

    function mintChest(
        uint256 chestId,
        uint256 amount,
        bytes memory signature
    ) public {
        uint256 nonce = _currentNonce(_msgSender());
        bytes32 structHash = keccak256(
            abi.encode(_TYPE_HASH, _msgSender(), chestId, amount, nonce)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = _recoverSigner(hash, signature);

        require(signer == owner(), "Chest: invalid signature");

        _mint(_msgSender(), chestId, amount, "");

        _increaseNonce(_msgSender());

        emit MintChest(_msgSender(), chestId, amount, sigToBytes32(signature));
    }

    function cancelMintChest(bytes memory mSignature, bytes memory cSignature)
        public
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSig(mSignature);

        uint256 nonce = _currentNonce(_msgSender());

        bytes32 hash = keccak256(
            abi.encodePacked(owner(), _msgSender(), r, s, v, nonce)
        );
        address signer = _recoverSigner(hash, cSignature);

        require(signer == owner(), "Chest: invalid signature");

        _increaseNonce(_msgSender());

        emit CancelMintChest(_msgSender(), sigToBytes32(mSignature));
    }

    function openChest(uint256 chestId, uint256 amount) public {
        require(
            amount <= balanceOf(_msgSender(), chestId),
            "Chest: exceed amount"
        );

        ChestInfo memory chest = _chests[chestId];

        require(chest.initialized, "Chest: not initialized");

        if (chest.fee > 0) {
            _kgc.safeTransferFrom(_msgSender(), _feeRecipient, chest.fee);
        }

        burn(_msgSender(), chestId, amount);

        emit OpenChest(_msgSender(), chestId, amount);
    }

    function getNonce(address player) public view onlyOwner returns (uint256) {
        return _currentNonce(player);
    }
}
