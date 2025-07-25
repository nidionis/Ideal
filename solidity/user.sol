// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FirmeSystem {

    struct ContactMethod {
        string methodType; // "email", "tel", "presentiel"
        string value;      // adresse email, numéro, ou lieu
        bool validatedByFirme; // si nécessaire
    }

    struct User {
        string name;
        address walletKey;            // Clé publique Ethereum principale
        address voteKey;              // Clé de vote (changeable)
        bytes32 individualCGUHash;    // hash du document CGU signé par l'utilisateur
        ContactMethod[2] contacts;    // deux moyens de contact
        uint256 maxResponseDelay;     // en secondes
        bool isIdentityValidated;     // par la firme
        bool isMemberValidated;       // par la firme
        address[] firmes;             // adresses des firmes associées
    }

    mapping(address => User) public users;

    // Exemple de création (par la firme)
    function registerUser(
        address userWallet,
        string memory name,
        address voteKey,
        bytes32 cguHash,
        ContactMethod[2] memory contacts,
        uint256 delaySeconds
    ) public {
        User storage u = users[userWallet];
        u.name = name;
        u.walletKey = userWallet;
        u.voteKey = voteKey;
        u.individualCGUHash = cguHash;
        u.contacts = contacts;
        u.maxResponseDelay = delaySeconds;
    }

    // Validation identité & adhésion par la firme
    function validateIdentity(address userAddr) public {
        users[userAddr].isIdentityValidated = true;
    }

    function validateMembership(address userAddr) public {
        users[userAddr].isMemberValidated = true;
    }

    function attachFirme(address userAddr, address firmeAddr) public {
        users[userAddr].firmes.push(firmeAddr);
    }

    function updateVoteKey(address newVoteKey) public {
        users[msg.sender].voteKey = newVoteKey;
    }

    // Lecture
    function getContacts(address userAddr) external view returns (ContactMethod[2] memory) {
        return users[userAddr].contacts;
    }
}

