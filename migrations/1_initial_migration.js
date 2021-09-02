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
  let proxyAdmin = '0x5560aF0F46D00FCeA88627a9DF7A4798b1b10961';
  let admin = '0x4Cf0A877E906DEaD748A41aE7DA8c220E4247D9e';
  let wwan = '0x916283cc60fdaf05069796466af164876e35d21f';
  let wasp = '0x830053DABd78b4ef0aB0FeC936f8a1135B68da6f';
  let wand = '0x37e907f611CA55F10D32e3Af7407305Ee93B0A10';
  let priceOracle = '0x27933A9b0A5c21B838843d7601B6e0b488122AE9';
  let router = '0xeA300406FE2eED9CD2bF5c47D01BECa8Ad294Ec1';
  let operator = '0xc19e6f0b3c8f149c87f727a009e52d25d7c67964';
  //--------------------
  //TODO: MAINNET CONFIG----------
  // let proxyAdmin = '0xa206e4858849f70c3d684e854e7C126EF7baB32e';
  // let admin = '0x83f83439Cc3274714A7dad32898d55D17f7C6611';
  //--------------------

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
  await deployer.deploy(TemptationDelegate);
  let temptation5 = await TemptationDelegate.deployed();
  await deployer.deploy(TemptationDelegate);
  let temptation6 = await TemptationDelegate.deployed();
  await deployer.deploy(TemptationDelegate);
  let temptation7 = await TemptationDelegate.deployed();


  // address _admin, address _operator, address _router, address _tokenAddressFrom, address _tokenAddressTo, address[] calldata _path, address _stream
  await temptation0.initialize(deployerAddr, operator, router, wwan, '0x0f6be49eB9d86f97dE0EB759c856bFb0db8316f7', [wwan, '0x0f6be49eB9d86f97dE0EB759c856bFb0db8316f7'], stream.address); // wan->usdt
  await temptation1.initialize(deployerAddr, operator, router, '0x0f6be49eB9d86f97dE0EB759c856bFb0db8316f7', wwan, ['0x0f6be49eB9d86f97dE0EB759c856bFb0db8316f7', wwan], stream.address); // usdt->wan
  await temptation2.initialize(deployerAddr, operator, router, wwan, '0x48344649B9611a891987b2Db33fAada3AC1d05eC', [wwan, '0x48344649B9611a891987b2Db33fAada3AC1d05eC'], stream.address); // wan->eth
  await temptation3.initialize(deployerAddr, operator, router, '0x48344649B9611a891987b2Db33fAada3AC1d05eC', wwan, ['0x48344649B9611a891987b2Db33fAada3AC1d05eC', wwan], stream.address); // eth->wan
  await temptation4.initialize(deployerAddr, operator, router, '0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3', '0x48344649B9611a891987b2Db33fAada3AC1d05eC', ['0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3', '0x48344649B9611a891987b2Db33fAada3AC1d05eC'], stream.address); // btc->eth
  await temptation5.initialize(deployerAddr, operator, router, '0x48344649B9611a891987b2Db33fAada3AC1d05eC', '0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3', ['0x48344649B9611a891987b2Db33fAada3AC1d05eC', '0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3'], stream.address); // eth->btc
  await temptation6.initialize(deployerAddr, operator, router, wwan, '0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3', [wwan, '0x48344649B9611a891987b2Db33fAada3AC1d05eC', '0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3'], stream.address); // wan->eth->btc
  await temptation7.initialize(deployerAddr, operator, router, '0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3', wwan, ['0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3', '0x48344649B9611a891987b2Db33fAada3AC1d05eC', wwan], stream.address); // btc->eth->wan


  await stream.grantRole('0x00', admin);

  await temptation0.grantRole('0x00', admin);
  await temptation1.grantRole('0x00', admin);
  await temptation2.grantRole('0x00', admin);
  await temptation3.grantRole('0x00', admin);
  await temptation4.grantRole('0x00', admin);
  await temptation5.grantRole('0x00', admin);
  await temptation6.grantRole('0x00', admin);
  await temptation7.grantRole('0x00', admin);

  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await stream.renounceRole('0x00', deployerAddr);
    await temptation0.renounceRole('0x00', deployerAddr);
    await temptation1.renounceRole('0x00', deployerAddr);
    await temptation2.renounceRole('0x00', deployerAddr);
    await temptation3.renounceRole('0x00', deployerAddr);
    await temptation4.renounceRole('0x00', deployerAddr);
    await temptation5.renounceRole('0x00', deployerAddr);
    await temptation6.renounceRole('0x00', deployerAddr);
    await temptation7.renounceRole('0x00', deployerAddr);
  }

  console.log('stream:', stream.address);
  console.log('temptation 0:', temptation0.address);
  console.log('temptation 1:', temptation1.address);
  console.log('temptation 2:', temptation2.address);
  console.log('temptation 3:', temptation3.address);
  console.log('temptation 4:', temptation4.address);
  console.log('temptation 5:', temptation5.address);
  console.log('temptation 6:', temptation6.address);
  console.log('temptation 7:', temptation7.address);
};
