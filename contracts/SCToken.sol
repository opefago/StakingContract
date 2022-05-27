// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract SCToken is ERC20, Ownable {
    constructor (uint256 _totalSupply) ERC20("Staking Contract Token", "SCT") {
        _mint(msg.sender, _totalSupply);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    
}