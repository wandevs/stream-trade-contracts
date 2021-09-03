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

  let stream = '0x6C28A4D2C2F25B733e23720342c2ad2e69d6D0ec';

  await deployer.deploy(TemptationDelegate);
  let temptation0 = await TemptationDelegate.deployed();
 
  await temptation0.initialize(deployerAddr, operator, router, wasp, ZOO, [wasp, ZOO], stream); // WASP->ZOO

  await temptation0.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await temptation0.renounceRole('0x00', deployerAddr);
  }

  console.log('temptation 0:', temptation0.address);
};
