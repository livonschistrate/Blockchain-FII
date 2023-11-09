// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import "./ProductStore.sol";
import "./ProductIdentification.sol";

contract ProductDeposit{
    struct product{
        bool isRegistered;
        string name;
        address producerAddress;
        uint value;
        uint depositQuantity;
        uint shopQuantity;
        store store;
    }

    struct store{
        bool isRegistered;
        string name;
        address producerAddress;
        address storeAddress;
    }

    address payable public admin;
    uint public publicTax;
    uint public maxVolume;
    uint public currentVolume;

    ProductIdentification public contractIdentification;
    ProductStore public contractStore;

    product[] public products;
    store[] public stores;
    mapping(address => store) public registeredStores;

    constructor(uint newTax, uint newVolume, address newContractIdentAddress){
        admin = payable(msg.sender);
        publicTax = newTax;
        maxVolume = newVolume;
        currentVolume = 0;
        contractIdentification = ProductIdentification(newContractIdentAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can set the public tax.");
        _;
    }

    modifier maxVolumeReached(){
        require(products.length == maxVolume, "Maximum volume of deposit is reached.");
        _;
    }

    modifier onlyOneProducer(){
        require(contractIdentification.isProducerSignedUp(msg.sender), "Only one authorized producer can register a product.");
        _;
    }

    event publicTaxChanged(uint newTax);

    function setPublicTax(uint num) public onlyAdmin{
        publicTax = num;
        emit publicTaxChanged(publicTax);
    }

    event maxDepositChanged(uint newMax);

    function setMaxDepositVolume(uint num) public onlyAdmin{
        maxVolume = num;
        emit maxDepositChanged(maxVolume);
    }

    event depositProductRegistered(address producer, product productToDeposit, uint units);

    function registerDepositProduct(uint productId, uint units) payable public onlyOneProducer maxVolumeReached{
        (bool isProductRegistered, string memory productName,
         address producerAddress, uint value) = contractIdentification.getInfoProductById(productId);
        product memory productToDeposit; // = product(isProductRegistered, productName, producerAddress, value, units);
        productToDeposit.isRegistered = isProductRegistered;
        productToDeposit.name = productName;
        productToDeposit.producerAddress = producerAddress;
        productToDeposit.value = value;
        productToDeposit.depositQuantity = units;
        
        require(msg.value >= publicTax * units, "Insufficient funds for registering products.");
        require(currentVolume + units <= maxVolume, "Cannot add more units as it overcomes the maximum volume.");

        products.push(productToDeposit);
        currentVolume += units;
        payable(msg.sender).transfer(msg.value - publicTax * units);
        admin.transfer(publicTax * units);
        emit depositProductRegistered(msg.sender, productToDeposit, units);
    }

    event storeAuthorized(address producer, address store, string name, uint productId);

    function registerStore(string memory name, address contractStoreAddress, uint productId) public onlyOneProducer{
        store memory newShop;
        newShop.isRegistered = true;
        newShop.name = name;
        newShop.producerAddress = msg.sender;
        newShop.storeAddress = contractStoreAddress;
        products[productId].store = newShop;
        products[productId].shopQuantity = 0;
        stores.push(newShop);
        emit storeAuthorized(msg.sender, contractStoreAddress, name, productId);
    }

    event productsDeleted(address producer);

    function deleteProduct(uint indexToDelete) private {
        for(uint j = indexToDelete; j < products.length - 1; j++)
            products[j] = products[j+1];
        products.pop();
    }

    function deleteFromDeposit(uint productId, uint units) public onlyOneProducer returns (bool){
        require((msg.sender == products[productId].producerAddress) || (msg.sender == products[productId].store.storeAddress),
         "Producer is not authorized to delete the product.");
        require(products[productId].depositQuantity < units, "Too many units to delete.");
        for(uint i = 0; i < products.length; i++){   
            if(keccak256(abi.encodePacked(products[i].name)) == keccak256(abi.encodePacked(products[productId].name))
            && products[i].value == products[productId].value){
                products[i].depositQuantity -= units;
                currentVolume -= units;
                if(products[i].depositQuantity == 0) 
                    deleteProduct(productId);
                break;
            }
        }
        emit productsDeleted(msg.sender);
        return true;
    }

    function getProductById(uint id) public view returns (string memory, address, uint, uint, uint){
        require(products[id].isRegistered, "Product not registered or not existent in store.");
        return (products[id].name, products[id].producerAddress, products[id].value,
        products[id].depositQuantity, products[id].shopQuantity);
    }
}