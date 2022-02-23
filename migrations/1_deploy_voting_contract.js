var Web3 = require("web3");
var Voting = artifacts.require("Voting");

const web3 = new Web3("http://localhost:7545");
let proposalsArray = ["Tenten", "Infinity", "Tobino"];
let proposalsArrayBytes32 = [];

for (let i of proposalsArray) {
  const e = proposalsArray[i];

  proposalsArrayBytes32.push(
    web3.utils.hexToBytes(web3.utils.padLeft(web3.utils.asciiToHex(e), 64))
  );
}

const args = {};
args._proposals = proposalsArrayBytes32;
args._start_time = Date.now().toString();
args._voting_duration = Date.now().toString() + 1000;
args._allow_delegation = true;
args._registeration_duration = Date.now() + 100;

module.exports = function (deployer) {
  deployer.deploy(Voting, ...Object.values(args));
};
