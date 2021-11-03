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
  // return;

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
  let wanXRP = '0xf665E0e3E75D16466345E1129530ec28839EfaEa';

  let wanBTC = '0x50c439B6d602297252505a6799d84eA5928bCFb6';
  let wanETH = '0xE3aE74D1518A76715aB4C7BeDF1af73893cd435A';
  let wanUSDC = '0x52A9CEA01c4CBDd669883e41758B8eB8e8E2B34b';
  let wanDOGE = '0xD3a33C6fEa7F785DdC0915f6A76919C11AbdED45';
  let wanDOT = '0x52f44783BdF480e88C0eD4cF341A933CAcfDBcaa'; 

  let stream = '0x6C28A4D2C2F25B733e23720342c2ad2e69d6D0ec';

  await deployer.deploy(TemptationDelegate);
  let temptation0 = await TemptationDelegate.deployed(); // wanUSDT->wand
  await deployer.deploy(TemptationDelegate);
  let temptation1 = await TemptationDelegate.deployed(); // wan->wand
  await deployer.deploy(TemptationDelegate);
  let temptation2 = await TemptationDelegate.deployed(); // wanBTC->wand
  await deployer.deploy(TemptationDelegate);
  let temptation3 = await TemptationDelegate.deployed(); // wanETH->wand
  await deployer.deploy(TemptationDelegate);
  let temptation4 = await TemptationDelegate.deployed(); // wanUSDC->wand
  await deployer.deploy(TemptationDelegate);
  let temptation5 = await TemptationDelegate.deployed(); // wasp->wand
  await deployer.deploy(TemptationDelegate);
  let temptation6 = await TemptationDelegate.deployed(); // wanXRP->wand
  await deployer.deploy(TemptationDelegate);
  let temptation7 = await TemptationDelegate.deployed(); // ZOO->wand
  await deployer.deploy(TemptationDelegate);
  let temptation8 = await TemptationDelegate.deployed(); // wanLTC->wand
  await deployer.deploy(TemptationDelegate);
  let temptation9 = await TemptationDelegate.deployed(); // wanDOGE->wand
  await deployer.deploy(TemptationDelegate);
  let temptation10 = await TemptationDelegate.deployed(); // wanDOT->wand
 
  await temptation0.initialize(deployerAddr, operator, router, wanUSDT, wand, [wanUSDT, wwan, wasp, wand], stream); //wanUSDT->wand
  await temptation1.initialize(deployerAddr, operator, router, wwan, wand, [wwan, wasp, wand], stream); //wan->wand
  await temptation2.initialize(deployerAddr, operator, router, wanBTC, wand, [wanBTC, wwan, wasp, wand], stream); //wanBTC->wand
  await temptation3.initialize(deployerAddr, operator, router, wanETH, wand, [wanETH, wwan, wasp, wand], stream); //wanETH->wand
  await temptation4.initialize(deployerAddr, operator, router, wanUSDC, wand, [wanUSDC, wanUSDT, wasp, wand], stream); //wanUSDC->wand
  await temptation5.initialize(deployerAddr, operator, router, wasp, wand, [wasp, wand], stream); //wasp->wand
  await temptation6.initialize(deployerAddr, operator, router, wanXRP, wand, [wanXRP, wwan, wasp, wand], stream); //wanXRP->wand
  await temptation7.initialize(deployerAddr, operator, router, ZOO, wand, [ZOO, wasp, wand], stream); //ZOO->wand
  await temptation8.initialize(deployerAddr, operator, router, wanLTC, wand, [wanLTC, wasp, wand], stream); //wanLTC->wand
  await temptation9.initialize(deployerAddr, operator, router, wanDOGE, wand, [wanDOGE, wasp, wand], stream); //wanDOGE->wand
  await temptation10.initialize(deployerAddr, operator, router, wanDOT, wand, [wanDOT, wasp, wand], stream); //wanDOT->wand

  // await temptation0.grantRole('0x00', admin);
  // await temptation1.grantRole('0x00', admin);
  // await temptation2.grantRole('0x00', admin);
  // await temptation3.grantRole('0x00', admin);
  // await temptation4.grantRole('0x00', admin);
  // await temptation5.grantRole('0x00', admin);
  // await temptation6.grantRole('0x00', admin);
  // await temptation7.grantRole('0x00', admin);
  // await temptation8.grantRole('0x00', admin);
  // await temptation9.grantRole('0x00', admin);
  // await temptation10.grantRole('0x00', admin);

  // if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
  //   console.log('renounceRole:', deployerAddr);
  //   await temptation0.renounceRole('0x00', deployerAddr);
  //   await temptation1.renounceRole('0x00', deployerAddr);
  //   await temptation2.renounceRole('0x00', deployerAddr);
  // }

  console.log('temptation 0:', temptation0.address);
  console.log('temptation 1:', temptation1.address);
  console.log('temptation 2:', temptation2.address);
  console.log('temptation 3:', temptation3.address);
  console.log('temptation 4:', temptation4.address);
  console.log('temptation 5:', temptation5.address);
  console.log('temptation 6:', temptation6.address);
  console.log('temptation 7:', temptation7.address);
  console.log('temptation 8:', temptation8.address);
  console.log('temptation 9:', temptation9.address);
  console.log('temptation 10:', temptation10.address);
};
