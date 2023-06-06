import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { developmentChains, networkConfig } from '../helper-hardhat-config'
import verify from '../helper-functions'

const deployDataConsumerV3: DeployFunction = async function (
	hre: HardhatRuntimeEnvironment
) {
	// @ts-ignore
	const { getNamedAccounts, deployments, network } = hre
	const { deploy, log } = deployments
	const { deployer } = await getNamedAccounts()

	log('----------------------------------------------------')
	log('Deploying DataConsumerV3 contract and waiting for confirmations...')

	const DataFeedsContract = await deploy('DataConsumerV3', {
		from: deployer,
		args: [],
		log: true,
		waitConfirmations: networkConfig[network.name].blockConfirmations || 1
	})

	if (
		!developmentChains.includes(network.name) &&
		process.env.POLYGONSCAN_API_KEY
	) {
		await verify(DataFeedsContract.address, [])
	}
}

export default deployDataConsumerV3
deployDataConsumerV3.tags = ['all', 'DataConsumerV3']
