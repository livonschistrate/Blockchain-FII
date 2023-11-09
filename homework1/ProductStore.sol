// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import "./ProductDeposit.sol";
import "./ProductIdentification.sol";

contract ProductStore{
    struct product{
        bool isRegistered;
        string name;
        address producerAddress;
        uint value;
        uint depositQuantity;
        uint shopQuantity;
        // store store;
    }

    // struct producer{
    //     string name;
    //     address producerAddress;
    //     product[] products;
    // }

    // struct store{
    //     bool isRegistered;
    //     string name;
    //     address storeAddress;
    //     product[] products;
    // }

    address payable public admin;
    ProductDeposit public contractDeposit;
    ProductIdentification public contractIdentification;
    // store[] stores;
    product[] products;

    constructor(address newContractIdentAddress, address newContractDepositAddress){
        admin = payable(msg.sender);
        contractDeposit = ProductDeposit(newContractIdentAddress);
        contractIdentification = ProductIdentification(newContractDepositAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can set the public tax.");
        _;
    }

    modifier onlyOneProducer(){
        require(contractIdentification.isProducerSignedUp(msg.sender), "Only one authorized producer can register a product.");
        _;
    }

    function setContractDeposit(ProductDeposit newDeposit) public{
        contractDeposit = newDeposit;
    }

    function setContractIdentification(ProductIdentification newIdentification) public{
        contractIdentification = newIdentification;
    }

    event storeRegistered(string name, address contractStoreAddress);

    // function registerStore(string memory name, address contractStoreAddress) public onlyAdmin{
    //     store memory newShop;
    //     newShop.isRegistered = true;
    //     newShop.name = name;
    //     newShop.storeAddress = contractStoreAddress;
    //     stores.push(newShop);
    //     emit storeRegistered(name, contractStoreAddress);
    // }

    // function getStore(uint id) public returns (bool, string memory, address){
    //     return (stores[id].isRegistered, stores[id].name, stores[id].storeAddress);
    // }

    function addNewProductInStore(uint productId, uint units) public onlyAdmin{
        product memory newProduct;
        (string memory productName, address producerAddress, uint value,
         uint depositQuantity, uint shopQuantity) = contractDeposit.getProductById(productId);

        require(contractDeposit.deleteFromDeposit(productId, units), "Product cannot be withdrawn from deposit.");
        newProduct.name = productName;
        newProduct.producerAddress = producerAddress;
        newProduct.value = value; 
        newProduct.depositQuantity = depositQuantity - units;
        newProduct.shopQuantity = shopQuantity + units;

        products.push(newProduct);
    }

    function setPriceValue(uint productId, uint newValue) public onlyAdmin{
        products[productId].value = newValue;
    }

    function isProductAvailable(uint productId) public view returns (uint){
        require(products[productId].shopQuantity > 0, "The product is currently not in the store.");
        return products[productId].shopQuantity;
    }

    function purchaseProduct(uint productId, uint units) public payable{
        require(isProductAvailable(productId) > 0, "The product is currently not available in the store.");
        require(isProductAvailable(productId) < units, "There are too few units for this product.");
        // (string memory productName, address producerAddress, int value,
        //  uint depositQuantity, uint shopQuantity) = contractDeposit.getProductById(productId);
        
        uint totalPrice = products[productId].value * units;
        require(msg.value >= totalPrice, "Insufficient funds for product payment.");
        products[productId].shopQuantity -= units;
        
        payable(msg.sender).transfer(msg.value - totalPrice);
        payable(products[productId].producerAddress).transfer(totalPrice / 2);
    }

}