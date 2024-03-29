// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { AxiomIncentives } from "@axiom-crypto/axiom-incentives/AxiomIncentives.sol";

contract AxiomReferral is AxiomIncentives {
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
    /// @param  incentivesQuerySchemas A length-1 list containing the querySchema for registration and renewals.
    constructor(address _axiomV2QueryAddress, bytes32[] memory incentivesQuerySchemas)
        AxiomIncentives(_axiomV2QueryAddress, incentivesQuerySchemas)
    {
        require(incentivesQuerySchemas.length == 1, "Invalid incentivesQuerySchemas length");
        QUERY_SCHEMA = incentivesQuerySchemas[0];
    }

    /// @notice Set the referring address for a referee
    /// @param  referrer The address of the referrer
    function setReferrer(address referrer) external {
        require(referralAddress[msg.sender] == address(0), "Referrer already set");
        referralAddress[msg.sender] = referrer;
        emit Referral(msg.sender, referrer, uint64(block.number));
    }

    /// @inheritdoc AxiomIncentives
    function _validateClaim(
        bytes32, // querySchema
        uint256, // startClaimId
        uint256, // endClaimId
        uint256 incentiveId,
        uint256 // totalValue
    ) internal pure override {
        address referrer = address(uint160(incentiveId));
        require(referrer != 0, "Invalid referrer");
    }

    /// @inheritdoc AxiomIncentives
    function _sendClaimRewards(
        bytes32, // querySchema
        uint256 startClaimId,
        uint256 endClaimId,
        uint256 incentiveId,
        uint256 totalValue
    ) internal override {
        address referrer = address(uint160(incentiveId));
        emit Claim(referrer, startClaimId, endClaimId, totalValue);
    }
}
