import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { developmentChains, networkConfig } from '../helper-hardhat-config'
import verify from '../helper-functions'

const deployBIOrbit: DeployFunction = async function (
	hre: HardhatRuntimeEnvironment
) {
	// @ts-ignore
	const { getNamedAccounts, deployments, network } = hre
	const { deploy, log, get } = deployments
	const { deployer } = await getNamedAccounts()
	const dataFeeds = await get('DataConsumerV3')

	log('----------------------------------------------------')
	log('Deploying BIOrbit contract and waiting for confirmations...')

	const BIOrbitContract = await deploy('BIOrbit', {
		from: deployer,
		args: [dataFeeds.address],
		log: true,
		waitConfirmations: networkConfig[network.name].blockConfirmations || 1
	})

	if (
		!developmentChains.includes(network.name) &&
		process.env.POLYGONSCAN_API_KEY
	) {
		await verify(BIOrbitContract.address, [])
	}
}

export default deployBIOrbit
deployBIOrbit.tags = ['all', 'BIOrbit']
