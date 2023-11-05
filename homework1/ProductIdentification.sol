// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

contract ProductIdentification{
    address payable public admin;
    uint public publicTax;
    mapping(address => producer) public contractState;

    struct product{
        string name;
        address producerAddress;
        int value;
    }

    struct producer{
        bool signedUp;
        string name;
        address producerAddress;
        product[] products;
    }

    // mapping(address => producer) public producers;
    address[] public producers;
    product[] public products;

    constructor(){
        admin = payable(msg.sender);
        publicTax = 5;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can set the public tax.");
        _;
    }

    modifier onlyOneProducer(){
        bool isProducer = false;
        for(uint i = 0; i < producers.length; i++)
            if(msg.sender == producers[i]){
                isProducer = true;
                break;
            }
        require(isProducer, "Only one producer can register a product.");
        _;
    }

    event publicTaxChanged(uint newPublicTax);

    function setPublicTax(uint num) public onlyAdmin{
        publicTax = num;
        emit publicTaxChanged(publicTax);
    }

    event producerRegistered(address newProducer);

    function registerProducer() public payable{
        require(msg.value >= publicTax, "Insufficient funds for registering a producer.");
        contractState[msg.sender].signedUp = true;
        admin.transfer(publicTax);
        emit producerRegistered(msg.sender);
    }

    event productRegistered(address producer, string productName, int productValue);

    function registerProduct(producer memory theProducer, string memory productName, int productValue) public onlyOneProducer{
        product memory structProduct = product(productName, theProducer.producerAddress, productValue);
        products.push(structProduct);
        emit productRegistered(theProducer.producerAddress, productName, productValue);
    }

    function getProducer(producer memory theProducer) public view returns (bool){
        for(uint i = 0; i < producers.length; i++)
            if(producers[i] == theProducer.producerAddress)
                return true;
        return false;
    }

    function getInfoProductById(uint id) public view returns (string memory, address, int){
        return (products[id].name, products[id].producerAddress, products[id].value);
    }
}