# Tasks to be completed
- [ ] How to get signers from `signers.txt`.
==> add this signers in constructor
- [ ] Your task is to build a multisig smart contract. In order words, a contract that will only release Ethers after receiving **approval of the majority of voters. (more than 50%)**
- [x] Initialize state after contract creation
 `
   When this contract is initially created, it's in the state 
   "Accepting contributions". No proposals can be sent, no withdraw
   and no vote can be made while in this state. After this function
   is called, the contract state changes to "Active" in which it will
   not accept contributions anymore and will accept all other functions
   (submit proposal, vote, withdraw)
   
    function endContributionPeriod() external;
 `  
- [ ] end contribute can be called only by signers.txt 
- [x] Anyone can submit a proposal to withdraw some Ethers from the contract. In order to do so, all one needs to do is sending a transaction calling the function submitProposal with the requested value. **Value cannot be more than 10% of the total holdings of the contract.**
- [ ] reduce 10% from total holdings(maintain a local variable), it will be locked.
- [ ] if proposal is rejected, add the money back to this local variable.
- [x] Anyone can feed the contract with Ethers. The contract should hold the list of contributors and the amount that they sent to the contract.
- [ ] Voters vote on a given proposal by calling the function approve or reject depending on their preferences.
- [x] Pay close attention to the events that the contract should emit.
- [x] A beneficiary can submit only one proposal at a time
- [ ] contributor v/s voter (or signers) are they same or different.
- [x] who will deploy the contract
- [ ] how you can contribute directly without contribute function? (Anyone can contribute to the fund. This is just transfer of ethers/weis to the fund. The fund transfer does not need a function.)
- [ ] can you withdraw more then you contribute? Yes, no relation between contribution and withdrawal.
have a fallback function, then june 16 transferether
- [ ] anyone can contribute,
- [ ] anyone can submit (except signers) ?
- [ ] set wei as default unit
- [ ] set minimum contribution
