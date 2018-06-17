pragma solidity ^0.4.17;

contract Quote_Registry {
    mapping(string => address) quoteRegistry;
    address public contractOwner;
    
    function Quote_Registry() public {
        contractOwner = msg.sender;       
    }
    
    function register(string _quote) public {
        quoteRegistry[_quote] = msg.sender;
    }

    function ownership(string _quote) public view returns (address) {
        return quoteRegistry[_quote];
    }

    function transfer(string _quote, address _newOwner) public payable {
        require(msg.value == 0.5 ether,"Fee of 0.5 ether to be paid for transfer of ownership");
        
        address _oldOwner = quoteRegistry[_quote];
        quoteRegistry[_quote] = _newOwner;
        _oldOwner.transfer(msg.value);
        
    }

    function owner() public view returns (address) {
        return contractOwner;
    }
}
