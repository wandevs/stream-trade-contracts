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
  await deployer.deploy(TemptationDelegate);
  return;

  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);
  //TODO: TESTNET CONFIG----------
  let proxyAdmin = '0x5560aF0F46D00FCeA88627a9DF7A4798b1b10961';
  let admin = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  let wwan = '0x916283cc60fdaf05069796466af164876e35d21f';
  let wasp = '0x830053DABd78b4ef0aB0FeC936f8a1135B68da6f';
  let router = '0xeA300406FE2eED9CD2bF5c47D01BECa8Ad294Ec1';
  //--------------------
  //TODO: MAINNET CONFIG----------
  // let proxyAdmin = '0xa206e4858849f70c3d684e854e7C126EF7baB32e';
  // let admin = '0x83f83439Cc3274714A7dad32898d55D17f7C6611';
  //--------------------

  await deployer.deploy(CollateralOracle);

  let oracle = await CollateralOracle.deployed();


  await deployer.deploy(StreamDelegate);
  await deployer.deploy(TemptationDelegate);

  let streamDelegate = await StreamDelegate.deployed();
  let temptationDelegate = await TemptationDelegate.deployed();

  await deployer.deploy(CommonProxy, streamDelegate.address, proxyAdmin, '0x');
  let stream = await StreamDelegate.at((await CommonProxy.deployed()).address);

  await deployer.deploy(CommonProxy, temptationDelegate.address, proxyAdmin, '0x');
  let temptation = await TemptationDelegate.at((await CommonProxy.deployed()).address);
  
  await stream.initialize(deployerAddr, wwan, wasp, oracle.address);

  // address _admin, address _operator, address _router, address _tokenAddressFrom, address _tokenAddressTo, address _stream
  await temptation.initialize(deployerAddr, admin, router, wwan, '0x0f6be49eB9d86f97dE0EB759c856bFb0db8316f7', stream.address);

  await stream.grantRole('0x00', admin);
  await temptation.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await stream.renounceRole('0x00', deployerAddr);
    await temptation.renounceRole('0x00', deployerAddr);
  }

  console.log('stream:', stream.address);
  console.log('temptation:', temptation.address);
};
