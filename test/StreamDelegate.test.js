const FakeErc20 = artifacts.require('FakeErc20');
const StreamDelegate = artifacts.require('StreamDelegate');
const WwanToken = artifacts.require('WwanToken');
const { time, expectEvent} = require("@openzeppelin/test-helpers");

const assert = require('assert');

contract("StreamDelegate", accounts => {
  let delegate;
  let token;
  let wasp;
  beforeEach(async ()=>{
    token = await FakeErc20.new('MOO', 'MOO');
    await token.mint(accounts[0], 1000000);
    await token.mint(accounts[1], 1000000);
    await token.mint(accounts[2], 1000000);

    wasp = await FakeErc20.new('WASP', 'WASP');
    await wasp.mint(accounts[0], '10000000000000000000000');
    await wasp.mint(accounts[1], '10000000000000000000000');
    await wasp.mint(accounts[2], '10000000000000000000000');

    let wwan = await WwanToken.new();

    delegate = await StreamDelegate.new();
    await delegate.initialize(accounts[0], wwan.address, wasp.address);
    await token.approve(delegate.address, 0xfffffffffffff, {from: accounts[0]});
    await token.approve(delegate.address, 0xfffffffffffff, {from: accounts[1]});
    await token.approve(delegate.address, 0xfffffffffffff, {from: accounts[2]});
    await wasp.approve(delegate.address, '1000000000000000000000000', {from: accounts[0]});
    await wasp.approve(delegate.address, '1000000000000000000000000', {from: accounts[1]});
    await wasp.approve(delegate.address, '1000000000000000000000000', {from: accounts[2]});
  });

  it("should success deposit", async () => {
    await delegate.deposit(token.address, 100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '900000', 1);
    assert.strictEqual((await delegate.userInfo(accounts[0], token.address)).toString(), '100000', 1.1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[0], token.address)).toString(), '100000', 1.1);

    await delegate.deposit(token.address, 100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '800000', 2);
    assert.strictEqual((await delegate.userInfo(accounts[0], token.address)).toString(), '200000', 2.1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[0], token.address)).toString(), '200000', 2.1);

    await delegate.deposit(token.address, 100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '700000', 3);
    assert.strictEqual((await delegate.userInfo(accounts[0], token.address)).toString(), '300000', 3.1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[0], token.address)).toString(), '300000', 3.1);

    await delegate.deposit(token.address, 1000000, {from: accounts[1]});
    assert.strictEqual((await token.balanceOf(accounts[1])).toString(), '0', 4);
    assert.strictEqual((await delegate.userInfo(accounts[1], token.address)).toString(), '1000000', 4.1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[1], token.address)).toString(), '1000000', 4.1);

    await delegate.deposit(token.address, 1000000, {from: accounts[2]});
    assert.strictEqual((await token.balanceOf(accounts[2])).toString(), '0', 5);
    assert.strictEqual((await delegate.userInfo(accounts[1], token.address)).toString(), '1000000', 5.1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[1], token.address)).toString(), '1000000', 5.1);

  });

  it("should success withdraw", async () => {
    await delegate.deposit(token.address, 1000000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '0', 6);

    await delegate.withdraw(token.address, 500000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '500000', 7);

    await delegate.withdraw(token.address, 500000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '1000000', 8);

  });

  const start = async () => {
    await delegate.deposit(token.address, 1000000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '0', 6);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[0], token.address)).toString(), '1000000', 4.1);

    let ret = await delegate.startStream(token.address, 1, accounts[1], {from: accounts[0]});
    console.log('startStream gasUsed', ret.receipt.gasUsed);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[1], token.address)).toString(), '0', 4.1);
    assert.strictEqual((await wasp.balanceOf(accounts[0])).toString(), '9900000000000000000000', 6);
    assert.strictEqual((await wasp.balanceOf(delegate.address)).toString(), '100000000000000000000', 6);

    time.increase(1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[0], token.address)).toString(), '999999', 4.1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[1], token.address)).toString(), '1', 4.1);
    time.increase(99);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[1], token.address)).toString(), '100', 4.1);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[0], token.address)).toString(), '999900', 4.1);
  }

  it("should success start", async () => {
    await start();
  });

  const stop = async () => {
    let ret = await delegate.stopStream(token.address, accounts[1], {from: accounts[0]});
    console.log('stopStream gasUsed', ret.receipt.gasUsed);

    assert.strictEqual((await wasp.balanceOf(accounts[0])).toString(), '10000000000000000000000', 1);
    assert.strictEqual((await wasp.balanceOf(delegate.address)).toString(), '0', 2);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[1], token.address)).toString(), '100', 3);
    assert.strictEqual((await delegate.getUserRealTimeAsset(accounts[0], token.address)).toString(), '999900', 4);
    assert.strictEqual((await delegate.userInfo(accounts[1], token.address)).toString(), '100', 5);
    assert.strictEqual((await delegate.userInfo(accounts[0], token.address)).toString(), '999900', 6);
    ret = await delegate.withdraw(token.address, 100, {from: accounts[1]});
    console.log('withdraw gasUsed', ret.receipt.gasUsed);

    assert.strictEqual((await token.balanceOf(accounts[1])).toString(), '1000100', 7);
  }

  it("should success stop", async () => {
    await start();
    await stop();
  });
});

