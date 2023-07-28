// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/solady/src/utils/FixedPointMathLib.sol";
import "lib/SafeCastLib.sol";

library WeightedMathLib {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeCastLib for *;
    using FixedPointMathLib for *;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ZeroInvariant();
    error AmountInTooLarge();
    error AmountOutTooLarge();

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)
    uint256 internal constant MAX_PERCENTAGE_IN = 0.3 ether;
    uint256 internal constant MAX_PERCENTAGE_OUT = 0.3 ether;

    /// -----------------------------------------------------------------------
    ///  Weighted Arithmetic
    /// -----------------------------------------------------------------------

    function getSpotPrice(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256) {
        // -----------------------------------------------------------------------
        // (reserveIn / weightIn) / (reserveOut / weightOut)
        // -----------------------------------------------------------------------

        return reserveIn.divWad(weightIn).divWad(reserveOut.divWad(weightOut));
    }

    function getInvariant(uint256[] memory reserves, uint256[] memory weights)
        internal
        pure
        returns (uint256 invariant)
    {
        // -----------------------------------------------------------------------
        //   ____
        //   ⎟⎟          weight
        //   ⎟⎟  reserve ^     = i
        //   n = totalAssets
        // -----------------------------------------------------------------------

        invariant = 1e18;

        for (uint256 i; i < weights.length; i = i.rawAdd(1)) {
            invariant = invariant.mulWad(
                int256(reserves[i]).powWad(int256(weights[i])).toUint256()
            );
        }

        if (invariant == 0) revert ZeroInvariant();
    }

    function getInvariant(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256 invariant) {
        // -----------------------------------------------------------------------
        //   ____
        //   ⎟⎟          weight
        //   ⎟⎟  reserve ^     = i
        //   n = 2
        // -----------------------------------------------------------------------

        invariant = 1e18.mulWad(powWad(reserveIn, weightIn)).mulWad(
            powWad(reserveOut, weightOut)
        );

        if (invariant == 0) revert ZeroInvariant();
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256) {
        unchecked {
            // -----------------------------------------------------------------------
            //
            //             ⎛                       ⎛weightIn ⎞    ⎞
            //             ⎜                        ─────────      ⎟
            //             ⎜                       ⎝weightOut⎠    ⎟
            //             ⎜⎛     reserveOut      ⎞               ⎟
            // reserveIn ⋅    ─────────────────────             - 1
            //             ⎝⎝reserveOut - amountIn⎠               ⎠
            // -----------------------------------------------------------------------

            // Assert `amountOut` cannot exceed `MAX_PERCENTAGE_OUT`.
            if (amountOut > reserveOut.mulWad(MAX_PERCENTAGE_OUT)) {
                revert AmountOutTooLarge();
            }

            // `MAX_PERCENTAGE_OUT` check ensures `amountOut` is always less than `reserveOut`.
            return reserveIn.mulWadUp(
                powWadUp(
                    reserveOut.divWadUp(reserveOut.rawSub(amountOut)),
                    weightOut.divWadUp(weightIn)
                ) - 1 ether
            );
        }
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256) {
        // -----------------------------------------------------------------------
        //
        //             ⎛                          ⎛weightIn ⎞⎞
        //             ⎜                           ─────────  ⎟
        //             ⎜                          ⎝weightOut⎠⎟
        //             ⎜    ⎛      reserveIn     ⎞           ⎟
        // reserveOut ⋅  1 -  ────────────────────
        //             ⎝    ⎝reserveIn + amountIn⎠           ⎠
        // -----------------------------------------------------------------------

        // Assert `amountIn` cannot exceed `MAX_PERCENTAGE_IN`.
        if (amountIn > reserveIn.mulWad(MAX_PERCENTAGE_IN)) {
            revert AmountInTooLarge();
        }

        return reserveOut.mulWad(
            complement(
                powWadUp(
                    reserveIn.divWadUp(reserveIn + amountIn),
                    weightIn.divWad(weightOut)
                )
            )
        );
    }

    /// -----------------------------------------------------------------------
    /// Fixed-point Arithmetic
    /// -----------------------------------------------------------------------

    function powWad(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 1 ether) {
            return x;
        } else if (y == 2 ether) {
            return x.mulWad(x);
        } else if (y == 4 ether) {
            uint256 square = x.mulWad(x);
            return square.mulWad(square);
        }

        return int256(x).powWad(int256(y)).toUint256();
    }

    function powWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 1 ether) {
            return x;
        } else if (y == 2 ether) {
            return x.mulWadUp(x);
        } else if (y == 4 ether) {
            uint256 square = x.mulWadUp(x);
            return square.mulWadUp(square);
        }

        uint256 power = int256(x).powWad(int256(y)).toUint256();
        return power + power.mulWadUp(MAX_POW_RELATIVE_ERROR) + 1;
    }

    function complement(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mul(lt(x, 0xde0b6b3a7640000), sub(0xde0b6b3a7640000, x))
        }
    }
}
