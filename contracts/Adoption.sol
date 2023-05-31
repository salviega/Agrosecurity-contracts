pragma solidity ^0.7.6;
pragma abicoder v2;
// pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Adoption {
    struct PetStruct {
        uint256 keyExists;
        uint256 listIndex;
        string name;
        address adopter;
    }
    mapping(string => PetStruct) public petsMap;
    string[] public petsList;

    function getPetListLength() public view returns (uint256 petCount) {
        return petsList.length;
    }

    function isPetExists(string memory petName) public view returns (bool) {
        // check if non-zero value in struct is zero
        // if it is zero then you know that myMapping[key] doesn't yet exist
        if (petsMap[petName].keyExists != 0) {
            return true;
        }
        return false;
    }

    event APetAdded(string petName);

    function addNewPet(string memory petName) public returns (bool success) {
        console.log("get in: add new pet function");

        if (isPetExists(petName)) return false;

        petsMap[petName].keyExists = 1;
        petsList.push(petName);
        petsMap[petName].listIndex = petsList.length - 1;
        petsMap[petName].name = petName;

        emit APetAdded(petName);
        console.log("emit APetAdded: petName =", petName);

        return true;
    }

    function updatePet(string memory petName, address adopterAddress)
        public
        returns (bool success)
    {
        if (!isPetExists(petName)) return false;

        petsMap[petName].adopter = adopterAddress;

        emit APetAdded(petName);

        return true;
    }

    function deletePet(string memory petName) public returns (bool success) {
        if (!isPetExists(petName)) return false;

        uint256 indexToDelete = petsMap[petName].listIndex;
        string memory elementToMove = petsList[petsList.length - 1];
        petsList[indexToDelete] = elementToMove;
        petsMap[elementToMove].listIndex = indexToDelete;
        petsList.pop();
        // petsList.length--;

        emit APetAdded(petName);

        return true;
    }

    event APetGetAdopted(address indexed owner);

    function adopt(string memory petName) public returns (string memory) {
        // require(petId >= 0 && petId <= 15);

        updatePet(petName, msg.sender);

        emit APetGetAdopted(msg.sender);

        return petName;
    }

    function getAdopters() public view returns (PetStruct[] memory) {
        PetStruct[] memory tempList = new PetStruct[](petsList.length);
        for (uint256 i = 0; i < petsList.length; i++) {
            tempList[i] = petsMap[petsList[i]];
        }
        return tempList;
    }
}
