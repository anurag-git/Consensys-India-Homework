/*
1. contract creation and deployed
2. contribute to any given proposal
3. endContribution for any given proposal
4. submitProposal for withdrawal
5. Approve or Reject the proposal
6. Withdraw the proposed value

Signers
---------------------
0xfa3c6a1d480a14c546f12cdbb6d1bacbf02a1610
0x2f47343208d8db38a64f49d7384ce70367fc98c0
0x7c0e7b2418141f492653c6bf9ced144c338ba740
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
   * This function should return the onwer of this contract or whoever you
   * want to receive the Gyaan Tokens reward if it's coded correctly.
   */

  function owner() external returns(address);

  /*
   * This event should be dispatched whenever the contract receives
   * any contribution (Ethers).
   */
   event ReceivedContribution(address indexed _contributor, uint _valueInWei);

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
  event ProposalSubmitted(address indexed _beneficiary, uint _valueInWei);

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
  event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

  /*
   * Reject the proposal of the given beneficiary
   */
  function reject(address _beneficiary) external;
  event ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _valueInWei);

  /*
   * Withdraw the specified value from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
   * should be sent.
   *
   */
  function withdraw(uint _value) external;
  event WithdrawPerformed(address indexed beneficiary, uint _valueInWei);

}

//contract MultiSig is AbstractMultiSig {
contract MultiSig {
    using SafeMath for uint256;

    /*
    * This event should be dispatched whenever the contract receives
    * any contribution (Ethers).
    */
    event ReceivedContribution(address indexed _contributor, uint _valueInWei);

    event ProposalSubmitted(address indexed _beneficiary, uint _valueInWei);
    event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _valueInWei);
    event ProposalRejected(address indexed _approver, address indexed _beneficiary, uint _valueInWei);
    event WithdrawPerformed(address indexed beneficiary, uint _valueInWei);

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
    mapping(address => bool) private submitters;
    mapping(address => bool) private signersList;
    mapping(address => bool) private withdrawals;
    mapping(address => SubmittedProposal) private proposals;


    // Address variables
    address private contractOwner;
    address[] private listOfContributors;
    address[] private openBeneficiaries;

    // Integer variables
    uint public signerCount = 0;
    uint public totalContribution = 0; //in Weis
    ProposalState public state;

    constructor () public {
        contractOwner = msg.sender;
        state = ProposalState.AcceptingContributions;

        signersList[address(0x00fa3c6a1d480a14c546f12cdbb6d1bacbf02a1610)] = true; signerCount = signerCount.add(1);
        signersList[address(0x002f47343208d8db38a64f49d7384ce70367fc98c0)] = true; signerCount = signerCount.add(1);
        signersList[address(0x007c0e7b2418141f492653c6bf9ced144c338ba740)] = true; signerCount = signerCount.add(1);

/*
        //my test in remix to be removed
        signersList[address(0x00dd870fa1b7c4700f2bd7f44238821c26f7392148)] = true; signerCount = signerCount.add(1);
        signersList[address(0x00583031d1113ad414f02576bd6afabfb302140225)] = true; signerCount = signerCount.add(1);
        signersList[address(0x004b0897b0513fdc7c541b6d9d7e929c4e5364d2db)] = true; signerCount = signerCount.add(1);
*/
    }

    modifier isSigner() {
        require(signersList[msg.sender],"You are not a signer!!!");
        _;
    }

    modifier isNotASigner() {
        require(!signersList[msg.sender],"Signer not allowed to perform this operation!!!");
        _;
    }

    modifier isContributor() {
        require(contributors[msg.sender],"You are not a contributor!!!");
        _;
    }

    modifier inState(ProposalState _state) {
        require(state == _state, "Please check the required state for this activity!!!");
        _;
    }

    // fallback function to receive contribution in weis
    function () inState(ProposalState.AcceptingContributions) public payable {
        //check if we can have require in fallback fucntion
        require(msg.value > 0,"Minimum Contribution should be greater than 0 wei !!!");

        //Add contributor and its contribution to the mapping
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

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

   1. contract should have some ether before calling endContributionPeriod
   */
  function endContributionPeriod() external isSigner inState(ProposalState.AcceptingContributions) {
      require(totalContribution > 0, "Not enough ethers in contract, fund contract before ending contribution period!!!");

      state = ProposalState.Active;
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
        require(_value <= totalContribution.div(2),"Value cannot be more than 10% of the total holdings of the contract!!!");
        //require(_value <= totalContribution.div(10),"Value cannot be more than 10% of the total holdings of the contract!!!");
        require(!submitters[msg.sender], "Beneficiary is allowed only one proposal at a time!!!");

        SubmittedProposal memory newProposal = SubmittedProposal({
           submitter: msg.sender,
           amountRequested: _value,
           approvalCount: 0,
           rejectionCount: 0
        });

        openBeneficiaries.push(msg.sender);

        proposals[msg.sender] = newProposal;
        getProposalValue[msg.sender] = _value;
        submitters[msg.sender] = true;
        totalContribution = totalContribution.sub(_value);

        emit ProposalSubmitted(msg.sender, _value);
   }

   function getCompleteProposal(address _beneficiary) public view returns (address,uint,uint,uint) {
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
    require(submitters[_beneficiary],"No proposal submitted for this beneficiary!!!");

    SubmittedProposal storage aProposal = proposals[_beneficiary];

    require(!aProposal.rejections[msg.sender],"You cannot approve as you have already rejected this proposal!!!");
    require(!aProposal.approvals[msg.sender],"You can approve only once!!!");

    uint value = getProposalValue[_beneficiary];
    aProposal.approvalCount = aProposal.approvalCount.add(1);
    aProposal.approvals[msg.sender] = true;

    if( aProposal.approvalCount.mul(100) >= signerCount.mul(100).div(2) ) {
        removeByValue(_beneficiary);
    }

    emit ProposalApproved(msg.sender, _beneficiary, value);
  }

  /*
   * Reject the proposal of the given beneficiary
   1. if you have rejected, you cannot approve same proposal.
   2. you can reject only once --DONE
   */
  function reject(address _beneficiary) external isSigner inState(ProposalState.Active) {
    require(submitters[_beneficiary],"No proposal submitted for this beneficiary!!!");

    SubmittedProposal storage rProposal = proposals[_beneficiary];

    require(!rProposal.approvals[msg.sender],"You cannot reject as you have already approved this proposal!!!");
    require(!rProposal.rejections[msg.sender],"You can reject only once!!!");

    uint value = getProposalValue[_beneficiary];
    rProposal.rejectionCount = rProposal.rejectionCount.add(1);
    rProposal.rejections[msg.sender] = true;

    if( rProposal.rejectionCount.mul(100) >= signerCount.mul(100).div(2) ) {
        removeByValue(_beneficiary);
    }

    emit ProposalRejected(msg.sender, _beneficiary, value);
  }

  /*
   * Returns a list of beneficiaries for the open proposals. Open
   * proposal is the one in which the majority of voters have not
   * voted yet.
   */
  function listOpenBeneficiariesProposals() external view returns (address[]) {
      // means beneficiary whose proposal is neither approved nor rejected by majority(50%)
         return openBeneficiaries;
  }


  /*
   * Withdraw the specified value from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
   * should be sent.
   *
   TODO:
   1.handle multiple withdrawals
   2. you cannot withdraw without submitting proposal -- DONE
   */
  function withdraw(uint _value) external isNotASigner inState(ProposalState.Active) payable {
    require(submitters[msg.sender],"No proposal submitted for this beneficiary!!!");
    // get proposal from msg.sender
    SubmittedProposal storage withdrawProposal = proposals[msg.sender];
    require(!withdrawals[msg.sender],"Withdrawals allowed only once!!!");

//    require(withdrawProposal.approvals[msg.sender] || withdrawProposal.rejections[msg.sender],
//        "Proposal neither approved nor rejected!!!");

    uint proposedValue = getProposalValue[msg.sender];

    // Minimum 50% signers should approve!!! and
    // requested _value should be less than or equal to proposed value
    if(withdrawProposal.approvalCount >= signerCount.div(2)) {
        if(_value == proposedValue) {
            msg.sender.transfer(_value); // contract balance will decrease
            withdrawals[msg.sender] = true;
            emit WithdrawPerformed(msg.sender, _value);
        } else if(_value < proposedValue) {
            msg.sender.transfer(_value);
            uint residualValue = proposedValue.sub(_value);
            totalContribution = totalContribution.add(residualValue); // add unused value to totalContribution
            //address(this).transfer(residualValue); // transfer back unused value to contract
            //getProposalValue[msg.sender] = residualValue;
            withdrawals[msg.sender] = true;
            emit WithdrawPerformed(msg.sender, _value);
        } else if(_value > proposedValue) {
            totalContribution = totalContribution.add(proposedValue); // add back unused value to totalContribution
            withdrawals[msg.sender] = true;
            revert("Requested more than proposed value, Submit a new Proposal!!!");
        }
    }

    // Minimum 50% signers should reject
    if(withdrawProposal.rejectionCount >= signerCount.div(2)) {
      totalContribution = totalContribution.add(proposedValue); // add back unused/rejected value to totalContribution
      withdrawals[msg.sender] = true;
    }

    // if approval and rejection counts are equal
    if(withdrawProposal.approvalCount == withdrawProposal.rejectionCount) {
        withdrawals[msg.sender] = true;
        totalContribution = totalContribution.add(proposedValue); // add back unused/rejected value to totalContribution
        revert("No Majority hence withdraw cancelled!!!");
    }
  }

  function getContractBalance() public view returns(uint){
      return address(this).balance;
  }

  function getBalance() public view returns(uint){
      return address(msg.sender).balance;
  }

  function owner() public view returns (address) {
    return contractOwner;
  }

  // functions for listOpenBeneficiariesProposals
  function find(address _addr) private view returns(uint) {
        uint i = 0;
        while (openBeneficiaries[i] != _addr) {
            i++;
        }
        return i;
    }

    function removeByIndex(uint i) private {
        while (i<openBeneficiaries.length-1) {
            openBeneficiaries[i] = openBeneficiaries[i+1];
            i++;
        }
        openBeneficiaries.length--;
    }

    function removeByValue(address _addr) private {
        uint i = find(_addr);
        removeByIndex(i);
    }
    // functions for listOpenBeneficiariesProposals
}
