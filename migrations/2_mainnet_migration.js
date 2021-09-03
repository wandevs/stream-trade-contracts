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
  let admin = '0x4c20857E086514D711E658eEF962215e5fFEdDdf';
  let wwan = '0xdabD997aE5E4799BE47d6E69D9431615CBa28f48';
  let wasp = '0x8B9F9f4aA70B1B0d586BE8aDFb19c1Ac38e05E9a';
  let wand = '0x230f0C01b8e2c027459781E6a56dA7e1876EFDbe';
  let priceOracle = '0xa2b6CFAE041371A30bED5f2092393f03D6dCDEEc';
  let router = '0xeA300406FE2eED9CD2bF5c47D01BECa8Ad294Ec1';
  let operator = '0xc19e6f0b3c8f149c87f727a009e52d25d7c67964';

  let wanUSDT = '0x11e77E27Af5539872efEd10abaA0b408cfd9fBBD';
  let ZOO = '0x6e11655d6aB3781C6613db8CB1Bc3deE9a7e111F';
  let wanLTC = '0xd8e7bd03920BA407D764789B11DD2B5EAeE0961e';

  await deployer.deploy(CollateralOracle);

  let oracle = await CollateralOracle.deployed();

  // address _admin, address _wasp, address _wand, address _oracle
  await oracle.initialize(admin, wasp, wand, priceOracle);
  // return;

  await deployer.deploy(StreamDelegate);

  let stream = await StreamDelegate.deployed();
  
  await stream.initialize(deployerAddr, wwan, oracle.address);

  await deployer.deploy(TemptationDelegate);
  let temptation0 = await TemptationDelegate.deployed();
  await deployer.deploy(TemptationDelegate);
  let temptation1 = await TemptationDelegate.deployed();
  await deployer.deploy(TemptationDelegate);
  let temptation2 = await TemptationDelegate.deployed();
  await deployer.deploy(TemptationDelegate);
  let temptation3 = await TemptationDelegate.deployed();
  await deployer.deploy(TemptationDelegate);
  let temptation4 = await TemptationDelegate.deployed();

  // address _admin, address _operator, address _router, address _tokenAddressFrom, address _tokenAddressTo, address[] calldata _path, address _stream
  // wan->usdt
  // usdt->wan
  // zoo->wasp->usdt
  // wasp->wan->usdt
  // zoo->wasp->LTC

  await temptation0.initialize(deployerAddr, operator, router, wwan, wanUSDT, [wwan, wanUSDT], stream.address); // wan->usdt
  await temptation1.initialize(deployerAddr, operator, router, wanUSDT, wwan, [wanUSDT, wwan], stream.address); // usdt->wan
  await temptation2.initialize(deployerAddr, operator, router, ZOO, wanUSDT, [ZOO, wasp, wanUSDT], stream.address); // zoo->wasp->usdt
  await temptation3.initialize(deployerAddr, operator, router, wasp, wanUSDT, [wasp, wwan, wanUSDT], stream.address); // wasp->wan->usdt
  await temptation4.initialize(deployerAddr, operator, router, ZOO, wanLTC, [ZOO, wasp, wanLTC], stream.address); // zoo->wasp->LTC


  await stream.grantRole('0x00', admin);

  await temptation0.grantRole('0x00', admin);
  await temptation1.grantRole('0x00', admin);
  await temptation2.grantRole('0x00', admin);
  await temptation3.grantRole('0x00', admin);
  await temptation4.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await stream.renounceRole('0x00', deployerAddr);
    await temptation0.renounceRole('0x00', deployerAddr);
    await temptation1.renounceRole('0x00', deployerAddr);
    await temptation2.renounceRole('0x00', deployerAddr);
    await temptation3.renounceRole('0x00', deployerAddr);
    await temptation4.renounceRole('0x00', deployerAddr);
  }

  console.log('stream:', stream.address);
  console.log('temptation 0:', temptation0.address);
  console.log('temptation 1:', temptation1.address);
  console.log('temptation 2:', temptation2.address);
  console.log('temptation 3:', temptation3.address);
  console.log('temptation 4:', temptation4.address);
};
