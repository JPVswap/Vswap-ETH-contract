pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Vswapv2/interfaces/IVswapV2ERC20.sol";
import "./Vswapv2/interfaces/IVswapV2Pair.sol";
import "./Vswapv2/interfaces/IVswapV2Factory.sol";


contract ValkyrieMaker {
    using SafeMath for uint256;

    IVswapV2Factory public factory;
    address public bar;
    address public valkyrie;
    address public weth;

    constructor(IVswapV2Factory _factory, address _bar, address _valkyrie, address _weth) public {
        factory = _factory;
        valkyrie = _valkyrie;
        bar = _bar;
        weth = _weth;
    }

    function convert(address token0, address token1) public {
        // At least we try to make front-running harder to do.
        require(msg.sender == tx.origin, "do not convert from contract");
        IVswapV2Pair pair = IVswapV2Pair(factory.getPair(token0, token1));
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(this));
        uint256 wethAmount = _toWETH(token0) + _toWETH(token1);
        _toValkyrie(wethAmount);
    }

    function _toWETH(address token) internal returns (uint256) {
        if (token == valkyrie) {
            uint amount = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(bar, amount);
            return 0;
        }
        if (token == weth) {
            uint amount = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(factory.getPair(weth, valkyrie), amount);
            return amount;
        }
        IVswapV2Pair pair = IVswapV2Pair(factory.getPair(token, weth));
        if (address(pair) == address(0)) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        IERC20(token).transfer(address(pair), amountIn);
        pair.swap(amount0Out, amount1Out, factory.getPair(weth, valkyrie), new bytes(0));
        return amountOut;
    }

    function _toValkyrie(uint256 amountIn) internal {
        IVswapV2Pair pair = IVswapV2Pair(factory.getPair(weth, valkyrie));
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == weth ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, bar, new bytes(0));
    }
}
