compile:
	npx hardhat compile

deploy-bsc-testnet:
	npx hardhat run script/deploy_upgradable.ts --network bscTestnet

verify-bsc-testnet:
	source .env && npx hardhat verify --network bscTestnet $PROXY_CONTRACT

upgrade-bsc-testnet:
	npx hardhat run script/upgrade.ts --network bscTestnet

deploy-bsc:
	npx hardhat run script/deploy_upgradable.ts --network bsc

verify-bsc:
	source .env && npx hardhat verify --network bsc $PROXY_CONTRACT

upgrade-bsc:
	npx hardhat run script/upgrade.ts --network bsc

deploy-dbc-testnet:
	npx hardhat run script/deploy_upgradable.ts --network dbcTestnet

verify-dbc-testnet:
	source .env && npx hardhat verify --network dbcTestnet $PROXY_CONTRACT

upgrade-dbc-testnet:
	npx hardhat run script/upgrade.ts --network dbcTestnet
