const CollateralOracle = artifacts.require("CollateralOracle");
const StreamTank = artifacts.require("StreamTank");
const TradeCar = artifacts.require("TradeCar");

const tokens = {
  WWAN: '0x916283cc60fdaf05069796466af164876e35d21f',
  WASP: '0x830053DABd78b4ef0aB0FeC936f8a1135B68da6f',
  WAND: '0x37e907f611CA55F10D32e3Af7407305Ee93B0A10',
  wanUSDT: '0x0f6be49eB9d86f97dE0EB759c856bFb0db8316f7',
  wanBTC: '0x3c653971ffc0794CB2fC5DF5D47576BEdCE149B3',
  wanETH: '0x48344649B9611a891987b2Db33fAada3AC1d05eC',
}

const supportPairs = [
  {
    from: 'WWAN',
    to: 'wanUSDT',
    path: ['WWAN','wanUSDT'],
  },
  {
    from: 'wanUSDT',
    to: 'WWAN',
    path: ['wanUSDT','WWAN'],
  },
  {
    from: 'WWAN',
    to: 'wanETH',
    path: ['WWAN','wanETH'],
  },
  {
    from: 'wanETH',
    to: 'WWAN',
    path: ['wanETH','WWAN'],
  },
  {
    from: 'wanBTC',
    to: 'wanETH',
    path: ['wanBTC','wanETH'],
  },
  {
    from: 'wanETH',
    to: 'wanBTC',
    path: ['wanETH','wanBTC'],
  },
  {
    from: 'WWAN',
    to: 'wanBTC',
    path: ['WWAN','wanETH','wanBTC'],
  },
  {
    from: 'wanBTC',
    to: 'WWAN',
    path: ['wanBTC','wanETH','WWAN'],
  },
  {
    from: 'WWAN',
    to: 'WASP',
    path: ['WWAN','WASP'],
  },
];

module.exports = async function (deployer) {
  // deployer.deploy(Migrations);
  if (deployer.network === 'development' || deployer.network === 'coverage') {
    console.log('no need migration');
    return;
  }

  // return;

  let deployerAddr = deployer.provider.addresses[0];
  console.log('deployerAddr', deployerAddr);

  let admin = '0x0C2c190EA95484BAe41D4A26607cB59565f53e4a';

  let priceOracle = '0x27933a9b0a5c21b838843d7601b6e0b488122ae9';
  let router = '0xeA300406FE2eED9CD2bF5c47D01BECa8Ad294Ec1';
  let operator = '0xc19e6f0b3c8f149c87f727a009e52d25d7c67964';

  await deployer.deploy(CollateralOracle);

  let oracle = await CollateralOracle.deployed();

  // address _admin, address _wasp, address _wand, address _oracle
  await oracle.initialize(admin, tokens.WASP, tokens.WAND, priceOracle);

  await deployer.deploy(StreamTank);

  let stream = await StreamTank.deployed();
  
  await stream.initialize(deployerAddr, tokens.WWAN, oracle.address);

  let cars = [];
  let carCount = supportPairs.length;
  for (let i=0; i<carCount; i++) {
    await deployer.deploy(TradeCar);
    cars[i] = await TradeCar.deployed();
  }

  for (let i=0; i<carCount; i++) {
    await cars[i].initialize(operator, router, tokens[supportPairs[i].from], tokens[supportPairs[i].to], supportPairs[i].path.map(v=>tokens[v]), stream.address);
    console.log('car', i, 'initialized')
  }

  // config new admin
  await stream.grantRole('0x00', admin);

  // renonce tmp admin
  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await stream.renounceRole('0x00', deployerAddr);
  }

  console.log('StreamTank:', stream.address);
  console.log('CollateralOracle:', oracle.address);
  let configJson = [];
  for (let i=0; i<carCount; i++) {
    configJson.push({
      name: supportPairs[i].from + '->' + supportPairs[i].to,
      fromToken: tokens[supportPairs[i].from],
      toToken: tokens[supportPairs[i].to],
      tradeAddress: cars[i].address,
      isWorking: false,
    })
  }

  console.log('TradeCars', JSON.stringify(configJson, null, 2));
};
