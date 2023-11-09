// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

contract ProductIdentification{
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
    
    address payable public admin;
    uint public publicTax;
    mapping(address => producer) public contractState;

    constructor(uint newTax){
        admin = payable(msg.sender);
        publicTax = newTax;
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

    function registerProduct(string memory productName, int productValue) public onlyOneProducer{
        product memory newProduct = product(true, productName, msg.sender, productValue);
        contractState[msg.sender].products.push(newProduct);
        emit productRegistered(msg.sender, productName, productValue);
    }

    function isProducerSignedIn(address producerAddress) public view returns (bool){
        return contractState[producerAddress].signedUp;
    }

    function getInfoProductById(uint id) public view returns (bool, string memory, address, int){
        require(contractState[msg.sender].products[id].isRegistered, "Product not registered.");
        return (contractState[msg.sender].products[id].isRegistered,
        contractState[msg.sender].products[id].name,
        contractState[msg.sender].products[id].producerAddress,
        contractState[msg.sender].products[id].value);
    }
    
}