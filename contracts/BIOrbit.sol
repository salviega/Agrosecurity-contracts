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

	/* Enumerables */

	enum State {
		Active,
		Monitor,
		Paused,
		Inactive
	}

	/* Struct */

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
		address owner
	);

	constructor() ERC721('BIOrbit', 'BIO') {}

	function mintProject(
		string memory _name,
		string memory _description,
		string memory _extension,
		string[][] memory _footprint,
		string memory _country
	) external payable {
		uint256 projectId = _getNextProjectId();
		Project storage newProject = Projects[projectId];

		State state = State.Monitor;

		_setNewProjectData(
			newProject,
			projectId,
			state,
			_name,
			_description,
			_extension,
			_footprint,
			_country,
			msg.sender
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
			newProject.owner
		);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override(ERC721, IERC721) {
		super.safeTransferFrom(from, to, tokenId);

		// Update the owner of the project
		Project storage project = Projects[tokenId];
		project.owner = to;
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public override(ERC721, IERC721) {
		super.safeTransferFrom(from, to, tokenId, _data);

		// Update the owner of the project
		Project storage project = Projects[tokenId];
		project.owner = to;
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override(ERC721, IERC721) {
		super.transferFrom(from, to, tokenId);

		// Update the owner of the project
		Project storage project = Projects[tokenId];
		project.owner = to;
	}

	function setTokenURI(
		string[] memory _detectionDate,
		string[] memory _forestCoverExtension,
		uint256 _projectId,
		string memory _tokenURI
	) public {
		Project storage project = Projects[_projectId];

		if (project.state == State.Monitor) {
			_setTokenURI(_projectId, _tokenURI);

			ImageTimeSeries memory imageTimeSeries = ImageTimeSeries(
				_detectionDate,
				_forestCoverExtension
			);
			project.imageTimeSeries = imageTimeSeries;
			project.state = State.Active;
			project.uri = _tokenURI;
			return;
		}

		if (project.state == State.Active) {
			Monitoring memory monitoring = Monitoring(
				_detectionDate[0],
				_forestCoverExtension[0]
			);
			project.monitoring.push(monitoring);
			project.uri = _tokenURI;
			return;
		}
	}

	function tokenURI(
		uint256 tokenId
	) public view override(ERC721, ERC721URIStorage) returns (string memory) {
		return super.tokenURI(tokenId);
	}

	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view override(ERC721, ERC721URIStorage) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	// *********************************** //
	// *        Private functions         * //
	// *********************************** //

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
		address _owner
	) private {
		_newProject.id = _id;
		_newProject.state = _state;
		_newProject.name = _name;
		_newProject.description = _description;
		_newProject.extension = _extension;
		_newProject.footprint = _footprint;
		_newProject.country = _country;
		_newProject.owner = _owner;
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
}
