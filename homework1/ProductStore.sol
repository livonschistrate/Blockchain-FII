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
    }

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

    event contractDepositAdded(address newDeposit);

    function setContractDeposit(address newDepositAddress) public onlyAdmin{
        contractDeposit = ProductDeposit(newDepositAddress);
        emit contractDepositAdded(newDepositAddress);
    }

    event contractIdentificationAdded(address newIdentAddress);

    function setContractIdentification(address newIdentAddress) public onlyAdmin{
        contractIdentification = ProductIdentification(newIdentAddress);
        emit contractIdentificationAdded(newIdentAddress);
    }

    event newProductAdded(product newProduct, uint units);

    function addNewProductInStore(uint productId, uint units) public onlyOneProducer{
        product memory newProduct;
        (string memory productName, address producerAddress, uint value,
         uint depositQuantity, uint shopQuantity) = contractDeposit.getProductById(productId);

        require(contractDeposit.withdrawFromDeposit(productId, units), "Product cannot be withdrawn from deposit.");
        newProduct.name = productName;
        newProduct.producerAddress = producerAddress;
        newProduct.value = value; 
        newProduct.depositQuantity = depositQuantity - units;
        newProduct.shopQuantity = shopQuantity + units;

        products.push(newProduct);
        emit newProductAdded(newProduct, units);
    }

    event priceValueUpdated(product thatProduct, uint newValue);

    function setPriceValue(uint productId, uint newValue) public onlyAdmin{
        products[productId].value = newValue;
        emit priceValueUpdated(products[productId], newValue);
    }

    event productQuantityAvailable(product thatProduct);

    function isProductAvailable(uint productId) public returns (uint){
        require(products[productId].shopQuantity > 0, "The product is currently not in the store.");
        emit productQuantityAvailable(products[productId]);
        return products[productId].shopQuantity;
    }

    event productPurchased(product thatProduct, uint units);

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
        emit productPurchased(products[productId], units);
    }

}