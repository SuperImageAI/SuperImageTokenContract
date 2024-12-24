compile:
	npx hardhat compile

deploy-dbc-testnet:
	source .env && npx hardhat run script/deploy_upgradable.ts --network dbcTestnet

verify-dbc-testnet:
	source .env && npx hardhat verify --network dbcTestnet $PROXY_CONTRACT

upgrade-dbc-testnet:
	npx hardhat run script/upgrade.ts --network dbcTestnet

request_token_upgrade_auth-dbc-testnet:
	source .env && npx hardhat run script/create_proposal_for_requesting_token_upgrade_permission.ts --network dbcTestnet


deploy_multi_sign_time_lock-dbc-testnet:
	source .env && npx hardhat run script/deploy_multi_sign_time_lock.ts --network dbcTestnet

verify_multi_sign_time_lock-dbc-testnet:
	source .env && npx hardhat verify --network dbcTestnet $MULTI_SGIN_TIME_LOCK_CONTRACT

upgrade_multi_sign_time_lock-dbc-testnet:
	npx hardhat run script/upgrade_multi_sign_time_lock.ts --network dbcTestnet

request_multi_sign_time_lock_upgrade_auth-dbc-testnet:
	source .env && npx hardhat run script/create_proposal_for_requesting_multi_sign_time_lock_upgrade_permission.ts --network dbcTestnet


deploy-dbc-mainnet:
	source .env && npx hardhat run script/deploy_upgradable.ts --network dbcMainnet

verify-dbc-mainnet:
	source .env && npx hardhat verify --network dbcMainnet $PROXY_CONTRACT

upgrade-dbc-mainnet:
	npx hardhat run script/upgrade.ts --network dbcMainnet

request_token_upgrade_auth-dbc-mainnet:
	source .env && npx hardhat run script/create_proposal_for_requesting_token_upgrade_permission.ts --network dbcMainnet


deploy_multi_sign_time_lock-dbc-mainnet:
	source .env && npx hardhat run script/deploy_multi_sign_time_lock.ts --network dbcMainnet

verify_multi_sign_time_lock-dbc-mainnet:
	source .env && npx hardhat verify --network dbcMainnet $MULTI_SGIN_TIME_LOCK_CONTRACT

upgrade_multi_sign_time_lock-dbc-mainnet:
	npx hardhat run script/upgrade_multi_sign_time_lock.ts --network dbcMainnet

request_multi_sign_time_lock_upgrade_auth-dbc-mainnet:
	source .env && npx hardhat run script/create_proposal_for_requesting_multi_sign_time_lock_upgrade_permission.ts --network dbcMainnet
