// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {WeightedMathLib as Custom} from "src/WeightedMathLib.sol";
import {WeightedMathLib as Reference} from "../Reference.sol";

uint256 constant amountIn = 1 ether;
uint256 constant amountOut = 1 ether;
uint256 constant reserveIn = 100 ether;
uint256 constant reserveOut = 100 ether;
uint256 constant weightIn = 0.6 ether;
uint256 constant weightOut = 0.4 ether;

contract WeightedMathLibTest is Test {
    uint256 ACCEPTABLE_RELATIVE_SWAP_ERROR = 50000;
    uint256 ACCEPTABLE_RELATIVE_INVARIANT_ERROR = 20000;

    function testGetInvariant() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = reserveIn;
        reserves[1] = reserveOut;

        uint256[] memory weights = new uint256[](2);
        weights[0] = weightIn;
        weights[1] = weightOut;

        uint256 a = Custom.getInvariant(reserves, weights);
        uint256 b =
            Custom.getInvariant(reserveIn, reserveOut, weightIn, weightOut);
        uint256 c = Reference._calculateInvariant(weights, reserves);

        assertEq(a, b);
        assertApproxEqRel(b, c, ACCEPTABLE_RELATIVE_INVARIANT_ERROR);
    }

    function testGetAmountIn() public {
        assertApproxEqRel(
            Custom.getAmountIn(
                amountOut, reserveIn, reserveOut, weightIn, weightOut
            ),
            Reference._calcInGivenOut(
                reserveIn, weightIn, reserveOut, weightOut, amountOut
            ),
            ACCEPTABLE_RELATIVE_SWAP_ERROR
        );
    }

    function testGetAmountOut() public {
        assertApproxEqRel(
            Custom.getAmountOut(
                amountIn, reserveIn, reserveOut, weightIn, weightOut
            ),
            Reference._calcOutGivenIn(
                reserveIn, weightIn, reserveOut, weightOut, amountIn
            ),
            ACCEPTABLE_RELATIVE_SWAP_ERROR
        );
    }

    function testRoundTripGetAmountOut() public {
        uint256 invariantBefore =
            Custom.getInvariant(reserveIn, reserveOut, weightIn, weightOut);

        uint256 invariantAfter = Custom.getInvariant(
            reserveIn + amountIn,
            reserveOut
                - Custom.getAmountOut(
                    amountIn, reserveIn, reserveOut, weightIn, weightOut
                ),
            weightIn,
            weightOut
        );

        assertTrue(invariantBefore <= invariantAfter);
    }

    modifier LogGas(
        function (uint256, uint256, uint256, uint256, uint256) pure returns (uint256)
            func,
        uint256 param0,
        uint256 param1,
        uint256 param2,
        uint256 param3,
        uint256 param4,
        string memory label
    ) {
        uint256 gasLeftBefore = gasleft();
        func(param0, param1, param2, param3, param4);
        uint256 gasLeftAfter = gasleft();
        _;
        console.log(label, gasLeftBefore - gasLeftAfter);
    }

    function testGetAmountOutGasCustom()
        public
        LogGas(
            Reference._calcOutGivenIn,
            reserveIn,
            0.6 ether,
            reserveOut,
            0.4 ether,
            amountIn,
            "Reference:"
        )
        LogGas(
            Custom.getAmountOut,
            amountIn,
            reserveIn,
            reserveOut,
            0.6 ether,
            0.4 ether,
            "Custom:"
        )
    {}
}
