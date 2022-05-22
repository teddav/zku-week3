//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const { buildPoseidon } = require("circomlibjs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { groth16 } = require("snarkjs");




describe("MastermindVariation", function () {
    let mastermind;

    beforeEach(async function () {
        const verifier = await ethers.getContractFactory("Verifier");
        mastermind = await verifier.deploy();
        await mastermind.deployed();
    });

    it("Play", async function () {
        const poseidon = await buildPoseidon();
        const solution = [0,1,2,3];

        const salt = Math.floor(Math.random() * 1e6)
        const solutionHash = poseidon.F.toObject(poseidon([salt, ...solution]));
        
        const guess = [0,1,2,3];

        const Input = {
            "pubGuessA": guess[0],
            "pubGuessB": guess[1],
            "pubGuessC": guess[2],
            "pubGuessD": guess[3],
            "pubNumRedPins": 4,
            "pubNumWhitePins": 0,
            "pubSolnHash": solutionHash,
            "privSolnA": solution[0],
            "privSolnB": solution[1],
            "privSolnC": solution[2],
            "privSolnD": solution[3],
            "privSalt": salt
        }

        const { proof, publicSignals } = await groth16.fullProve(Input, "contracts/circuits/MastermindVariation_js/MastermindVariation.wasm","contracts/circuits/circuit_final.zkey");

        expect(await mastermind.verifyProof(proof.pi_a.slice(0, 2), [proof.pi_b[0].slice(0).reverse(),proof.pi_b[1].slice(0).reverse()], proof.pi_c.slice(0, 2), publicSignals)).to.be.true;
    });
});