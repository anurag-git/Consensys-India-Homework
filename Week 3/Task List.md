# Tasks to be completed
- [ ] How to get signers from `signers.txt`.
- [ ] Initialze state after contract creation
 `
   When this contract is initially created, it's in the state 
   "Accepting contributions". No proposals can be sent, no withdraw
   and no vote can be made while in this state. After this function
   is called, the contract state changes to "Active" in which it will
   not accept contributions anymore and will accept all other functions
   (submit proposal, vote, withdraw)
   
    function endContributionPeriod() external;
 `  
- [ ] Anyone can submit a proposal to withdraw some Ethers from the contract. In order to do so, all one needs to do is sending a transaction calling the function submitProposal with the requested value. Value cannot be more than 10% of the total holdings of the contract.
- [ ] - [ ] - [ ] Anyone can feed the contract with Ethers. The contract should hold the list of contributors and the amount that they sent to the contract.
- [ ] - [ ] Voters vote on a given proposal by calling the function approve or reject depending on their preferences.
- [ ] Pay close attention to the events that the contract should emit.
