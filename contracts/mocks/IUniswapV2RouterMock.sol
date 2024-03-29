pragma solidity >=0.6.0 <0.7.0;

interface IUniswapV2RouterMock {
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts); 

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

}