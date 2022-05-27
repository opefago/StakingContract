// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract RCToken is ERC20, Ownable {
    constructor (uint256 _totalSupply) ERC20("Reward Contract Token", "RCT") {
        _mint(msg.sender, _totalSupply);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }
}