pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
/*
Just the regular variation with 4 colors and 4 holes
*/
template MastermindVariation() {
    // Public inputs
    signal input pubGuessA;
    signal input pubGuessB;
    signal input pubGuessC;
    signal input pubGuessD;
    signal input pubNumRedPins;
    signal input pubNumWhitePins;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnA;
    signal input privSolnB;
    signal input privSolnC;
    signal input privSolnD;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[4] = [pubGuessA, pubGuessB, pubGuessC, pubGuessD];
    var soln[4] =  [privSolnA, privSolnB, privSolnC, privSolnD];

    var j = 0;
    var k = 0;
    component lessThan[8];

    // Create a constraint that the solution and guess digits are all less than 4 (between 0 and 3 included)
    for (j=0; j<4; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 4;
        lessThan[j].out === 1;
        lessThan[j+4] = LessThan(4);
        lessThan[j+4].in[0] <== soln[j];
        lessThan[j+4].in[1] <== 4;
        lessThan[j+4].out === 1;
    }

    // Count red & white pins
    var redPins = 0;
    var whitePins = 0;
    component isEqual[16];

    for (j=0; j<4; j++) {
        for (k=0; k<4; k++) {
            isEqual[4*j+k] = IsEqual();
            isEqual[4*j+k].in[0] <== soln[j];
            isEqual[4*j+k].in[1] <== guess[k];
            whitePins += isEqual[4*j+k].out;
            if (j == k) {
                redPins += isEqual[4*j+k].out;
                whitePins -= isEqual[4*j+k].out;
            }
        }
    }

    // Create a constraint on red pins
    component equalHit = IsEqual();
    equalHit.in[0] <== pubNumRedPins;
    equalHit.in[1] <== redPins;
    equalHit.out === 1;
    
    // Create a constraint on white pins
    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubNumWhitePins;
    equalBlow.in[1] <== whitePins;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(5);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnA;
    poseidon.inputs[2] <== privSolnB;
    poseidon.inputs[3] <== privSolnC;
    poseidon.inputs[4] <== privSolnD;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
}

component main = MastermindVariation();