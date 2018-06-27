/*
1. contract creation and deployed
2. contribute to any given proposal
3. endContribution for any given proposal
4. submitProposal for withdrawal
5. Approve or Reject the proposal
6. Withdraw the proposed value

Signers
---------------------
0xdfb782fbf761c0094de25cc6c21bbb9fd272aad5
0x922326d0fac731b422f811a9551686f621190d5a
0x51bdf0e78b29859cc15d8d1699666b34772afb49
*/

pragma solidity ^0.4.20;

/*
In real code use it like this
npm install -E zeppelin-solidity
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
*/
//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface AbstractMultiSig {

  /*
   * This event should be dispatched whenever the contract receives
   * any contribution (Ethers).
   */
  event ReceivedContribution(address indexed _contributor, uint valueInWei);
  
  /*
   * When this contract is initially created, it's in the state 
   * "Accepting contributions". No proposals can be sent, no withdraw
   * and no vote can be made while in this state. After this function
   * is called, the contract state changes to "Active" in which it will
   * not accept contributions anymore and will accept all other functions
   * (submit proposal, vote, withdraw)
   */
  function endContributionPeriod() external;

  /*
   * Sends a withdraw proposal to the contract. The beneficiary would
   * be "_beneficiary" and if approved, this address will be able to
   * withdraw "value" Ethers.
   *
   * This contract should be able to handle many proposals at once.
   */
  function submitProposal(uint _value) external;
  event ProposalSubmitted(address indexed _beneficiary, uint _value);

  /*
   * Returns a list of beneficiaries for the open proposals. Open
   * proposal is the one in which the majority of voters have not
   * voted yet.
   */
  function listOpenBeneficiariesProposals() external view returns (address[]);

  /*
   * Returns the value requested by the given beneficiary in his proposal.
   */
  function getBeneficiaryProposal(address _beneficiary) external view returns (uint);

  /*
   * List the addresses of the contributors, which are people that sent
   * Ether to this contract.
   */
  function listContributors() external view returns (address[]);

  /*
   * Returns the amount sent by the given contributor.
   */
  function getContributorAmount(address _contributor) external view returns (uint);

  /*
   * Approve the proposal for the given beneficiary
   */
  function approve(address _beneficiary) external;
  event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _value);

  /*
   * Reject the proposal of the given beneficiary
   */
  function reject(address _beneficiary) external;
  event ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _value);

  /*
   * Withdraw the specified value from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
   * should be sent.
   *
   */
  function withdraw(uint _value) external;
  event WithdrawPerformed(address indexed beneficiary, uint _value);

}

//contract MultiSig is AbstractMultiSig {
contract MultiSig {
    using SafeMath for uint256;

    /*
    * This event should be dispatched whenever the contract receives
    * any contribution (Ethers).
    */
    event ReceivedContribution(address indexed _contributor, uint valueInWei);
    
    event ProposalSubmitted(address indexed _beneficiary, uint _value);
    event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _value);
    event ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _value);
    event WithdrawPerformed(address indexed beneficiary, uint _value);
    
    // for testing state variable 
    event CheckState(string _str);
    
    enum ProposalState {
        AcceptingContributions,
        Active
    }
    
    /*
    enum ProposalState {
        AcceptingContributions,
        Active,
        Submitted, 
        Approved,
        Rejected,
        CompletelyWithdrawn,
        PartiallyWithdrawn
    }
    */
    
    struct SubmittedProposal {
        address submitter;
        uint amountRequested;
        uint approvalCount;
        uint rejectionCount;
        mapping(address => bool) approvals;
        mapping(address => bool) rejections;
    }
    
    // Initializing all contract variables
    mapping(address => uint) private contributions;
    mapping(address => bool) private contributors;
    mapping(address => uint) private getProposal;
    mapping(address => bool) private submitted;
    
    address public manager;
    address[] private listOfContributors;
    mapping(address => bool) public signersList;
    
    uint public totalContribution = 0;
    uint public minimumContribution = 0; //in Weis
    //uint private WEI_TO_ETHER=1000000000000000000;
    
    ProposalState public state;
    mapping(address => SubmittedProposal) private proposals;
    
    // 100,["0xdfb782fbf761c0094de25cc6c21bbb9fd272aad5","0x922326d0fac731b422f811a9551686f621190d5a","0x51bdf0e78b29859cc15d8d1699666b34772afb49"]
    
    constructor () public {
        require(msg.value > 0,"Contribution should be greater than 0 wei !!!");
        manager = msg.sender;
        
        minimumContribution = msg.value;
        state = ProposalState.AcceptingContributions;
        
        signersList[0xdfb782fbf761c0094de25cc6c21bbb9fd272aad5] = true;
        signersList[0x922326d0fac731b422f811a9551686f621190d5a] = true;
        signersList[0x51bdf0e78b29859cc15d8d1699666b34772afb49] = true;
        
        //my test to be removed
        signersList[0xdd870fa1b7c4700f2bd7f44238821c26f7392148] = true;
        signersList[0xf3a8894f73e055511bfeeba6f8313693a0d7d108] = true;
        signersList[0xe7d081c76dea36b1f087924d8404c2c840b44789] = true;        
        
        //emit CheckState("AcceptingContributions");
    }
    
    modifier isSigner() {
        require(signersList[msg.sender],"You are not a signer!!!")
        _;
    }
    
    modifier isNotASigner() {
        require(!signersList[msg.sender],"Signer cannot submit a proposal!!!")
        _;
    }
    
    modifier isContributor() {
        require(contributors[msg.sender],"You are not a contributor!!!");
        _;    
    }
    
/*
    modifier isContributorOrSigner() {
        require(contributors[msg.sender] || signersList[msg.sender],"Only contributor or a signer can call this function!!!");
        _;    
    }
*/    
    modifier inState(ProposalState _state) {
        require(state == _state, "Please check the required state for this activity!!!");
        _;
    }
    
    
    // fallback function to receive contribution in weis
    function () inState(ProposalState.AcceptingContributions) public payable {
        //check if we can have require in fallback fucntion
        require(msg.value >= minimumContribution,"Minimum Contribution should be greater than 0 wei !!!");
        
        //Add contributor and its contribution to the mapping
        //contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        
        if(!contributors[msg.sender]) {
            contributors[msg.sender] = true; //Add contributor to the list
            listOfContributors.push(msg.sender); // Add contributor to the listOfContributors
        }
        
        totalContribution = totalContribution.add(msg.value); // total contribution from all signers
        
        emit ReceivedContribution(msg.sender, msg.value); //Send event after receiving contribution
    }

  /*
   * When this contract is initially created, it's in the state 
   * "Accepting contributions". No proposals can be sent, no withdraw
   * and no vote can be made while in this state. After this function
   * is called, the contract state changes to "Active" in which it will
   * not accept contributions anymore and will accept all other functions
   * (submit proposal, vote, withdraw)
   */
   
  function endContributionPeriod() external isSigner inState(ProposalState.AcceptingContributions) {
      state = ProposalState.Active;
      //emit CheckState("Active");
  }
  
   /*
   * Sends a withdraw proposal to the contract. The beneficiary would
   * be "_beneficiary" and if approved, this address will be able to
   * withdraw "value" Ethers.
   *
   * This contract should be able to handle many proposals at once.
   */
   function submitProposal(uint _value) external isNotASigner inState(ProposalState.Active) {
       require(_value <= getContractBalance().div(10),"Value cannot be more than 10% of the total holdings of the contract!!!");
       require(!submitted[msg.sender], "Beneficiary is allowed only one proposal at a time!!!");
       
       SubmittedProposal memory newProposal = SubmittedProposal({
           submitter: msg.sender,
           amountRequested: _value,
           approvalCount: 0,
           rejectionCount: 0
        });
        
        proposals[msg.sender] = newProposal;
        
        getProposal[msg.sender] = _value;
        submitted[msg.sender] = true;
        
        emit ProposalSubmitted(msg.sender, _value);
   }
   
  /* 
   * Returns the value requested by the given beneficiary in his proposal.
   */
  function getBeneficiaryProposal(address _beneficiary) external view returns (uint) {
      return getProposal[_beneficiary];
  }

  /*
   * List the addresses of the contributors, which are people that sent
   * Ether to this contract.
   */
  function listContributors() external view returns (address[]) {
      return listOfContributors;
  }

  /*
   * Returns the amount sent by the given contributor.
   */
  function getContributorAmount(address _contributor) external view returns (uint) {
      return contributions[_contributor];
  }

  /*
   * Approve the proposal for the given beneficiary
   */
  function approve(address _beneficiary) external isSigner {
    require(!proposal.approvals[msg.sender],"You can approve only once!!!");
    
    uint _value = getProposal[_beneficiary];
    SubmittedProposal storage proposal = proposals[_beneficiary];
      
    proposal.approvalCount = proposal.approvalCount.add(1);
    proposal.approvals[msg.sender] = true;
      
    emit ProposalApproved(msg.sender, _beneficiary, _value);
  }


  /*
   * Reject the proposal of the given beneficiary
   */
  //function reject(address _beneficiary) external isContributor;
  //emit ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _value);
  
  function reject(address _beneficiary) external isSigner {
    require(!proposal.rejections[msg.sender],"You can reject only once!!!");
    
    uint _value = getProposal[_beneficiary];
    SubmittedProposal storage proposal = proposals[_beneficiary];

    proposal.rejectionCount = proposal.rejectionCount.add(1);
    proposal.rejections[msg.sender] = true;
      
    emit ProposalRejected(msg.sender, _beneficiary, _value);
  }

  /*
   * Returns a list of beneficiaries for the open proposals. Open
   * proposal is the one in which the majority of voters have not
   * voted yet.
   */
  //function listOpenBeneficiariesProposals() external view isContributor returns (address[]);
  
  
  /*
   * Withdraw the specified value from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
    isContributor* should be sent.
   *
   */
  //function withdraw(uint _value) external isContributor;
  //emit WithdrawPerformed(address indexed beneficiary, uint _value);
  
  function getContractBalance() public view isContributor returns(uint){
      return address(this).balance;
  }
}
