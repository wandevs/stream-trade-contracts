const FakeErc20 = artifacts.require('FakeErc20');
const Layer2BridgeDelegate = artifacts.require('Layer2BridgeDelegate');

const assert = require('assert');

contract("Layer2BridgeDelegate", accounts => {
  let delegate;
  let token;
  beforeEach(async ()=>{
    token = await FakeErc20.new('MOO', 'MOO');
    await token.mint(accounts[0], 1000000);
    await token.mint(accounts[1], 1000000);
    await token.mint(accounts[2], 1000000);

    delegate = await Layer2BridgeDelegate.new();
    await delegate.initialize(accounts[0], token.address);
    await token.approve(delegate.address, 0xfffffffffffff, {from: accounts[0]});
    await token.approve(delegate.address, 0xfffffffffffff, {from: accounts[1]});
    await token.approve(delegate.address, 0xfffffffffffff, {from: accounts[2]});
  });

  it("should success stake", async () => {
    await delegate.stake(100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '900000', 1);

    await delegate.stake(100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '800000', 2);

    await delegate.stake(100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '700000', 3);

    await delegate.stake(1000000, {from: accounts[1]});
    assert.strictEqual((await token.balanceOf(accounts[1])).toString(), '0', 4);

    await delegate.stake(1000000, {from: accounts[2]});
    assert.strictEqual((await token.balanceOf(accounts[2])).toString(), '0', 5);
  });

  it("should success withdraw", async () => {
    await delegate.stake(1000000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '0', 6);

    await delegate.withdraw(500000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '500000', 7);

    await delegate.withdraw(500000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[0])).toString(), '1000000', 8);

  });

  it("should success mint", async () => {
    await delegate.stake(1000000, {from: accounts[2]});
    assert.strictEqual((await token.balanceOf(accounts[2])).toString(), '0', 9);

    await delegate.mint(accounts[1], 100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[1])).toString(), '1100000', 10);
  });

  it("should success mint", async () => {
    await delegate.burn(accounts[1], 100000, {from: accounts[0]});
    assert.strictEqual((await token.balanceOf(accounts[1])).toString(), '900000', 11);
  });

  it("should get info", async () => {
    await delegate.stake(100000, {from: accounts[0]});
    await delegate.stake(100000, {from: accounts[1]});
    await delegate.stake(100000, {from: accounts[2]});
    assert.strictEqual((await delegate.totalStaked()).toString(), '300000', 12);

    assert.strictEqual((await delegate.getStakerAmount(accounts[0])).toString(), '100000', 13);

    assert.strictEqual((await delegate.getStakersCount()).toString(), '3', 14);

    let count = Number(await delegate.getStakersCount());
    console.log(await delegate.getStakers(0, count));
    console.log(await delegate.name());
    console.log(await delegate.symbol());
    console.log(await delegate.decimals());
    console.log(await delegate.totalSupply());
    console.log(await delegate.balanceOf(accounts[0]));

  });

});

