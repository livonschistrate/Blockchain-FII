// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

contract ProductIdentification{
    struct product{
        bool isRegistered;
        string name;
        address producerAddress;
        uint value;
        uint quantity;
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
    product[] products;

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

        payable(msg.sender).transfer(msg.value - publicTax);
        admin.transfer(publicTax);
        emit producerRegistered(producerName, msg.sender);
    }

    event productRegistered(address producer, string productName, uint productValue);

    function registerProduct(string memory productName, uint productValue) public onlyOneProducer{
        product memory newProduct;
        newProduct.isRegistered = true;
        newProduct.name = productName;
        newProduct.producerAddress = msg.sender;
        newProduct.value = productValue;

        contractState[msg.sender].products.push(newProduct);
        products.push(newProduct);
        emit productRegistered(msg.sender, productName, productValue);
    }

    function isProducerSignedUp(address producerAddress) public view returns (bool){
        return contractState[producerAddress].signedUp;
    }

    function getProducerInfo(address producerAddress) public view returns (bool, string memory, address, product[] memory){
        return (contractState[producerAddress].signedUp,
        contractState[producerAddress].name,
        contractState[producerAddress].producerAddress,
        contractState[producerAddress].products);
    }

    function getInfoProductById(uint id) public view returns (bool, string memory, address, uint){
        require(products[id].isRegistered, "Product not registered.");
        require(products.length > id, "Index out of bounds.");
        return (products[id].isRegistered,
        products[id].name,
        products[id].producerAddress,
        products[id].value);
    }
    
    
}