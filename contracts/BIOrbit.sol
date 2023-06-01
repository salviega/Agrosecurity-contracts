// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
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

contract BIOrbit is ERC721, ERC721URIStorage, AccessControl, ReentrancyGuard {
	using Counters for Counters.Counter;

	bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
	Counters.Counter public protectAreaIdCounter;

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
		IERC721 nft;
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

	mapping(uint256 => Project) Projects;

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

	constructor() ERC721('BIOrbit', 'BIO') {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(ADMIN_ROLE, msg.sender);
	}

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
		uint256 _tokenId,
		string memory _tokenURI
	) public onlyRole(ADMIN_ROLE) {
		Project storage project = Projects[_tokenId];

		if (project.state == State.Monitor) {
			_setTokenURI(_tokenId, _tokenURI);

			ImageTimeSeries memory imageTimeSeries = ImageTimeSeries(
				_detectionDate,
				_forestCoverExtension
			);
			project.imageTimeSeries = imageTimeSeries;
			project.state = State.Active;
			return;
		}

		if (project.state == State.Active) {
			Monitoring memory monitoring = Monitoring(
				_detectionDate[0],
				_forestCoverExtension[0]
			);
			project.monitoring.push(monitoring);
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
	)
		public
		view
		override(ERC721, ERC721URIStorage, AccessControl)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	// *********************************** //
	// *        Private functions         * //
	// *********************************** //

	function _getNextProjectId() private returns (uint256) {
		uint256 ProjectId = protectAreaIdCounter.current();
		protectAreaIdCounter.increment();
		return ProjectId;
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
}
