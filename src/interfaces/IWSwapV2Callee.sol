// SPDX-License-Identifier: UNKNOWN 
pragma solidity >=0.5.0;

interface IWSwapV2Callee {
    function call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}