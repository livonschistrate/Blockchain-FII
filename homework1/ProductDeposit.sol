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

    product[] public products;
    mapping(address => store) stores;

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
        require(currentVolume <= maxVolume, "Maximum volume of deposit is reached.");
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
        
        require(msg.sender == producerAddress, "Producer not authorized to deposit the selected product.");
        require(msg.value >= publicTax * units, "Insufficient funds for registering products.");
        require(currentVolume + units <= maxVolume, "Cannot add more units as it overcomes the maximum volume.");

        products.push(productToDeposit);
        currentVolume += units;
        payable(msg.sender).transfer(msg.value - publicTax * units);
        admin.transfer(publicTax * units);
        emit depositProductRegistered(msg.sender, productToDeposit, units);
    }

    event storeAuthorized(address producer, address storeAddress, string name);

    function registerStore(string memory name, address storeAddress) public onlyOneProducer{
        store memory newShop;
        newShop.isRegistered = true;
        newShop.name = name;
        newShop.producerAddress = msg.sender;
        newShop.storeAddress = storeAddress;

        stores[msg.sender] = newShop;
        emit storeAuthorized(msg.sender, storeAddress, name);
    }

    event productsDeleted(address producer);

    function addToDeposit(uint productId, uint units) public payable onlyOneProducer{
        require((msg.sender == products[productId].producerAddress)  || stores[msg.sender].isRegistered,
         "Producer is not authorized to add units to the product.");
        require(products[productId].depositQuantity + units <= maxVolume, "Too many units to add.");
        require(products.length > productId, "Index out of bounds.");
        require(msg.value >= publicTax * units, "Insufficient funds for adding products.");
        for(uint i = 0; i < products.length; i++){   
            if(keccak256(abi.encodePacked(products[i].name)) == keccak256(abi.encodePacked(products[productId].name))
            && products[i].value == products[productId].value){
                products[i].depositQuantity += units;
                currentVolume += units;
                break;
            }
        }
        payable(msg.sender).transfer(msg.value - publicTax * units);
        admin.transfer(publicTax * units);
    }

    function withdrawFromDeposit(uint productId, uint units) public onlyOneProducer returns (bool){
        require((msg.sender == products[productId].producerAddress) || stores[msg.sender].isRegistered,
         "Producer is not authorized to delete the product.");
        require(products[productId].depositQuantity >= units, "Too many units to withdraw.");
        require(products.length > productId, "Index out of bounds.");
        for(uint i = 0; i < products.length; i++){   
            if(keccak256(abi.encodePacked(products[i].name)) == keccak256(abi.encodePacked(products[productId].name))
            && products[i].value == products[productId].value){
                products[i].depositQuantity -= units;
                currentVolume -= units;
                break;
            }
        }
        emit productsDeleted(msg.sender);
        return true;
    }

    function getProductById(uint id) external view returns (string memory, address, uint, uint, uint){
        require(products[id].isRegistered, "Product not registered or not existent in store.");
        require(products.length > id, "Index out of bounds.");
        return (products[id].name, products[id].producerAddress, products[id].value,
        products[id].depositQuantity, products[id].shopQuantity);
    }
}