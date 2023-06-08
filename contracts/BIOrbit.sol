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

interface DataFeedsInterface {
	function getLatestData() external view returns (int);
}

contract BIOrbit is ERC721, ERC721URIStorage {
	using Counters for Counters.Counter;

	Counters.Counter public projectIdCounter;

	/* Constants and immutable */

	address dataFeedsAddress;
	uint256 public rentTime = 30 days;

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
		bytes32 name;
		bytes32 description;
		bytes32 extension;
		string[][] footprint;
		bytes32 country;
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
		bytes32 name;
		bytes32 description;
		bytes32 extension;
		string[][] footprint;
		bytes32 country;
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
		bytes32 name,
		bytes32 description,
		bytes32 extension,
		string[][] footprint,
		bytes32 country,
		address owner,
		bool isRent,
		uint256 rent
	);

	constructor(address _dataFeedsAddress) ERC721('BIOrbit', 'BIO') {
		dataFeedsAddress = _dataFeedsAddress;
	}

	function mintProject(
		bytes32 _name,
		bytes32 _description,
		bytes32 _extension,
		string[][] memory _footprint,
		bytes32 _country,
		bool _isRent
	) external payable {
		projectIdCounter.increment();
		uint256 projectId = projectIdCounter.current();

		Project storage newProject = Projects[projectId];

		uint256 rentCost = msg.value / 10;

		newProject.id = projectId;
		newProject.state = State.Monitor;
		newProject.name = _name;
		newProject.description = _description;
		newProject.extension = _extension;
		newProject.footprint = _footprint;
		newProject.country = _country;
		newProject.owner = msg.sender;
		newProject.isRent = _isRent;
		newProject.rentCost = rentCost;

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

		RentInfo memory newRentInfo = RentInfo({
			renter: msg.sender,
			expiry: block.timestamp + rentTime
		});

		project.rentInfo.push(newRentInfo);

		payable(project.owner).transfer(msg.value);
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

		if (project.state == State.Active) {
			_setTokenURI(_projectId, _projectURI);

			Monitoring memory monitoring = Monitoring(
				_detectionDate[0],
				_forestCoverExtension[0]
			);

			project.monitoring.push(monitoring);
			project.uri = _projectURI;
		}

		if (project.state == State.Monitor) {
			_setTokenURI(_projectId, _projectURI);

			ImageTimeSeries memory imageTimeSeries = ImageTimeSeries(
				_detectionDate,
				_forestCoverExtension
			);
			project.imageTimeSeries = imageTimeSeries;
			project.state = State.Active;
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
				uint256 rentAmount = project.rentCost;
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

	function getProjectsByOwner() public view returns (Project[] memory) {
		uint256 projectCount = projectIdCounter.current();

		if (projectCount == 0) {
			return new Project[](0);
		}

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

		if (projectCount == 0) {
			return new Project[](0);
		}

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

		if (projectCount == 0) {
			return new ProjectLite[](0);
		}

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

	function getLatestData() public view returns (uint256) {
		return uint256(DataFeedsInterface(dataFeedsAddress).getLatestData());
	}

	function setName(uint256 _projectId, bytes32 _name) public {
		Project storage project = Projects[_projectId];
		require(project.owner == msg.sender, 'Access denied');

		project.name = _name;
	}

	function setDescription(uint256 _projectId, bytes32 _description) public {
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

	function setRentCost(uint256 _projectId) public payable {
		Project storage project = Projects[_projectId];
		require(project.owner == msg.sender, 'Access denied');

		project.rentCost = getLatestData();
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

	// *********************************** //
	// *        Private functions         * //
	// *********************************** //

	function _burn(
		uint256 _projectId
	) internal override(ERC721, ERC721URIStorage) {
		super._burn(_projectId);
	}
}
