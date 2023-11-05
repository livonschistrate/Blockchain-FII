// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import "./ProductStore.sol";

contract ProductDeposit{
    address payable public admin;
    uint public publicTax;
    uint public maxVolume;

    struct product{
        string name;
        address producerAddress;
        int value;
    }

    struct shop{
        string name;
        address productStoreAddress;
    }

    // address[] public producers;
    product[] public products;
    mapping(address => bool) public registeredAddresses;

    constructor(){
        admin = payable(msg.sender);
        publicTax = 5;
        maxVolume = 100;
    }

    modifier maxVolumeReached(){
        require(products.length == maxVolume, "Maximum volume of deposit is reached.");
        _;
    }

    modifier onlyOneProducer(){
        require(msg.sender == admin, "Only one producer can register a product.");
        _;
    }

    event publicTaxChanged(uint newTax);

    function setPublicTax(uint num) public{
        publicTax = num;
        emit publicTaxChanged(publicTax);
    }

    event maxDepositChanged(uint newMax);

    function setMaxDepositVolume(uint num) public{
        maxVolume = num;
        emit maxDepositChanged(maxVolume);
    }

    event depositProductRegistered(address producer);

    function registerDepositProduct(address producer, string memory productName, int productValue, uint units) payable public onlyOneProducer{
        require(msg.value >= publicTax * units, "Insufficient funds for registering products.");
        require(msg.sender == producer, "Producer not authorized to register this product.");
        product memory structProduct = product(productName, producer, productValue);
        for(uint i = 0; i < units; i++)
            products.push(structProduct);
        emit depositProductRegistered(producer);
    }

    function registerStore(shop memory newShop) public{
    }

    event productsDeleted(address producer);

    function deleteProduct(uint indexToDelete) private {
        for(uint j = indexToDelete; j < products.length - 1; j++)
            products[j] = products[j+1];
    }

    function deleteFromDeposit(address producer, product memory productToDelete, uint units) public onlyOneProducer{
        require(msg.sender == producer, "Producer not authorized to delete this product.");
        for(uint i = 0; i < products.length; i++){   
            if(keccak256(abi.encodePacked(products[i].name)) == keccak256(abi.encodePacked(productToDelete.name))
            && products[i].value == productToDelete.value){
                deleteProduct(i);
                units--;
            }
            if(units == 0) 
                break;
        }
        emit productsDeleted(producer);
    }
}