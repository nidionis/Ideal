// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FirmeVote {

    struct VoteRecord {
        bytes32 hashedVote;     // hash(pubVoteKey + password + prefs)
        bool acknowledged;      // accusé de réception
        bool revealed;          // le vote a été révélé
        string preferences;     // format texte standardisé (JSON, CSV, etc.)
        bool invalidated;       // corrompu → opposition
        address pubVoteKey;     // clé de vote publique fournie pour invalidation
    }

    struct Proposal {
        string title;
        string votingMethod;    // description/verbatim du scrutin (STV, Condorcet, etc.)
        string context;         // peut contenir "modification CGU", "intégration", etc.
        mapping(address => VoteRecord) votes;
        address[] voters;
        bool resultApplied;     // a été appliqué après 2nd tour
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    address public immutable firme;

    constructor(address _firme) {
        firme = _firme;
    }

    // ========== Création d'un vote ==========

    function createProposal(
        string memory title,
        string memory votingMethod,
        string memory context,
        address[] memory voters
    ) public returns (uint256) {
        require(msg.sender == firme, "Seule la firme peut proposer");

        uint256 pid = nextProposalId++;
        Proposal storage p = proposals[pid];
        p.title = title;
        p.votingMethod = votingMethod;
        p.context = context;

        for (uint i = 0; i < voters.length; i++) {
            p.voters.push(voters[i]);
        }

        return pid;
    }

    // ========== Vote initial ==========

    function submitVote(uint256 pid, bytes32 hashedVote) public {
        Proposal storage p = proposals[pid];
        require(!_hasVoted(pid, msg.sender), "Deja vote");
        p.votes[msg.sender].hashedVote = hashedVote;
    }

    function acknowledgeReceipt(uint256 pid) public {
        require(proposals[pid].votes[msg.sender].hashedVote != 0, "Vote non trouve");
        proposals[pid].votes[msg.sender].acknowledged = true;
    }

    // ========== Dévoilement du vote (1er tour) ==========

    function revealVote(
        uint256 pid,
        string memory preferences,
        string memory password,
        address pubVoteKey
    ) public {
        VoteRecord storage vr = proposals[pid].votes[msg.sender];
        require(vr.hashedVote != 0, "Pas de vote");
        require(!vr.revealed, "Deja revele");

        // Recalcul hash
        bytes32 recalculated = keccak256(abi.encodePacked(pubVoteKey, password, preferences));
        require(recalculated == vr.hashedVote, "Hash invalide");

        vr.preferences = preferences;
        vr.revealed = true;
    }

    // ========== Invalidation du vote (opposition) ==========

    function invalidateVote(
        uint256 pid,
        address pubVoteKey,
        string memory password,
        string memory preferences
    ) public {
        VoteRecord storage vr = proposals[pid].votes[msg.sender];
        require(vr.hashedVote != 0, "Vote non trouve");
        require(!vr.invalidated, "Deja invalide");

        bytes32 recalculated = keccak256(abi.encodePacked(pubVoteKey, password, preferences));
        require(recalculated == vr.hashedVote, "Hash non valide");
        vr.invalidated = true;
        vr.pubVoteKey = pubVoteKey;
    }

    // ========== Marquage du résultat comme appliqué ==========

    function markResultApplied(uint256 pid) public {
        require(msg.sender == firme, "Seule la firme peut valider l'application");
        proposals[pid].resultApplied = true;
    }

    // ========== Vue pour calcul externe ==========

    struct StandardizedVote {
        address voter;
        bool acknowledged;
        bool revealed;
        bool invalidated;
        string preferences;
    }

    function getVotes(uint256 pid) public view returns (StandardizedVote[] memory) {
        Proposal storage p = proposals[pid];
        StandardizedVote[] memory results = new StandardizedVote[](p.voters.length);

        for (uint i = 0; i < p.voters.length; i++) {
            address voter = p.voters[i];
            VoteRecord storage vr = p.votes[voter];

            results[i] = StandardizedVote({
                voter: voter,
                acknowledged: vr.acknowledged,
                revealed: vr.revealed,
                invalidated: vr.invalidated,
                preferences: vr.preferences
            });
        }

        return results;
    }

    // ========== Internes ==========

    function _hasVoted(uint256 pid, address user) internal view returns (bool) {
        return proposals[pid].votes[user].hashedVote != 0;
    }
}

