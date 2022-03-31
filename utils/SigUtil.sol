// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract SigUtil {
    function sigToBytes32(bytes memory sig)
        public
        pure
        virtual
        returns (bytes32)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return keccak256(abi.encodePacked(r, s, v));
    }

    function splitSig(bytes memory sig)
        public
        pure
        virtual
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
