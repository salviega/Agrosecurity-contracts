// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 *  @title Agrosecurity
 *
 *  NOTE:
 *
 */

contract Agrosecurity {
	//

	/* Struct */

	struct Insurence {
		uint256 id;
		bool reedem;
		uint256 value;
		string coordinates;
		uint256 belowTemperatureThreshold;
		uint256 upperTemperatureThreshold;
		address owner;
	}

	/* Storage */

	mapping(uint256 => Insurence) public insurences;

	constructor() {}

	function createInsurence(
		uint256 _id,
		uint256 _belowTemperatureThreshold,
		uint256 _upperTemperatureThreshold
	) external payable {
		Insurence storage newInsurence = insurences[_id];

		newInsurence.id = _id;
		newInsurence.value = 0.001 ether;
		newInsurence.reedem = true;
		newInsurence.belowTemperatureThreshold = _belowTemperatureThreshold;
		newInsurence.upperTemperatureThreshold = _upperTemperatureThreshold;
		newInsurence.owner = msg.sender;

		require(newInsurence.value <= msg.value, 'Value is incorrect');

		insurences[_id] = newInsurence;
	}

	function reedemInsurence(uint256 _insurenceId) external payable {
		Insurence storage insurence = insurences[_insurenceId];

		require(
			insurence.owner == msg.sender,
			"You can't reedem your own insurences"
		);
		require(insurence.reedem, "Insurence isn't for reedem");

		(bool response /*byte data */, ) = insurence.owner.call{
			value: insurence.value
		}('');
		require(response, 'reverted');

		insurence.reedem = false;
	}

	function updateInsurence(uint256 _insurenceId) external payable {
		Insurence storage insurence = insurences[_insurenceId];

		require(
			insurence.owner == msg.sender,
			"You can't reedem your own insurences"
		);
		require(!insurence.reedem, "Insurence isn't for reedem");
		require(insurence.value <= msg.value, 'Value is incorrect');

		insurence.reedem = true;
	}
}
