const CommonProxy = artifacts.require('CommonProxy');
const Layer2BridgeDelegate = artifacts.require('Layer2BridgeDelegate');

const assert = require('assert');

contract("CommonProxy", accounts => {
  let proxy;
  let delegate;
  let delegate2;

  beforeEach(async ()=>{
    delegate = await Layer2BridgeDelegate.new();
    delegate2 = await Layer2BridgeDelegate.new();
    proxy = await CommonProxy.new(delegate.address, accounts[1], '0x');
  });

  it("should success when upgrade", async () => {
    await proxy.upgradeTo(delegate2.address, {from: accounts[1]});
  });

  it("should failed when upgrade without access", async () => {
    try {
      await proxy.upgradeTo(delegate2.address, {from: accounts[0]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should success when changeAdmin", async () => {
    await proxy.changeAdmin(accounts[2], {from: accounts[1]});

  });

  it("should failed when changeAdmin without access", async () => {

    try {
      await proxy.changeAdmin(accounts[2], {from: accounts[3]});

      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });

  it("should failed when call to delegate function without access", async () => {
    try {
      const zoo = await Layer2BridgeDelegate.at(proxy.address);
      await zoo.initialize(accounts[0], accounts[5], {from: accounts[1]});
      assert.fail('never go here');
    } catch (e) {
      assert.ok(e.message.match(/revert/));
    }
  });
});

