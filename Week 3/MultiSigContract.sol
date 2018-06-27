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
    event WithdrawRejected(address indexed beneficiary, uint _value);

    // for testing state variable
    //event CheckState(string _str);

    enum ProposalState {
        AcceptingContributions,
        Active
    }

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
    mapping(address => uint) private getProposalValue;
    mapping(address => bool) private submitted;

    address public contractOwner;
    address[] private listOfContributors;
    mapping(address => bool) public signersList;
    uint private signerCount = 0;

    uint public totalContribution = 0;
    uint public minimumContribution = 0; //in Weis
    //uint private WEI_TO_ETHER=1000000000000000000;

    ProposalState public state;
    mapping(address => SubmittedProposal) private proposals;

    // 100,["0xdfb782fbf761c0094de25cc6c21bbb9fd272aad5","0x922326d0fac731b422f811a9551686f621190d5a","0x51bdf0e78b29859cc15d8d1699666b34772afb49"]
    constructor () public {
        require(msg.value > 0,"Contribution should be greater than 0 wei !!!");
        contractOwner = msg.sender;

        minimumContribution = msg.value;
        state = ProposalState.AcceptingContributions;

        signersList[0xdfb782fbf761c0094de25cc6c21bbb9fd272aad5] = true; signerCount = signerCount.add(1);
        signersList[0x922326d0fac731b422f811a9551686f621190d5a] = true; signerCount = signerCount.add(1);
        signersList[0x51bdf0e78b29859cc15d8d1699666b34772afb49] = true; signerCount = signerCount.add(1);

        //my test in remix to be removed
        signersList[0xdd870fa1b7c4700f2bd7f44238821c26f7392148] = true; signerCount = signerCount.add(1);
        signersList[0xf3a8894f73e055511bfeeba6f8313693a0d7d108] = true; signerCount = signerCount.add(1);
        signersList[0xe7d081c76dea36b1f087924d8404c2c840b44789] = true; signerCount = signerCount.add(1);

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

   1. contract should have some ether ebfore calling endContributionPeriod
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

   TODO:
   1. handle multiple proposal by same submitter
   2. reduce _value from totalContribution -- DONE
   */
   function submitProposal(uint _value) external isNotASigner inState(ProposalState.Active) {
     require(_value <= totalContribution.div(10),"Value cannot be more than 10% of the total holdings of the contract!!!");
    //   require(_value <= getContractBalance().div(10),"Value cannot be more than 10% of the total holdings of the contract!!!");
       require(!submitted[msg.sender], "Beneficiary is allowed only one proposal at a time!!!");

       SubmittedProposal memory newProposal = SubmittedProposal({
           submitter: msg.sender,
           amountRequested: _value,
           approvalCount: 0,
           rejectionCount: 0
        });

        proposals[msg.sender] = newProposal;
        getProposalValue[msg.sender] = _value;
        submitted[msg.sender] = true;
        totalContribution = totalContribution.sub(_value);

        emit ProposalSubmitted(msg.sender, _value);
   }

function getCompleteProposal(address _beneficiary) public view returns (address,int,int,int) {
    SubmittedProposal memory tempProposal = proposals[_beneficiary];
    return (
      tempProposal.submitter,
      tempProposal.amountRequested,
      tempProposal.approvalCount,
      tempProposal.rejectionCount
      );
}
  /*
   * Returns the value requested by the given beneficiary in his proposal.
   */
  function getBeneficiaryProposal(address _beneficiary) external view returns (uint) {
      return getProposalValue[_beneficiary];
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
   1. if you have approved, you cannot reject same proposal. --DONE
   2. you can approve only once -- DONE
   */
  function approve(address _beneficiary) external isSigner inState(ProposalState.Active) {
    SubmittedProposal storage aProposal = proposals[_beneficiary];

    require(aProposal.rejections[msg.sender],"You cannot approve as you have already rejected this proposal!!!");
    require(!aProposal.approvals[msg.sender],"You can approve only once!!!");

    uint value = getProposalValue[_beneficiary];
    aProposal.approvalCount = aProposal.approvalCount.add(1);
    aProposal.approvals[msg.sender] = true;

    emit ProposalApproved(msg.sender, _beneficiary, value);
  }

  /*
   * Reject the proposal of the given beneficiary
   1. if you have rejected, you cannot approve same proposal.
   2. you can reject only once --DONE
   */
  function reject(address _beneficiary) external isSigner inState(ProposalState.Active) {
    SubmittedProposal storage rProposal = proposals[_beneficiary];

    require(rProposal.approvals[msg.sender],"You cannot reject as you have already approved this proposal!!!");
    require(!rProposal.rejections[msg.sender],"You can reject only once!!!");

    uint value = getProposalValue[_beneficiary];
    rProposal.rejectionCount = rProposal.rejectionCount.add(1);
    rProposal.rejections[msg.sender] = true;

    emit ProposalRejected(msg.sender, _beneficiary, value);
  }

  /*
   * Returns a list of beneficiaries for the open proposals. Open
   * proposal is the one in which the majority of voters have not
   * voted yet.
   */
  //function listOpenBeneficiariesProposals() external view returns (address[]);


  /*
   * Withdraw the specified value from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
   * should be sent.
   *
   */
  function withdraw(uint _value) external isContributor inState(ProposalState.Active) {
    // get proposal from msg.sender
    SubmittedProposal storage withdrawProposal = proposals[msg.sender];
    uint proposedValue = getProposalValue[msg.sender];

    //Minimum 50% contributors should approve!!!
    if(withdrawProposal.approvalCount > signerCount.div(2)) {
      // requested _value should be less than or equal to proposed value
      if(_value <= proposedValue) {
          msg.sender.transfer(_value);
      }

      emit WithdrawPerformed(msg.sender, _value);
    } else if(withdrawProposal.rejectionCount > signerCount.div(2)) {
      // Minimum 50% contributors rejected,
      // hence adding the value back to totalContribution
      totalContribution = totalContribution.add(_value);
      emit WithdrawRejected(msg.sender, _value);
    }
  }

  function getContractBalance() public view returns(uint){
      return address(this).balance;
  }

  function owner() public view returns (address) {
    return contractOwner;
  }
}
