pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract ValkyrieBar is ERC20("ValkyrieBar", "xValkyrie"){
    using SafeMath for uint256;
    IERC20 public valkyrie;

    constructor(IERC20 _valkyrie) public {
        valkyrie = _valkyrie;
    }

    // Enter the bar. Pay some Valkyries. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalValkyrie = valkyrie.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalValkyrie == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalValkyrie);
            _mint(msg.sender, what);
        }
        valkyrie.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your Valkyries.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(valkyrie.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        valkyrie.transfer(msg.sender, what);
    }
}
