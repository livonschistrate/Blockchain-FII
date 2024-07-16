// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SampleToken.sol";

contract ProductIdentification{
    struct product{
        uint id;
        bool isRegistered;
        string name;
        address producerAddress;
        uint volume;
    }

    struct producer{
        bool signedUp;
        string name;
        address producerAddress;
        // product[] products;
        uint registeredProducts;
    }
    
    address public admin;
    uint256 public publicTax;
    SampleToken tokenContract;

    mapping(address => producer) public producers;
    mapping(uint => product) public products;
    mapping(string => bool) public brandExists;
    uint registeredProducts = 0;

    constructor(SampleToken newTokenContract, uint newTax){
        admin = msg.sender;
        tokenContract = newTokenContract;
        publicTax = newTax;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can set the public tax.");
        _;
    }

    modifier onlyOneProducer(){
        require(producers[msg.sender].signedUp, "Only one producer can register a product.");
        _;
    }

    event publicTaxChanged(uint newPublicTax);

    function setPublicTax(uint num) public onlyAdmin{
        publicTax = num;
        emit publicTaxChanged(publicTax);
    }

    event producerRegistered(string producerName, address newProducer);

    function registerProducer(string memory producerName) public payable {
        require(tokenContract.getBalanceOf(msg.sender) >= publicTax, "Insufficient funds for registering a producer.");
        tokenContract.transferFrom(msg.sender, admin, publicTax);

        producers[msg.sender].signedUp = true;
        producers[msg.sender].name = producerName;
        producers[msg.sender].producerAddress = msg.sender;
        producers[msg.sender].registeredProducts = 0;

        // payable(msg.sender).transfer(publicTax);
        emit producerRegistered(producerName, msg.sender);
    }

    event productRegistered(address producer, string productName, uint productVolume);

    function registerProduct(string memory productName, uint productVolume) public onlyOneProducer{
        product memory newProduct = product(registeredProducts, true, productName, msg.sender, productVolume);
        
        // producers[msg.sender].products.push(newProduct);
        producers[msg.sender].registeredProducts++;
        products[registeredProducts] = newProduct;
        // products[registeredProducts].id = registeredProducts;
        registeredProducts++;

        brandExists[productName] = true;
        emit productRegistered(msg.sender, productName, productVolume);
    }

    function isProducerSignedUp(address producerAddress) public view returns (bool){
        return producers[producerAddress].signedUp;
    }

    function getProducerInfo(address producerAddress) public view returns (bool, string memory, address, uint){
        return (producers[producerAddress].signedUp,
        producers[producerAddress].name,
        producers[producerAddress].producerAddress,
        producers[producerAddress].registeredProducts);
    }

    function getInfoProductById(uint id) public view returns (uint, bool, string memory, address, uint){
        require(products[id].isRegistered, "Product not registered.");
        require(registeredProducts > id, "Index out of bounds.");
        return (products[id].id,
        products[id].isRegistered,
        products[id].name,
        products[id].producerAddress,
        products[id].volume);
    }

    function getTokens() public onlyAdmin{
        require(tokenContract.transfer(admin, tokenContract.getBalanceOf(admin)));
        payable(msg.sender).transfer(admin.balance);
    }

    function getBrand(string memory name) public view returns (bool){
        return brandExists[name];
    }
}