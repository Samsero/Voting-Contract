// SPDX-License-Identifier:  GPL-3.0

pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    /**  
     * @dev Structure de donnée représentant un Votant
    */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /**  
     * @dev Structure de donnée représentant une proposition
    */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /**  
     * @dev Décalaration d’une énumération "WorkflowStatus" qui définit six états du vote : 
     RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded, 
     VotingSessionStarted, VotingSessionEnded, VotesTallied 
    */
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }


    event VoterRegistered(address voterAddress); // événement enregistrement d'un votant par l'administrateur du vote
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus); /// événement relatif à l'état précédent et à l'état actuel du vote
    event ProposalRegistered(uint proposalId); // événement enregistrement d'une proposition 
    event Voted (address voter, uint proposalId);  //événement une personne a voté

    
    WorkflowStatus public currentWorkflowStatus;
 
    address public admin;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    address[] public votersAddresses;  //newly added

    // Permet de donner accès aux fonctions selon l'état du vote
    modifier validWorkflowStatus(WorkflowStatus requestedWorkflowStatus){
        require(currentWorkflowStatus == requestedWorkflowStatus, unicode"Cette requête ne correspond pas à la phase en cours");
        _;
    }

    // Permet de donner accès aux personnes enregistrées pour le vote seulement
    modifier onlyRegisteredVoters() {
            require(voters[msg.sender].isRegistered == true, unicode"Vous n'êtes pas enregistré en tant qu'électeur.");
            _;
    }

    /**
    Cette partie du code qui s'excute une seule fois lors du déploiement du contrat 
    permet d'initialiser les variables admin et currentWorkflowStatus 
    ainsi que la valeur isRegistered relative à l'instance administrateur
    */
    constructor() {
        admin = msg.sender;
        voters[admin].isRegistered = true; // Si on considère que l'administrateur a le droit de voter aussi
        currentWorkflowStatus = WorkflowStatus.RegisteringVoters;

    }

    /**
    * @dev Permet à l'administrateur de passer à l'état suivant du vote
    * @param x nouvel état du vote
    */
    function changeWorkflowStatus(uint8  x) public onlyOwner {
        require (WorkflowStatus(x) > currentWorkflowStatus, unicode"On ne peut pas retourner à l'étape précédente" );
        require (WorkflowStatus(x) <= WorkflowStatus.VotesTallied && WorkflowStatus(x) >= WorkflowStatus.RegisteringVoters, "Cette session n'existe pas." );
         /* autre alternative
        emit WorkflowStatusChange(currentWorkflowStatus, x);
        currentWorkflowStatus = x;
        */
        WorkflowStatus previousStatus = currentWorkflowStatus;
        currentWorkflowStatus = WorkflowStatus(x);
        emit WorkflowStatusChange(previousStatus, currentWorkflowStatus);
       
    }


    /** 
    * @dev permet d'enregistrer des votants
    * @param voter adresse du votant
    */
    function addVoter(address voter) public onlyOwner validWorkflowStatus(WorkflowStatus.RegisteringVoters) {
        require(!voters[voter].hasVoted, unicode"Cette personne a déjà voté.");
        require(voters[voter].isRegistered == false, unicode"Cette personne figure déjà dans liste des électeurs.");
        votersAddresses.push(voter); //newly added
        voters[voter].isRegistered = true;
        emit VoterRegistered(voter); 
    }

    /**
    * @dev permet à chaque personne enregsitré d'ajouter une proposition
    * @param submittedProposal description de la proposition
    */
    function addProposal(string memory submittedProposal)  public onlyRegisteredVoters validWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted){
                proposals.push(Proposal({
                    description: submittedProposal,
                    voteCount: 0
                }));
                emit ProposalRegistered(proposals.length-1);     
    }


    /**
    * @dev permet aux personnes enregistées de voter pour leur proposition préférée
    * @param proposalId l'Id de la proposition
    */
    function toVote(uint proposalId) public onlyRegisteredVoters validWorkflowStatus(WorkflowStatus.VotingSessionStarted) {
        Voter storage sender  = voters[msg.sender];
        require(!sender.hasVoted, unicode"Cette personne a déjà voté.");
        require(proposalId < proposals.length && proposalId >= 0, "Cette proposition n'existe pas.");
        sender.hasVoted = true;
        sender.votedProposalId = proposalId;
        proposals[proposalId].voteCount ++;
        emit Voted(msg.sender, proposalId);
    }

    /**
    * @dev permet de retourner la proposition gagnante (son Id, son nom et le nombre de votes)
    */
    function getWinner() public view onlyRegisteredVoters validWorkflowStatus(WorkflowStatus.VotesTallied) returns (uint winningProposalId, string memory winningProposalName, uint numberOfVotes) {
        uint higherVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > higherVoteCount) {
                higherVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        winningProposalName = proposals[winningProposalId].description;
        numberOfVotes = proposals[winningProposalId].voteCount;
    }
    
}