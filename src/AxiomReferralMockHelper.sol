// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract AxiomReferralMockHelper {
    address public axiomV2QueryAddress;
    bytes32 QUERY_SCHEMA;
    uint64 SOURCE_CHAIN_ID;
    mapping(address => address) referralAddress;
    mapping(address => uint256) lastClaimedId;

    event Referral(address indexed trader, address indexed referrer, uint64 blockNumber);

    event Trade(
        address trader,
        address subject,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 subjectEthAmount,
        uint256 supply
    );

    function setReferrer(address trader, address referrer) external {
        referralAddress[trader] = referrer;
        emit Referral(trader, referrer, uint64(block.number));
    }

    function emitTrade(
        address trader,
        address subject,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 subjectEthAmount,
        uint256 supply
    ) external {
        emit Trade(trader, subject, isBuy, shareAmount, ethAmount, protocolEthAmount, subjectEthAmount, supply);
    }
}
