const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function () {
  let Voting, voting, owner, addr1, addr2;

  beforeEach(async function () {
    Voting = await ethers.getContractFactory("Voting");
    [owner, addr1, addr2] = await ethers.getSigners();
    voting = await Voting.deploy();
    await voting.deployed();
  });

  it("Should allow only admin to create an election", async function () {
    await voting.createElection("Test Election", "QmFakeIPFSHash", ["Alice", "Bob"]);
    await expect(
      voting.connect(addr1).createElection("Election 2", "QmFakeIPFSHash2", ["Eve", "Mallory"])
    ).to.be.revertedWith("Only admin can call this function");
  });

  it("Should open and close elections", async function () {
    await voting.createElection("Test Election", "QmFakeIPFSHash", ["Alice", "Bob"]);
    await voting.openElection(0);
    let election = await voting.getElection(0);
    expect(election[2]).to.equal(1); // ElectionStatus.Open
    await voting.closeElection(0);
    election = await voting.getElection(0);
    expect(election[2]).to.equal(2); // ElectionStatus.Closed
  });

  it("Should allow voting only when open", async function () {
    await voting.createElection("Test Election", "QmFakeIPFSHash", ["Alice", "Bob"]);
    await expect(voting.connect(addr1).vote(0, "Alice")).to.be.revertedWith("Election not open");
    await voting.openElection(0);
    await voting.connect(addr1).vote(0, "Alice");
    const votes = await voting.getVotes(0, "Alice");
    expect(votes).to.equal(1);
    await expect(voting.connect(addr1).vote(0, "Bob")).to.be.revertedWith("Already voted");
  });

  it("Should not allow invalid candidates", async function () {
    await voting.createElection("Test Election", "QmFakeIPFSHash", ["Alice", "Bob"]);
    await voting.openElection(0);
    await expect(voting.connect(addr2).vote(0, "Charlie")).to.be.revertedWith("Invalid candidate");
  });

  it("Should retrieve all votes for off-chain analytics", async function () {
    await voting.createElection("Test Election", "QmFakeIPFSHash", ["Alice", "Bob"]);
    await voting.openElection(0);
    await voting.connect(addr1).vote(0, "Alice");
    await voting.connect(addr2).vote(0, "Bob");
    const [names, counts] = await voting.getAllVotes(0);
    expect(names[0]).to.equal("Alice");
    expect(names[1]).to.equal("Bob");
    expect(counts[0]).to.equal(1);
    expect(counts[1]).to.equal(1);
  });
});