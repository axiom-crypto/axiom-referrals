// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { AxiomV2Client } from "@axiom-crypto/v2-periphery/client/AxiomV2Client.sol";

contract AxiomReferral is AxiomV2Client {
    /// @dev The unique identifier of the circuit accepted by this contract.
    bytes32 immutable QUERY_SCHEMA;

    /// @dev `referralAddress[referee] = referrer` if `referrer` referred `referee`.
    mapping(address => address) public referralAddress;

    /// @dev `lastClaimedId[referrer]` is the latest `claimId` at which `referrer` claimed a referral reward.
    /// @dev `claimId` = `blockNumber` * 2^128 + `txIdx` * 2^64 + `logIdx`
    mapping(address => uint256) public lastClaimedId;

    /// @notice Emitted when a new referral is registered.
    /// @param referee The address of the referee.
    /// @param referrer The address of the referrer.
    /// @param blockNumber The block number at which the referral was registered.
    event Referral(address indexed referee, address indexed referrer, uint64 blockNumber);

    /// @notice Emitted when a claim is made.
    /// @param referrer The address of the referrer.
    /// @param startClaimId The ID of the first claim in the claim batch.
    /// @param endClaimId The ID of the last claim in the claim batch.
    /// @param claimAmount The total amount of the claim batch.
    event Claim(address indexed referrer, uint256 startClaimId, uint256 endClaimId, uint256 claimAmount);

    /// @notice Construct a new AxiomReferral contract.
    /// @param  _axiomV2QueryAddress The address of the AxiomV2Query contract.
    constructor(address _axiomV2QueryAddress, bytes32 _querySchema) AxiomV2Client(_axiomV2QueryAddress) {
        QUERY_SCHEMA = _querySchema;
    }

    /// @notice Set the referring address for a referee
    /// @param  referrer The address of the referrer
    function setReferrer(address referrer) external {
        require(referralAddress[msg.sender] == address(0), "Referrer already set");
        referralAddress[msg.sender] = referrer;
        emit Referral(msg.sender, referrer, uint64(block.number));
    }

    /// @inheritdoc AxiomV2Client
    function _validateAxiomV2Call(
        AxiomCallbackType, // callbackType,
        uint64 sourceChainId,
        address, // caller,
        bytes32 querySchema,
        uint256, // queryId,
        bytes calldata // extraData
    ) internal view override {
        require(sourceChainId == block.chainid, "Source chain ID does not match");
        require(querySchema == QUERY_SCHEMA, "Invalid query schema");
    }

    /// @inheritdoc AxiomV2Client
    function _axiomV2Callback(
        uint64, // sourceChainId,
        address, // caller,
        bytes32, // querySchema,
        uint256, // queryId,
        bytes32[] calldata axiomResults,
        bytes calldata // extraData
    ) internal override {
        uint256 startClaimId = uint256(axiomResults[0]);
        uint256 endClaimId = uint256(axiomResults[1]);
        address referrer = address(uint160(uint256(axiomResults[2])));
        uint256 claimAmount = uint256(axiomResults[3]);

        require(referrer != address(0), "Referrer not set");
        require(lastClaimedId[referrer] < startClaimId, "Already claimed");

        lastClaimedId[referrer] = endClaimId;

        emit Claim(referrer, startClaimId, endClaimId, claimAmount);
    }
}
