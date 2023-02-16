import { Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";
import { fromB64, toB64 } from '@mysten/bcs';
import React, { useState } from "react";

const SignInButton = () => {
  const [keyPair, setKeyPair] = useState(() => {
    // Check if keyPair exists in local storage
    const storedKeyPair = localStorage.getItem("keyPair");  
    const storedKeyPairSui = localStorage.getItem("keyPairSui");  
    console.log(storedKeyPair)
    console.log(JSON.parse(storedKeyPairSui))
    // If keyPair exists, parse and return it
    if (storedKeyPair) {

      return JSON.parse(storedKeyPair);
    }

    // Otherwise, return null
    return null;
  });
  const generateKeyPair = () => {
    // Generate the keypair here
    const keypairSui = new Ed25519Keypair();
    console.log(keypairSui)
    console.log(toB64(keypairSui.getPublicKey()))
    const privateKey = "abc123";
    const publicKey = "def456";
    // Store the keypair in local storage
    localStorage.setItem("keyPair", JSON.stringify({ privateKey, publicKey }));
    localStorage.setItem("keyPairSui", JSON.stringify(keypairSui));

    // Set the keypair state
    setKeyPair({ privateKey, publicKey });
    console.log("asdfa", keyPair)
  };
  return (
    <div>
      {keyPair ? (
        <p>Public Key: {keyPair.publicKey}</p>
      ) : (
        <button className="signin-button" onClick={generateKeyPair}>Sign In</button>
      )}
    </div>
  );
};

export default SignInButton;
