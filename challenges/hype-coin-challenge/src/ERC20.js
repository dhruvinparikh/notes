import { Web3Provider } from '@ethersproject/providers';
import { useState, useEffect } from 'react';
import './ERC20.css';

async function getRemainingSupply(provider) {
  // TODO: fill in code here to get the remaining supply of the Hype Coin token.
  // This is the balance of the wallet that deployed the Hype Coin contract
  return "TODO";
}

async function getBalance(provider, address) {
  // TODO: fill in code here to get the balance of the Hype Coin token for the connected wallet
  return "TODO";
}


function ERC20(props) {
  const [remainingSupply, setRemainingSupply] = useState(null);
  const [balance, setBalance] = useState(null);
  const provider = new Web3Provider(window.ethereum);

  async function refreshStats() {
    if (props.address) {
      setRemainingSupply(await getRemainingSupply(provider));
      setBalance(await getBalance(provider, props.address));
    }
  }

  useEffect(() => {
    refreshStats();
  }, [props.address]);

  return (
    <div className="ERC20">
      <h2>Hype Coin</h2>
      <div>Hype Coin remaining supply: {remainingSupply} HC</div>
      <div>Hype Coin wallet balance: {balance} HC</div>
    </div>
  );
}

export default ERC20;
