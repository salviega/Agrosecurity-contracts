// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

/**
 *  @title BIOrbit
 *
 *  NOTE: BIOrbit is a blockchain-based platform that enables monitoring and protection of Earth's natural resources
 *  through satellite imagery and community engagement. Users can contribute to the platform by donating to monitor
 *  protected areas and purchasing satellite images, ultimately fostering sustainable development and environmental conservation.
 *
 */

contract BIOrbit is ERC721, ERC721URIStorage {
	using Counters for Counters.Counter;

	Counters.Counter public projectIdCounter;

	/* Constants and immutable */

	uint256 public cost = 550000000000000; // This is equivalent to 0.00055 ETH = 1 USD
	uint256 public rentTime = 30 days;
	uint256 public fundsScience = 0;
	uint256 public fundsBIorbit = 0;

	/* Enumerables */

	enum State {
		Active,
		Monitor,
		Paused,
		Inactive
	}

	/* Struct */

	struct RentInfo {
		address renter;
		uint256 value;
		uint256 expiry;
	}

	struct Monitoring {
		// Monitoring
		string detectionDate;
		string forestCoverExtension;
	}

	struct ImageTimeSeries {
		// analysis of image time series
		string[] detectionDate;
		string[] forestCoverExtension;
	}

	struct Project {
		uint256 id;
		string uri;
		State state;
		string name;
		string description;
		string extension;
		string[][] footprint;
		string country;
		address owner;
		ImageTimeSeries imageTimeSeries;
		Monitoring[] monitoring;
		bool isRent;
		uint256 rentCost;
		RentInfo[] rentInfo;
	}

	struct ProjectLite {
		uint256 id;
		State state;
		string name;
		string description;
		string extension;
		string[][] footprint;
		string country;
		address owner;
		bool isRent;
		uint256 rentCost;
	}

	/* Storage */

	mapping(uint256 => Project) public Projects;

	/* Events */

	event ProjectCreated(
		uint256 id,
		State state,
		string name,
		string description,
		string extension,
		string[][] footprint,
		string country,
		address owner,
		bool isRent,
		uint256 rent
	);

	constructor() ERC721('BIOrbit', 'BIO') {}

	function mintProject(
		string memory _name,
		string memory _description,
		string memory _extension,
		string[][] memory _footprint,
		string memory _country,
		bool _isRent
	) external payable {
		uint256 projectId = _getNextProjectId();
		Project storage newProject = Projects[projectId];

		uint256 extension = parseDecimalStringToInt(_extension);
		uint256 monitoringCost = extension * cost;

		require(
			msg.value >= monitoringCost,
			'Insufficient payment, monitoringCost required'
		);

		fundsBIorbit += msg.value;

		uint256 rentCost = monitoringCost / 5;

		_setNewProjectData(
			newProject,
			projectId,
			State.Monitor,
			_name,
			_description,
			_extension,
			_footprint,
			_country,
			msg.sender,
			_isRent,
			rentCost
		);

		_safeMint(msg.sender, projectId);

		emit ProjectCreated(
			newProject.id,
			newProject.state,
			newProject.name,
			newProject.description,
			newProject.extension,
			newProject.footprint,
			newProject.country,
			newProject.owner,
			newProject.isRent,
			newProject.rentCost
		);
	}

	function rentProject(uint256 _projectId) external payable {
		Project storage project = Projects[_projectId];

		require(project.owner != msg.sender, "You can't rent your own project");
		require(project.state == State.Active, 'Project is not active');
		require(project.isRent, "Project isn't for rent");
		require(project.rentCost == msg.value, 'Rent price is incorrect');

		uint256 contractShare = project.rentCost / 5;
		uint256 ownerShare = msg.value - contractShare;
		payable(project.owner).transfer(ownerShare);

		fundsScience += contractShare;

		RentInfo memory newRentInfo = RentInfo({
			renter: msg.sender,
			value: project.rentCost,
			expiry: block.timestamp + rentTime
		});

		project.rentInfo.push(newRentInfo);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 _projectId
	) public override(ERC721, IERC721) {
		super.safeTransferFrom(from, to, _projectId);

		// Update the owner of the project
		Project storage project = Projects[_projectId];
		project.owner = to;
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 _projectId,
		bytes memory _data
	) public override(ERC721, IERC721) {
		super.safeTransferFrom(from, to, _projectId, _data);

		// Update the owner of the project
		Project storage project = Projects[_projectId];
		project.owner = to;
	}

	function transferFrom(
		address from,
		address to,
		uint256 _projectId
	) public override(ERC721, IERC721) {
		super.transferFrom(from, to, _projectId);

		// Update the owner of the project
		Project storage project = Projects[_projectId];
		project.owner = to;
	}

	function setTokenURI(
		string[] memory _detectionDate,
		string[] memory _forestCoverExtension,
		uint256 _projectId,
		string memory _projectURI
	) public {
		Project storage project = Projects[_projectId];

		if (project.state == State.Monitor) {
			_setTokenURI(_projectId, _projectURI);

			ImageTimeSeries memory imageTimeSeries = ImageTimeSeries(
				_detectionDate,
				_forestCoverExtension
			);
			project.imageTimeSeries = imageTimeSeries;
			project.state = State.Active;
			project.uri = _projectURI;
			return;
		}

		if (project.state == State.Active) {
			_setTokenURI(_projectId, _projectURI);

			Monitoring memory monitoring = Monitoring(
				_detectionDate[0],
				_forestCoverExtension[0]
			);

			project.monitoring.push(monitoring);
			project.uri = _projectURI;
		}
	}

	function tokenURI(
		uint256 _projectId
	) public view override(ERC721, ERC721URIStorage) returns (string memory) {
		Project memory project = Projects[_projectId];
		require(project.owner == msg.sender, 'Access denied');

		return super.tokenURI(_projectId);
	}

	function burnProject(uint256 _projectId) public {
		Project memory project = Projects[_projectId];
		require(project.owner == msg.sender, 'You can only burn your own projects');

		bool hasActiveRenters = false;

		for (uint256 i = 0; i < project.rentInfo.length; i++) {
			if (project.rentInfo[i].expiry > block.timestamp) {
				hasActiveRenters = true;
				uint256 rentAmount = project.rentInfo[i].value;
				payable(project.rentInfo[i].renter).transfer(rentAmount);
			}
		}

		if (!hasActiveRenters) {
			_burn(_projectId);
			delete Projects[project.id];
		}
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view override(ERC721, ERC721URIStorage) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	// ************************************ //
	// *        Getters & Setters         * //
	// ************************************ //

	function getProjects() public view returns (Project[] memory) {
		uint256 projectCount = projectIdCounter.current();
		Project[] memory projects = new Project[](projectCount);
		uint256 projectsCount = 0;

		for (uint256 i = 0; i <= projectCount; i++) {
			Project storage project = Projects[i];
			projects[projectsCount] = project;
			projectsCount++;
		}

		// Resize the array to remove any unused slots
		assembly {
			mstore(projects, projectsCount)
		}

		return projects;
	}

	function getProjectsByOwner() public view returns (Project[] memory) {
		uint256 projectCount = projectIdCounter.current();
		Project[] memory ownedProjects = new Project[](projectCount);
		uint256 ownedProjectsCount = 0;

		for (uint256 i = 1; i <= projectCount; i++) {
			Project storage project = Projects[i];
			if (project.owner == msg.sender) {
				ownedProjects[ownedProjectsCount] = project;
				ownedProjectsCount++;
			}
		}

		// Resize the array to remove any unused slots
		assembly {
			mstore(ownedProjects, ownedProjectsCount)
		}

		return ownedProjects;
	}

	function getActiveRentingProjects() public view returns (Project[] memory) {
		uint256 projectCount = projectIdCounter.current();
		Project[] memory activeRentingProjects = new Project[](projectCount);
		uint256 activeRentingProjectsCount = 0;

		for (uint256 i = 1; i <= projectCount; i++) {
			Project memory project = Projects[i];
			for (uint256 j = 0; j < project.rentInfo.length; j++) {
				if (
					project.rentInfo[j].renter == msg.sender &&
					project.rentInfo[j].expiry > block.timestamp
				) {
					activeRentingProjects[activeRentingProjectsCount] = project;
					activeRentingProjectsCount++;
					break;
				}
			}
		}

		// Resize the array to remove any unused slots
		assembly {
			mstore(activeRentingProjects, activeRentingProjectsCount)
		}

		return activeRentingProjects;
	}

	function getProjectsNotOwnedWithoutRent()
		public
		view
		returns (ProjectLite[] memory)
	{
		uint256 projectCount = projectIdCounter.current();
		ProjectLite[] memory notOwnedProjects = new ProjectLite[](projectCount);
		uint256 notOwnedProjectsCount = 0;

		for (uint256 i = 1; i <= projectCount; i++) {
			Project memory project = Projects[i];
			bool isOwned = project.owner == msg.sender;
			bool hasActiveRenters = false;

			for (uint256 j = 0; j < project.rentInfo.length; j++) {
				if (project.rentInfo[j].expiry > block.timestamp) {
					hasActiveRenters = true;
					break;
				}
			}

			if (!isOwned && !hasActiveRenters) {
				ProjectLite memory projectLite = ProjectLite({
					id: project.id,
					state: project.state,
					name: project.name,
					description: project.description,
					extension: project.extension,
					footprint: project.footprint,
					country: project.country,
					owner: project.owner,
					isRent: project.isRent,
					rentCost: project.rentCost
				});
				notOwnedProjects[notOwnedProjectsCount] = projectLite;
				notOwnedProjectsCount++;
			}
		}

		// Resize the array to remove any unused slots
		assembly {
			mstore(notOwnedProjects, notOwnedProjectsCount)
		}

		return notOwnedProjects;
	}

	function getDetectionDatesAndForestCoverExtensionsByProjectId(
		uint256 _projectId
	) public view returns (string[][] memory) {
		Project storage project = Projects[_projectId];
		require(project.owner == msg.sender, 'Access denied');

		string[][] memory detectionData = new string[][](2);
		detectionData[0] = project.imageTimeSeries.detectionDate;
		detectionData[1] = project.imageTimeSeries.forestCoverExtension;

		// Temporary arrays to store monitoring data
		string[] memory tempDetectionDates = new string[](
			project.monitoring.length
		);
		string[] memory tempForestCoverExtensions = new string[](
			project.monitoring.length
		);

		// Retrieve monitoring data
		for (uint256 i = 1; i < project.monitoring.length; i++) {
			tempDetectionDates[i] = project.monitoring[i].detectionDate;
			tempForestCoverExtensions[i] = project.monitoring[i].forestCoverExtension;
		}

		// Concatenate monitoring data with detectionData arrays
		detectionData[0] = concatenateArrays(detectionData[0], tempDetectionDates);
		detectionData[1] = concatenateArrays(
			detectionData[1],
			tempForestCoverExtensions
		);

		return detectionData;
	}

	function setName(uint256 _projectId, string memory _name) public {
		Project storage project = Projects[_projectId];
		require(project.owner == msg.sender, 'Access denied');

		project.name = _name;
	}

	function setDescription(
		uint256 _projectId,
		string memory _description
	) public {
		Project storage project = Projects[_projectId];
		require(project.owner == msg.sender, 'Access denied');

		project.description = _description;
	}

	function setIsRent(uint256 _projectId) public {
		Project storage project = Projects[_projectId];
		require(project.owner == msg.sender, 'Access denied');

		if (!project.isRent) {
			project.isRent = true;
			return;
		}

		project.isRent = false;
	}

	// ************************************ //
	// *        Helpers functions         * //
	// ************************************ //

	function concatenateArrays(
		string[] memory a,
		string[] memory b
	) private pure returns (string[] memory) {
		string[] memory result = new string[](a.length + b.length);
		uint256 i;
		for (i = 0; i < a.length; i++) {
			result[i] = a[i];
		}
		for (uint256 j = 0; j < b.length; j++) {
			result[i++] = b[j];
		}
		return result;
	}

	function parseDecimalStringToInt(
		string memory s
	) private pure returns (uint256) {
		bytes memory b = bytes(s);
		uint256 result;
		uint256 dec;
		bool hasDec;
		uint256 length = b.length;
		for (uint j = 0; j < length; j++) {
			if ((uint8(b[j]) >= 48) && (uint8(b[j]) <= 57)) {
				if (hasDec) {
					dec++;
					// Require that the number have only two decimals
					require(dec <= 2, 'Number must have at most 2 decimal places');
					result = result * 10 + (uint(uint8(b[j])) - 48);
				} else {
					result = result * 10 + (uint(uint8(b[j])) - 48);
				}
			} else if (uint8(b[j]) == 46) {
				require(!hasDec, 'More than one decimal point');
				hasDec = true;
			} else {
				revert('Invalid character');
			}
		}

		// Require that the number be greater than 1
		require(
			result > 100 || (result == 100 && dec > 0),
			'Number must be greater than 1'
		);

		// If it doesn't have decimals, convert it to integer
		if (!hasDec) {
			return result;
		}

		// Adjust the number according to the decimals
		if (dec < 2) {
			result *= 10 ** (2 - dec);
		}

		return result;
	}

	// *********************************** //
	// *        Private functions         * //
	// *********************************** //

	function _burn(
		uint256 _projectId
	) internal override(ERC721, ERC721URIStorage) {
		super._burn(_projectId);
	}

	function _getNextProjectId() private returns (uint256) {
		projectIdCounter.increment();
		uint256 projectId = projectIdCounter.current();
		return projectId;
	}

	function _setNewProjectData(
		Project storage _newProject,
		uint256 _id,
		State _state,
		string memory _name,
		string memory _description,
		string memory _extension,
		string[][] memory _footprint,
		string memory _country,
		address _owner,
		bool _isRent,
		uint256 _rentCost
	) private {
		_newProject.id = _id;
		_newProject.state = _state;
		_newProject.name = _name;
		_newProject.description = _description;
		_newProject.extension = _extension;
		_newProject.footprint = _footprint;
		_newProject.country = _country;
		_newProject.owner = _owner;
		_newProject.isRent = _isRent;
		_newProject.rentCost = _rentCost;
	}
}
