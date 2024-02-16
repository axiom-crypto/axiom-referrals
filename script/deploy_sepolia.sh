# Call script from root directory of repo: ./script/deploy_sepolia.sh

source .env
forge script script/AxiomReferral.s.sol:AxiomReferralScript --private-key $PRIVATE_KEY_SEPOLIA --broadcast --rpc-url $PROVIDER_URI_SEPOLIA -vvvv --force --verify --etherscan-api-key $ETHERSCAN_API_KEY
cp out/AxiomReferral.sol/AxiomReferral.json ./app/src/lib/abi/AxiomReferral.json