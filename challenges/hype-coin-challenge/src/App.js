import './App.css';
import { useState, useEffect } from 'react';
import ERC20 from './ERC20';
import ERC721 from './ERC721';

async function connectToMetamask(setAddress) {
  const accounts = await window.ethereum.request({
    method: 'eth_requestAccounts',
  });
  setAddress(accounts[0]);
}

function App() {
  const [address, setAddress] = useState(null);

  useEffect(() => {
    connectToMetamask(setAddress);
  }, []);

  useEffect(() => {
    window.ethereum.on('accountsChanged', () => {
      connectToMetamask(setAddress);
    });
  }, []);

  return (
    <div className="App">
      <h1>Hype Coin App</h1>
      {address ?
        <div>Connected to {address}</div> :
        <button onClick={async () => await connectToMetamask(setAddress)}>Connect to Metamask</button>
      }
      <ERC20 address={address}/>
      <ERC721 address={address}/>
    </div>
  );
}

export default App;
