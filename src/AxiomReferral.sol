// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { AxiomV2Client } from "@axiom-v2-client/client/AxiomV2Client.sol";

contract AxiomReferral is AxiomV2Client {
    /// @dev The unique identifier of the circuit accepted by this contract.
    bytes32 immutable QUERY_SCHEMA;

    /// @dev The chain ID of the chain whose data the callback is expected to be called from.
    uint64 immutable SOURCE_CHAIN_ID;

    /// @dev `referralAddress[trader] = referrer` if `referrer` referred `trader`.
    mapping(address => address) referralAddress;

    /// @dev `lastClaimedBlockNumber[referrer]` is the latest block number at which `referrer` claimed a referral reward.
    mapping(address => uint64) lastClaimedBlockNumber;

    /// @notice Emitted when a new referral is registered.
    /// @param trader The address of the trader.
    /// @param referrer The address of the referrer.
    /// @param blockNumber The block number at which the referral was registered.
    event Referral(address indexed trader, address indexed referrer, uint64 blockNumber);

    /// @notice Construct a new AxiomNonceIncrementor contract.
    /// @param  _axiomV2QueryAddress The address of the AxiomV2Query contract.
    /// @param  _callbackSourceChainId The ID of the chain the query reads from.
    constructor(address _axiomV2QueryAddress, uint64 _callbackSourceChainId, bytes32 _querySchema)
        AxiomV2Client(_axiomV2QueryAddress)
    {
        QUERY_SCHEMA = _querySchema;
        SOURCE_CHAIN_ID = _callbackSourceChainId;
    }

    /// @notice Set the referring address for a trader
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
        require(sourceChainId == SOURCE_CHAIN_ID, "Source chain ID does not match");
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
        uint64 startBlockNumber = uint64(uint256(axiomResults[0]));
        uint64 endBlockNumber = uint64(uint256(axiomResults[1]));
        address referrer = address(uint160(uint256(axiomResults[2])));
        uint256 totalTradeVolume = uint256(axiomResults[3]);
    }
}
