pragma solidity ^0.4.24;

contract Quote_Registry {
    mapping(string => address) quoteRegistry;
    address public contractOwner;
    
    constructor() public {
        contractOwner = msg.sender;       
    }
    
    function register(string _quote) public {
        require(ownership(_quote) == address(0),"Quote already registered!!!");
    
        quoteRegistry[_quote] = msg.sender;
    
    }

    function ownership(string _quote) public view returns (address) {
        return quoteRegistry[_quote];
    }

    function transfer(string _quote, address _newOwner) public payable {
        address _oldOwner = ownership(_quote);
        
        require(msg.sender == _oldOwner, "You are not a owner of this quote..");
        
        require(_oldOwner != _newOwner, "New owner is already owner of this quote..");
        
        require(msg.value == 0.5 ether,"Fee of 0.5 ether to be paid for transfer of ownership");
        
   
        quoteRegistry[_quote] = _newOwner;
        
        _oldOwner.transfer(msg.value);
    }

    function owner() public view returns (address) {
        return contractOwner;
    }
    
    function checkBalance(address _addr) public view returns(uint) {
        return _addr.balance;
    }
}
