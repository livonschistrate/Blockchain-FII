// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

contract ProductIdentification{
    address payable public admin;
    uint public publicTax;
    mapping(address => producer) public contractState;

    struct product{
        bool isRegistered;
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

    constructor(){
        admin = payable(msg.sender);
        publicTax = 5;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can set the public tax.");
        _;
    }

    modifier onlyOneProducer(){
        require(contractState[msg.sender].signedUp, "Only one producer can register a product.");
        _;
    }

    event publicTaxChanged(uint newPublicTax);

    function setPublicTax(uint num) public onlyAdmin{
        publicTax = num;
        emit publicTaxChanged(publicTax);
    }

    event producerRegistered(string producerName, address newProducer);

    function registerProducer(string memory producerName) public payable{
        require(msg.value >= publicTax, "Insufficient funds for registering a producer.");
        contractState[msg.sender].signedUp = true;
        contractState[msg.sender].name = producerName;
        contractState[msg.sender].producerAddress = msg.sender; 
        admin.transfer(publicTax);
        emit producerRegistered(producerName, msg.sender);
    }

    event productRegistered(address producer, string productName, int productValue);

    function registerProduct(producer memory theProducer, string memory productName, int productValue) public onlyOneProducer{
        product memory structProduct = product(true, productName, theProducer.producerAddress, productValue);
        contractState[theProducer.producerAddress].products.push(structProduct);
        emit productRegistered(theProducer.producerAddress, productName, productValue);
    }

    function getProducer(address producerAddress) public view returns (bool){
        return contractState[producerAddress].signedUp;
    }

    function getInfoProductById(address producerAddress, uint id) public view returns (string memory, int){
        require(contractState[producerAddress].products[id].isRegistered, "Product not registered.");
        return (contractState[producerAddress].products[id].name, contractState[producerAddress].products[id].value);
    }
}