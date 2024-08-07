// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SampleToken {
    
    string public name = "Sample Token";
    string public symbol = "TOK";
    uint8 public decimals = 16;

    uint256 public totalSupply;
    
    event Transfer(address indexed _from,
                   address indexed _to,
                   uint256 _value);

    event Approval(address indexed _owner,
                   address indexed _spender,
                   uint256 _value);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function getTotalSupply() public view returns (uint256){
        return totalSupply;
    }

    function getBalanceOf(address owner) public view returns (uint256){
        return balanceOf[owner];
    }
    
    function getAllowance(address owner, address spender) public view returns (uint256){
        return allowance[owner][spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "The user doesn't have enough tokens to transfer");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "The user doesn't have enough tokens to transfer");
        require(_value <= allowance[_from][msg.sender], "The user doesn't have enough allowances");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract SampleTokenSale {
    
    SampleToken public tokenContract;
    uint256 public tokenPrice;
    address owner;

    uint256 public tokensSold;

    event Sell(address indexed _buyer, uint256 indexed _amount);

    constructor(SampleToken _tokenContract, uint256 _tokenPrice) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function setTokenPrice(uint256 newPrice) public {
        require(owner == msg.sender, "Only the owner of the contract can change the token price.");
        tokenPrice = newPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(_numberOfTokens > 0, "There must be a number of tokens to pay.");
        require(msg.value >= _numberOfTokens * tokenPrice, "Insufficient funds for paying tokens.");
        require(tokenContract.getAllowance(owner, address(this)) >= _numberOfTokens, "Insufficient allowances.");
        require(tokenContract.transferFrom(owner, msg.sender, _numberOfTokens), "Transfer failed.");

        tokensSold += _numberOfTokens;
        payable(msg.sender).transfer(msg.value -  _numberOfTokens * tokenPrice);

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == owner);
        require(tokenContract.transfer(owner, tokenContract.getBalanceOf(address(this))));
        payable(msg.sender).transfer(address(this).balance);
    }
}