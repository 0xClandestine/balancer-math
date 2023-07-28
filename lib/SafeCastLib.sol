// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// TODO: Add Solady version
library SafeCastLib {
    error Overflow();

    function toUint256(int256 x) internal pure returns (uint256) {
        if (x < 0) revert Overflow();
        return uint256(x);
    }
}
