import { Web3Provider } from '@ethersproject/providers';
import { useState, useEffect } from 'react';
import './ERC721.css';

async function getNftIds(provider, address) {
  // TODO: fill in code here to get the NFT IDs owned by the address
  return [];
}

async function getBalance(provider, address) {
  // TODO: fill in code here to get the number of Hype NFTs owned by the address
  return -1;
}

async function getNextId(provider) {
  // TODO: fill in code here to get the next available NFT ID
  return -1;
}


function ERC721(props) {
  const [nftIds, setNftIds] = useState([]);
  const [balance, setBalance] = useState(null);
  const [nextId, setNextId] = useState(null);
  const provider = new Web3Provider(window.ethereum);

  async function refreshStats() {
    if (props.address) {
      setNftIds(await getNftIds(provider, props.address));
      setBalance(await getBalance(provider, props.address));
      setNextId(await getNextId(provider));
    }
  }

  useEffect(() => {
    refreshStats();
  }, [props.address]);

  return (
    <div className="ERC721">
      <h2>Hype NFT</h2>
      <div>NFT Count: {balance}</div>
      <div>NFT IDs: {nftIds.length === 0 ? "None" : nftIds.join(", ")}</div>
      <div>Next available ID: {nextId}</div>
    </div>
  );
}

export default ERC721;
