import { config as dotEnvConfig } from 'dotenv'
dotEnvConfig()

import { HardhatUserConfig } from 'hardhat/types'

import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import '@nomiclabs/hardhat-etherscan'
import 'solidity-coverage'

interface Etherscan {
	etherscan: { apiKey: string | undefined }
}

type HardhatUserEtherscanConfig = HardhatUserConfig & Etherscan

const { POLYGONSCAN_API_KEY, PRIVATE_KEY } = process.env

const defaultNetwork = 'localhost'

const config: HardhatUserEtherscanConfig = {
	defaultNetwork,
	networks: {
		hardhat: {},
		localhost: {
			url: 'http://127.0.0.1:8545'
		},
		mumbai: {
			chainId: 80001,
			accounts: [PRIVATE_KEY],
			url: 'https://rpc-mumbai.maticvigil.com',
			gas: 6000000, // Increase the gas limit
			gasPrice: 10000000000 // Set a custom gas price (in Gwei, optional)
		},
		coverage: {
			url: 'http://127.0.0.1:8555' // Coverage launches its own ganache-cli client
		}
	},
	etherscan: {
		// Your API key for Etherscan
		// Obtain one at https://etherscan.io/
		apiKey: POLYGONSCAN_API_KEY
	},
	solidity: {
		version: '0.8.19',
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
				details: { yul: false }
			}
		}
	}
}

export default config
