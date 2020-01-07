include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "../node_modules/circomlib/circuits/eddsamimcsponge.circom";

template Transaction(maxSignatures) {
  signal input state;
  signal input txHash;

  // state members
  signal private input minSignatures;
  signal private input pubkeys[maxSignatures][2];
  signal private input pubkeyMap[maxSignatures];

  signal private input signatures[maxSignatures][3];

  // Verify state
  component stateHasher = MiMCSponge(1 + 3 * maxSignatures, 1);
  stateHasher.k <== 0;
  stateHasher.ins[0] <== minSignatures;
  signal sigCount;
  for(var i = 0; i<maxSignatures; i++) {
    stateHasher.ins[1 + i] === pubkeys[i][0];
    stateHasher.ins[1 + i + maxSignatures] === pubkeys[i][1];
    stateHasher.ins[1 + i + 2 * maxSignatures] === pubkeyMap[i];
    pubkeyMap[i] * (1 - pubkeyMap[i]) === 0;
    sigCount += pubkeyMap[i];
  }
  state === stateHasher.outs[0];
  sigCount === minSignatures;

	// Verify signatures
  component sig_verifier[maxSignatures];
  for(var i = 0; i<maxSignatures; i++) {
    sig_verifier[i] = EdDSAMiMCSpongeVerifier();
    sig_verifier[i].enabled <== pubkeyMap[i];
    sig_verifier[i].Ax <== pubkeys[i][0];
    sig_verifier[i].Ay <== pubkeys[i][1];
    sig_verifier[i].R8x <== signatures[i][0];
    sig_verifier[i].R8y <== signatures[i][1];
    sig_verifier[i].S <== signatures[i][2];
    sig_verifier[i].M <== txHash;
  }
}

component main = Transaction(4);