// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FirmeDenierSystem {

    uint8 public constant MAX_RATIO = 6;

    struct Denier {
        address firm;
        uint256 timeSpent; // en minutes
        uint8 ratio;
        address validator1;
        address validator2;
        bool validated;
    }

    struct Firme {
        string name;
        address[] members;
        mapping(address => mapping(address => uint8)) ratios; // ratios entre pairs
        uint256 revenueWei; // chiffre d'affaire en wei
        bytes32 contractHash; // hash CGU
        bytes32 authMethodHash; // méthode d’authentification définie par la firme
        uint256[] deniers; // index des deniers associés
    }

    mapping(address => Firme) public firmes;
    Denier[] public deniers;

    // =========== Firme Management ===========

    function createFirme(
        address firmAddr,
        string memory name,
        bytes32 contractHash,
        bytes32 authMethodHash
    ) public {
        Firme storage f = firmes[firmAddr];
        f.name = name;
        f.contractHash = contractHash;
        f.authMethodHash = authMethodHash;
    }

    function addMember(address firmAddr, address user) public {
        firmes[firmAddr].members.push(user);
    }

    function setRatio(address firmAddr, address from, address to, uint8 ratio) public {
        require(ratio <= MAX_RATIO, "Ratio too high");
        firmes[firmAddr].ratios[from][to] = ratio;
        require(_checkTotalRatios(firmAddr, from), "Total ratio exceeds MAX_RATIO");
    }

    function _checkTotalRatios(address firmAddr, address user) internal view returns (bool) {
        uint8 sum = 0;
        for (uint i = 0; i < firmes[firmAddr].members.length; i++) {
            sum += firmes[firmAddr].ratios[user][firmes[firmAddr].members[i]];
        }
        return sum <= MAX_RATIO;
    }

    // =========== Deniers ===========

    function submitDenier(
        address firm,
        uint256 timeSpent,
        uint8 ratio,
        address validator1,
        address validator2
    ) public returns (uint256) {
        require(ratio >= 1 && ratio <= MAX_RATIO, "Invalid ratio");
        require(validator1 != validator2, "Validators must differ");

        deniers.push(Denier({
            firm: firm,
            timeSpent: timeSpent,
            ratio: ratio,
            validator1: validator1,
            validator2: validator2,
            validated: false
        }));

        uint256 id = deniers.length - 1;
        firmes[firm].deniers.push(id);
        return id;
    }

    function validateDenier(uint256 id, address sender) public {
        Denier storage d = deniers[id];
        require(!d.validated, "Already validated");
        require(sender == d.validator1 || sender == d.validator2, "Not a validator");
        if (sender == d.validator1) {
            d.validator1 = address(0);
        } else {
            d.validator2 = address(0);
        }
        if (d.validator1 == address(0) && d.validator2 == address(0)) {
            d.validated = true;
        }
    }

    // =========== View Functions ===========

    function getFirmeMembers(address firmAddr) external view returns (address[] memory) {
        return firmes[firmAddr].members;
    }

    function getUserRatio(address firmAddr, address from, address to) external view returns (uint8) {
        return firmes[firmAddr].ratios[from][to];
    }

    function getDenier(uint256 id) external view returns (Denier memory) {
        return deniers[id];
    }
}

