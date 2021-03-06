const CollateralOracle = artifacts.require("CollateralOracle");
const StreamTank = artifacts.require("StreamTank");
const TradeCar = artifacts.require("TradeCar");
const TradeCarManager = artifacts.require("TradeCarManager");

const tokens = {
  WWAN: '0xdabD997aE5E4799BE47d6E69D9431615CBa28f48',
  WASP: '0x8B9F9f4aA70B1B0d586BE8aDFb19c1Ac38e05E9a',
  WAND: '0x230f0C01b8e2c027459781E6a56dA7e1876EFDbe',
  wanUSDT: '0x11e77E27Af5539872efEd10abaA0b408cfd9fBBD',
  ZOO: '0x6e11655d6aB3781C6613db8CB1Bc3deE9a7e111F',
  wanLTC: '0xd8e7bd03920BA407D764789B11DD2B5EAeE0961e',
  wanXRP: '0xf665E0e3E75D16466345E1129530ec28839EfaEa',
  wanBTC: '0x50c439B6d602297252505a6799d84eA5928bCFb6',
  wanETH: '0xE3aE74D1518A76715aB4C7BeDF1af73893cd435A',
  wanUSDC: '0x52A9CEA01c4CBDd669883e41758B8eB8e8E2B34b',
  wanDOGE: '0xD3a33C6fEa7F785DdC0915f6A76919C11AbdED45',
  wanDOT: '0x52f44783BdF480e88C0eD4cF341A933CAcfDBcaa',
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
    from: 'ZOO',
    to: 'wanUSDT',
    path: ['ZOO','WWAN','wanUSDT'],
  },
  {
    from: 'WASP',
    to: 'wanUSDT',
    path: ['WASP','WWAN','wanUSDT'],
  },
  {
    from: 'ZOO',
    to: 'wanLTC',
    path: ['ZOO','WASP','wanLTC'],
  },
  {
    from: 'ZOO',
    to: 'wanXRP',
    path: ['ZOO','WWAN','wanXRP'],
  },
  {
    from: 'WASP',
    to: 'WWAN',
    path: ['WASP','WWAN'],
  },
  {
    from: 'wanXRP',
    to: 'WWAN',
    path: ['wanXRP','WWAN'],
  },
  {
    from: 'WWAN',
    to: 'wanXRP',
    path: ['WWAN','wanXRP'],
  },
  {
    from: 'WASP',
    to: 'ZOO',
    path: ['WASP','ZOO'],
  },
  {
    from: 'WWAN',
    to: 'WAND',
    path: ['WWAN','WASP','WAND'],
  },
  {
    from: 'wanBTC',
    to: 'WAND',
    path: ['wanBTC','WWAN','WASP','WAND'],
  },
  {
    from: 'wanETH',
    to: 'WAND',
    path: ['wanETH','WWAN','WASP','WAND'],
  },
  {
    from: 'wanUSDC',
    to: 'WAND',
    path: ['wanUSDC','wanUSDT','WWAN','WASP','WAND'],
  },
  {
    from: 'wanUSDT',
    to: 'WAND',
    path: ['wanUSDT','WWAN','WASP','WAND'],
  },
  {
    from: 'WASP',
    to: 'WAND',
    path: ['WASP','WAND'],
  },
  {
    from: 'wanXRP',
    to: 'WAND',
    path: ['wanXRP','WWAN','WASP','WAND'],
  },
  {
    from: 'ZOO',
    to: 'WAND',
    path: ['ZOO','WASP','WAND'],
  },
  {
    from: 'wanLTC',
    to: 'WAND',
    path: ['wanLTC','WASP','WAND'],
  },
  {
    from: 'wanDOGE',
    to: 'WAND',
    path: ['wanDOGE','WASP','WAND'],
  },
  {
    from: 'wanDOT',
    to: 'WAND',
    path: ['wanDOT','WASP','WAND'],
  },
  {
    from: 'wanUSDT',
    to: 'ZOO',
    path: ['wanUSDT','WWAN','ZOO'],
  },
  {
    from: 'WWAN',
    to: 'ZOO',
    path: ['WWAN','ZOO'],
  },
  {
    from: 'WAND',
    to: 'wanUSDT',
    path: ['WAND','WASP','WWAN','wanUSDT'],
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

  let admin = '0x5d47F697b16B337e3B462c59E930905F7B41F665'; // multi-sig wallet

  let priceOracle = '0xa2b6CFAE041371A30bED5f2092393f03D6dCDEEc';
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

  await deployer.deploy(TradeCarManager);

  let manager = await TradeCarManager.deployed();

  await manager.initialize(deployerAddr, stream.address);

  for (let i=0; i<carCount; i++) {
    console.log('add car to manager', i);
    await manager.addCar(
      cars[i].address,
      supportPairs[i].path.join('->'),
      tokens[supportPairs[i].from],
      tokens[supportPairs[i].to]);
  }

  // config new admin
  await stream.grantRole('0x00', admin);
  await manager.grantRole('0x00', admin);

  // renonce tmp admin
  if (deployerAddr.toLowerCase() !== admin.toLowerCase()) {
    console.log('renounceRole:', deployerAddr);
    await stream.renounceRole('0x00', deployerAddr);
    await manager.renounceRole('0x00', deployerAddr);
  }

  console.log('StreamTank:', stream.address);
  console.log('CollateralOracle:', oracle.address);
  console.log('TradeCarManager:', manager.address);

  let configJson = [];
  for (let i=0; i<carCount; i++) {
    configJson.push({
      name: supportPairs[i].path.join('->'),
      fromToken: tokens[supportPairs[i].from],
      toToken: tokens[supportPairs[i].to],
      tradeAddress: cars[i].address,
      isWorking: false,
    })
  }

  console.log('TradeCars', JSON.stringify(configJson, null, 2));

  console.log('trade addresses:')
  for (let i=0; i<carCount; i++) {
    console.log(cars[i].address);
  }
};

