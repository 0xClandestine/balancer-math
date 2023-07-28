// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/solady/src/utils/FixedPointMathLib.sol";

library LiquidityBootstrapLib {
    /// -----------------------------------------------------------------------
    /// Depyencies
    /// -----------------------------------------------------------------------

    using FixedPointMathLib for *;

    /// -----------------------------------------------------------------------
    /// Linear Curve
    /// -----------------------------------------------------------------------

    function linearInterpolation(uint256 x, uint256 y, uint256 i, uint256 n)
        internal
        pure
        returns (uint256)
    {
        // -----------------------------------------------------------------------
        //
        //         ⎛ |x - y| ⎞
        // x ± i ⋅   ─────────
        //         ⎝    n    ⎠
        // -----------------------------------------------------------------------

        if (i > n) i = n;

        return x > y
            ? x.rawSub(x.rawSub(y).mulDiv(i, n))
            : x.rawAdd(y.rawSub(x).mulDiv(i, n));
    }
}
