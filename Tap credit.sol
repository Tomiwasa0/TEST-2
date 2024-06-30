// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    function mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return (a * b + c - 1) / c;
    }

    function mulDivDown(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return (a * b) / c;
    }
}

library Errors {
    error NOT_ENOUGH_CASH(uint256 maxCashAmountOutFragmentation, uint256 cashAmountOut);
}

contract Main {
    uint256 constant PERCENT = 1e18;
     uint256 constant YEAR= 31536000;

    struct FeeConfig {
        uint256 fragmentationFee;
    }

   FeeConfig public feeConfig;

    function getSwapFeePercent( uint256 tenor) internal view returns (uint256) {
        // Dummy implementation
        return Math.mulDivUp(5e15, tenor, YEAR); // Assume swap fee is proportional to tenor for testing purposes.
    }
    function getSwapFee(uint256 cash, uint256 tenor) internal view returns (uint256) {
        return Math.mulDivUp(cash, getSwapFeePercent( tenor), PERCENT);
    }
     

    function getCreditAmountIn(
        uint256 cashAmountOut,
        uint256 maxCashAmountOut,
        uint256 maxCredit,
        uint256 ratePerTenor,
        uint256 tenor
    ) public  view returns (uint256 creditAmountIn, uint256 fees) {
        uint256 swapFeePercent = getSwapFeePercent( tenor);

        uint256 maxCashAmountOutFragmentation = 0;

        if (maxCashAmountOut >= feeConfig.fragmentationFee) {
            maxCashAmountOutFragmentation = maxCashAmountOut - feeConfig.fragmentationFee;
        }

        if (cashAmountOut == maxCashAmountOut) {
            creditAmountIn = maxCredit;
            fees = Math.mulDivUp(cashAmountOut, swapFeePercent, PERCENT);
        } else if (cashAmountOut < maxCashAmountOutFragmentation) {
            creditAmountIn = Math.mulDivUp(
                cashAmountOut + feeConfig.fragmentationFee, PERCENT + ratePerTenor, PERCENT - swapFeePercent
            );
            // creditAmountIn= creditAmountIn ;
            fees = Math.mulDivUp(cashAmountOut + feeConfig.fragmentationFee, swapFeePercent, PERCENT) + feeConfig.fragmentationFee;
        } else {
            revert Errors.NOT_ENOUGH_CASH(maxCashAmountOutFragmentation, cashAmountOut);
        }
    }
     function setFragmentationFee() external {
        feeConfig.fragmentationFee = 5e6;
    }

     function protocolgetCreditAmountIn(
        uint256 cashAmountOut,
        uint256 maxCashAmountOut,
        uint256 maxCredit,
        uint256 ratePerTenor,
        uint256 tenor
    ) public  view returns (uint256 creditAmountIn, uint256 fees) {
        uint256 swapFeePercent = getSwapFeePercent( tenor);

        uint256 maxCashAmountOutFragmentation = 0;

        if (maxCashAmountOut >= feeConfig.fragmentationFee) {
            maxCashAmountOutFragmentation = maxCashAmountOut - feeConfig.fragmentationFee;
        }

        // slither-disable-next-line incorrect-equality
        if (cashAmountOut == maxCashAmountOut) {
            // no credit fractionalization

            creditAmountIn = maxCredit;
            fees = Math.mulDivUp(cashAmountOut, swapFeePercent, PERCENT);
        } else if (cashAmountOut < maxCashAmountOutFragmentation) {
            // credit fractionalization

            creditAmountIn = Math.mulDivUp(
                cashAmountOut + feeConfig.fragmentationFee, PERCENT + ratePerTenor, PERCENT - swapFeePercent
            );
            fees = Math.mulDivUp(cashAmountOut, swapFeePercent, PERCENT) + feeConfig.fragmentationFee;
        } else {
            // for maxCashAmountOutFragmentation < amountOut < maxCashAmountOut we are in an inconsistent situation
            //   where charging the swap fee would require to sell a credit that exceeds the max possible credit

            revert Errors.NOT_ENOUGH_CASH(maxCashAmountOutFragmentation, cashAmountOut);
        }
    }
}
