const CollateralOracle = artifacts.require("CollateralOracle");
const StreamDelegate = artifacts.require("StreamDelegate");
const TemptationDelegate = artifacts.require("TemptationDelegate");
const CommonProxy = artifacts.require("CommonProxy");

module.exports = async function (deployer) {
  // deployer.deploy(Migrations);
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }

  // await deployer.deploy(StreamDelegate);
  // await deployer.deploy(CollateralOracle);
  return;

  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO: TESTNET CONFIG----------
  // let proxyAdmin = '0x5560aF0F46D00FCeA88627a9DF7A4798b1b10961';
  let admin = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  let wwan = '0x916283cc60fdaf05069796466af164876e35d21f';
  let wasp = '0x830053DABd78b4ef0aB0FeC936f8a1135B68da6f';
  let wand = '0x37e907f611CA55F10D32e3Af7407305Ee93B0A10';
  let router = '0xeA300406FE2eED9CD2bF5c47D01BECa8Ad294Ec1';
  let operator = '0xc19e6f0b3c8f149c87f727a009e52d25d7c67964';

  let stream = '0x75b7330DC12312e70636417D587163dD5d5D1da2';

  await deployer.deploy(TemptationDelegate);
  let temptation0 = await TemptationDelegate.deployed();
 
  await temptation0.initialize(deployerAddr, operator, router, wwan, wasp, [wwan, wasp], stream); // wan->wasp

  await temptation0.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await temptation0.renounceRole('0x00', deployerAddr);
  }

  console.log('temptation 0:', temptation0.address);
};
