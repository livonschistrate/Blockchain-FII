// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import "./ProductDeposit.sol";
import "contracts/homework1/ProductIdentification.sol";

contract ProductStore{
    address payable public admin;
    ProductDeposit public contractDeposit;
    ProductIdentification public contractIdentification;

    struct product{
        string name;
        address producerAddress;
        int value;
    }

    struct producer{
        string name;
        address producerAddress;
        product[] products;
    }

    constructor(){
        admin = payable(msg.sender);
        contractDeposit = new ProductDeposit();
        contractIdentification = new ProductIdentification();
        // publicTax = 5;
    }

    function setContractDeposit(ProductDeposit newDeposit) public{
        contractDeposit = newDeposit;
    }

    function setContractIdentification(ProductIdentification newIdentification) public{
        contractIdentification = newIdentification;
    }

    function addProductInStore() public{
        
    }

}