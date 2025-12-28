import React, { useState, useEffect, useCallback } from 'react';
import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom';
import { ethers } from 'ethers';
import { getAddresses, getAbis, updateContractConfig, storeData, getData } from './contractConfig';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import firebase from 'firebase/compat/app';
import 'firebase/compat/auth';
import 'firebase/compat/firestore';
import './styles.css';
import logo from './images/GoateElectricLogo.jpg';
import backgroundImage1 from './images/background-image1.jpg';
import backgroundImage2 from './images/background-image2.jpg';
import { initializeOfflineModem, syncOfflineData } from './offline';
import UtilitiesPage from './UtilitiesPage';
import DeFiPage from './DeFiPage';
import EntertainmentPage from './EntertainmentPage';
import SettingsPage from './SettingsPage';

const firebaseConfig = {
  apiKey: "AIzaSyA9QXX-a-XbR8xjosRPZIH2VIyaL-etu9s",
  authDomain: "goate-electric.firebaseapp.com",
  projectId: "goate-electric",
  storageBucket: "goate-electric.appspot.com",
  messagingSenderId: "614092317702",
  appId: process.env.REACT_APP_FIREBASE_APP_ID
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

const App = () => {
  const [provider, setProvider] = useState(null);
  const [account, setAccount] = useState('');
  const [balances, setBalances] = useState({
    ZPE: { amount: 0, usd: 0 },
    ZPP: { amount: 0, usd: 0 },
    ZPW: { amount: 0, usd: 0 },
    BTC: { amount: 0, usd: 0 },
    USD: { amount: 0, usd: 0 },
    PI: { amount: 0, usd: 0 },
    GOATE: { amount: 0, usd: 0 },
    ZGI: { amount: 0, usd: 0 }
  });
  const [devices, setDevices] = useState([]);
  const [user, setUser] = useState(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [pin, setPin] = useState('');
  const [username, setUsername] = useState('');
  const [loading, setLoading] = useState(false);
  const [modemStatus, setModemStatus] = useState(false);
  const [transactions, setTransactions] = useState([]);
  const [pinPrompt, setPinPrompt] = useState({ show: false, callback: null });

  const usdPrices = {
    ZPE: 0.1,
    ZPP: 5,
    ZPW: 1,
    ZGI: 6
  };

  const OWNER_ADDRESS = '0x...'; // Replace with cj03nes address

  useEffect(() => {
    const init = async () => {
      setLoading(true);
      await initializeOfflineModem();
      await updateContractConfig();
      if (window.ethereum) {
        const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        setProvider(web3Provider);
        const accounts = await web3Provider.listAccounts();
        setAccount(accounts[0]);
        await fetchBalances(accounts[0]);
        await fetchDevices(accounts[0]);
        await fetchUserData(accounts[0]);
        await fetchTransactions(accounts[0]);
      }
      firebase.auth().onAuthStateChanged((user) => {
        setUser(user);
        if (user && accounts[0]) fetchUserData(accounts[0]);
        setLoading(false);
      });
    };
    init();

    // Auto-refresh balances every 0.2s if modem is active
    const interval = setInterval(() => {
      if (modemStatus && account) fetchBalances(account);
    }, 200);
    return () => clearInterval(interval);
  }, [account, modemStatus]);

  const fetchBalances = useCallback(async (user) => {
    const cachedBalances = await getData(`balances_${user}`);
    if (cachedBalances && !navigator.onLine) {
      setBalances(JSON.parse(cachedBalances));
      toast.info('Loaded cached balances (offline)');
      return;
    }
    try {
      const contract = new ethers.Contract(
        getAddresses().InstilledInteroperability,
        getAbis().InstilledInteroperability,
        provider
      );
      const assets = ['ZPE', 'ZPP', 'ZPW', 'BTC', 'USD', 'PI', 'GOATE', 'ZGI'];
      const newBalances = {};
      for (let asset of assets) {
        const balance = await contract.getBalance(user, asset);
        const amount = ethers.utils.formatUnits(balance, 18);
        const price = asset in usdPrices ? usdPrices[asset] : await getDynamicPrice(asset);
        newBalances[asset] = {
          amount: parseFloat(amount).toFixed(4),
          usd: (parseFloat(amount) * price).toFixed(2)
        };
      }
      setBalances(newBalances);
      await storeData(`balances_${user}`, JSON.stringify(newBalances));
      if (navigator.onLine) syncOfflineData();
    } catch (error) {
      console.error('Error fetching balances:', error);
      toast.error('Failed to fetch balances');
    }
  }, [provider]);

  const getDynamicPrice = async (asset) => {
    try {
      const contract = new ethers.Contract(
        getAddresses().InstilledInteroperability,
        getAbis().InstilledInteroperability,
        provider
      );
      const price = await contract.getPrice(asset);
      return ethers.utils.formatUnits(price, 18);
    } catch (error) {
      console.error(`Error fetching ${asset} price:`, error);
      return 0;
    }
  };

  const fetchDevices = async (user) => {
    const cachedDevices = await getData(`devices_${user}`);
    if (cachedDevices && !navigator.onLine) {
      setDevices(JSON.parse(cachedDevices));
      toast.info('Loaded cached devices (offline)');
      return;
    }
    try {
      const contract = new ethers.Contract(
        getAddresses().DeviceConnect,
        getAbis().DeviceConnect,
        provider.getSigner()
      );
      const deviceList = await contract.getUserDevices(user);
      setDevices(deviceList);
      await storeData(`devices_${user}`, JSON.stringify(deviceList));
    } catch (error) {
      console.error('Error fetching devices:', error);
      toast.error('Failed to fetch devices');
    }
  };

  const connectDevice = async () => {
    setLoading(true);
    try {
      const contract = new ethers.Contract(
        getAddresses().DeviceConnect,
        getAbis().DeviceConnect,
        provider.getSigner()
      );
      const deviceId = `device_${Math.random().toString(36).slice(2)}`;
      const tx = await contract.connectDevice(deviceId, account);
      await tx.wait();
      await fetchDevices(account);
      toast.success('Device connected successfully');
    } catch (error) {
      console.error('Error connecting device:', error);
      toast.error('Failed to connect device');
    }
    setLoading(false);
  };

  const fetchUserData = async (user) => {
    const cachedData = await getData(`userData_${user}`);
    if (cachedData && !navigator.onLine) {
      const data = JSON.parse(cachedData);
      setUsername(data.username || '');
      setPin(data.pin || '');
      toast.info('Loaded cached user data (offline)');
      return;
    }
    try {
      const doc = await db.collection('users').doc(user).get();
      const contract = new ethers.Contract(
        getAddresses().DataStorage,
        getAbis().DataStorage,
        provider
      );
      const onChainUsername = await contract.addressToUsername(user);
      const data = { firebase: doc.exists ? doc.data() : {}, onChain: { username: onChainUsername } };
      setUsername(onChainUsername);
      setPin(doc.exists ? doc.data().pin || '' : '');
      await storeData(`userData_${user}`, JSON.stringify({ ...data.firebase, username: onChainUsername }));
      await db.collection('users').doc(user).set({ username: onChainUsername, wallet: user }, { merge: true });
    } catch (error) {
      console.error('Error fetching user data:', error);
      toast.error('Failed to fetch user data');
    }
  };

  const fetchTransactions = async (user) => {
    const cachedTxs = await getData(`transactions_${user}`);
    if (cachedTxs && !navigator.onLine) {
      setTransactions(JSON.parse(cachedTxs));
      toast.info('Loaded cached transactions (offline)');
      return;
    }
    try {
      const contract = new ethers.Contract(
        getAddresses().GhostTransactions,
        getAbis().GhostTransactions,
        provider
      );
      const filter = contract.filters.TransferSigned(user, null, null, null, null, null, null);
      const events = await contract.queryFilter(filter);
      const txs = events.map((event) => ({
        hash: event.transactionHash,
        from: event.args[0],
        to: event.args[1],
        token: event.args[2],
        amount: ethers.utils.formatUnits(event.args[3], 18),
        usernameFrom: event.args[5],
        usernameTo: event.args[6],
        timestamp: event.args[7].toNumber(),
        status: Math.random() > 0.9 ? 'failed' : Math.random() > 0.7 ? 'pending' : event.args[2] === 'PI' || event.args[2] === 'BTC' ? 'cross-chain' : 'success'
      }));
      setTransactions(txs);
      await storeData(`transactions_${user}`, JSON.stringify(txs));
    } catch (error) {
      console.error('Error fetching transactions:', error);
      toast.error('Failed to fetch transactions');
    }
  };

  const signTransfer = async (to, token, amount, usernameTo) => {
    if (!to || !amount || !usernameTo) return toast.error('All fields required');
    setPinPrompt({
      show: true,
      callback: async (enteredPinOrPassword) => {
        setLoading(true);
        try {
          const contract = new ethers.Contract(
            getAddresses().GhostTransactions,
            getAbis().GhostTransactions,
            provider.getSigner()
          );
          if (enteredPinOrPassword.length > 4) {
            await firebase.auth().signInWithEmailAndPassword(firebase.auth().currentUser.email, enteredPinOrPassword);
          } else {
            const tx = await contract.verifyPin(enteredPinOrPassword);
            await tx.wait();
          }
          const parsedAmount = ethers.utils.parseUnits(amount, 18);
          const tx = await contract.signTransfer(to, token, parsedAmount, enteredPinOrPassword, username, usernameTo);
          await tx.wait();
          await fetchBalances(account);
          await fetchTransactions(account);
          toast.success('Transfer signed successfully');
        } catch (error) {
          console.error('Error signing transfer:', error);
          toast.error('Failed to sign transfer');
        }
        setPinPrompt({ show: false, callback: null });
        setLoading(false);
      }
    });
  };

  const registerUsername = async () => {
    if (!username) return toast.error('Username required');
    setLoading(true);
    try {
      const contract = new ethers.Contract(
        getAddresses().DataStorage,
        getAbis().DataStorage,
        provider.getSigner()
      );
      const tx = await contract.registerUsername(username);
      await tx.wait();
      await fetchUserData(account);
      toast.success('Username registered successfully');
    } catch (error) {
      console.error('Error registering username:', error);
      toast.error('Failed to register username');
    }
    setLoading(false);
  };

  const setUserPin = async () => {
    if (!pin || pin.length !== 4) return toast.error('4-digit PIN required');
    setLoading(true);
    try {
      const contract = new ethers.Contract(
        getAddresses().GhostTransactions,
        getAbis().GhostTransactions,
        provider.getSigner()
      );
      const tx = await contract.setPin(pin);
      await tx.wait();
      await db.collection('users').doc(account).set({ pin }, { merge: true });
      await storeData(`userData_${account}`, JSON.stringify({ pin, username }));
      toast.success('PIN set successfully');
    } catch (error) {
      console.error('Error setting PIN:', error);
      toast.error('Failed to set PIN');
    }
    setLoading(false);
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await firebase.auth().signInWithEmailAndPassword(email, password);
      await db.collection('users').doc(account).set({ email, wallet: account }, { merge: true });
      toast.success('Logged in successfully');
    } catch (error) {
      console.error('Login error:', error);
      toast.error(`Login failed: ${error.message}`);
    }
    setLoading(false);
  };

  const handleSignUp = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await firebase.auth().createUserWithEmailAndPassword(email, password);
      await db.collection('users').doc(account).set({ email, wallet: account });
      toast.success('Signed up successfully');
    } catch (error) {
      console.error('Sign up error:', error);
      toast.error(`Sign up failed: ${error.message}`);
    }
    setLoading(false);
  };

  const handleSocialLogin = async (providerName) => {
    setLoading(true);
    let authProvider;
    switch (providerName) {
      case 'google':
        authProvider = new firebase.auth.GoogleAuthProvider();
        break;
      case 'microsoft':
        authProvider = new firebase.auth.OAuthProvider('microsoft.com');
        break;
      case 'twitter':
        authProvider = new firebase.auth.TwitterAuthProvider();
        break;
      default:
        setLoading(false);
        return;
    }
    try {
      const result = await firebase.auth().signInWithPopup(authProvider);
      await db.collection('users').doc(account).set(
        { email: result.user.email, wallet: account },
        { merge: true }
      );
      toast.success(`Logged in with ${providerName}`);
    } catch (error) {
      console.error(`${providerName} login error:`, error);
      toast.error(`Failed to login with ${providerName}`);
    }
    setLoading(false);
  };

  const handleLogout = async () => {
    setLoading(true);
    try {
      await firebase.auth().signOut();
      setUser(null);
      setEmail('');
      setPassword('');
      setPin('');
      toast.success('Logged out successfully');
    } catch (error) {
      console.error('Logout error:', error);
      toast.error('Failed to logout');
    }
    setLoading(false);
  };

  const handlePinSubmit = (e) => {
    e.preventDefault();
    if (pinPrompt.callback) pinPrompt.callback(pin);
    setPin('');
  };

  const timestamp = new Date().toLocaleString();

  return (
    <BrowserRouter>
      <div
        className="min-h-screen font-sans"
        style={{
          backgroundImage: `url(${user ? backgroundImage2 : backgroundImage1})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundAttachment: 'fixed'
        }}
      >
        <header className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-4 bg-black border-b-2 border-gold">
          <div className="flex items-center space-x-4">
            <img src={logo} alt="Goate Electric Logo" className="h-12 w-12 object-contain" />
            <h1 className="text-2xl font-bold text-gold">Goate Electric</h1>
          </div>
          <div className="flex items-center space-x-4">
            {user ? (
              <>
                <p className="text-gold text-sm font-medium">{username || user.email}</p>
                <button
                  className="bg-gold text-black px-4 py-2 rounded-lg hover:bg-yellow-400 transition"
                  onClick={connectDevice}
                >
                  Connect Device
                </button>
                <NavLink
                  to="/settings"
                  className="bg-gold text-black px-4 py-2 rounded-lg hover:bg-yellow-400 transition"
                >
                  Settings
                </NavLink>
                <button
                  className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-500 transition"
                  onClick={handleLogout}
                >
                  Logout
                </button>
              </>
            ) : (
              <>
                <form onSubmit={handleLogin} className="flex space-x-2">
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="Email"
                    className="bg-gray-900 text-gold p-2 rounded-lg focus:outline-none"
                  />
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Password"
                    className="bg-gray-900 text-gold p-2 rounded-lg focus:outline-none"
                  />
                  <button
                    type="submit"
                    className="bg-gold text-black px-4 py-2 rounded-lg hover:bg-yellow-400 transition"
                  >
                    Login
                  </button>
                  <button
                    type="button"
                    onClick={handleSignUp}
                    className="bg-gold text-black px-4 py-2 rounded-lg hover:bg-yellow-400 transition"
                  >
                    Sign Up
                  </button>
                </form>
                {['google', 'microsoft', 'twitter'].map((p) => (
                  <button
                    key={p}
                    className="bg-gold text-black px-4 py-2 rounded-lg hover:bg-yellow-400 transition"
                    onClick={() => handleSocialLogin(p)}
                  >
                    {p === 'twitter' ? 'X' : p.charAt(0).toUpperCase() + p.slice(1)}
                  </button>
                ))}
              </>
            )}
          </div>
        </header>
        {loading && (
          <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
            <div className="text-gold text-xl">Loading...</div>
          </div>
        )}
        {pinPrompt.show && (
          <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
            <div className="bg-gray-900 p-6 rounded-lg shadow-lg">
              <h2 className="text-xl mb-2 text-gold">Enter PIN or Password</h2>
              <form onSubmit={handlePinSubmit}>
                <input
                  type="password"
                  value={pin}
                  onChange={(e) => setPin(e.target.value)}
                  placeholder="PIN or Password"
                  className="bg-gray-900 text-gold p-2 rounded-lg w-full mb-2 focus:outline-none"
                />
                <div className="flex space-x-2">
                  <button
                    type="submit"
                    className="bg-gold text-black px-4 py-2 rounded-lg hover:bg-yellow-400 transition"
                  >
                    Submit
                  </button>
                  <button
                    type="button"
                    className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-500 transition"
                    onClick={() => setPinPrompt({ show: false, callback: null })}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
        <main className="pt-20 pb-8 px-4 flex flex-col items-center min-h-screen">
          <div className="bg-gray-900 p-6 rounded-lg shadow-lg w-full max-w-2xl mb-8">
            <h2 className="text-xl font-bold text-gold mb-4 text-center">Balances</h2>
            <div className="grid grid-cols-2 gap-4">
              {Object.entries(balances).map(([asset, { amount, usd }]) => (
                <div key={asset} className="bg-gray-800 p-4 rounded-lg text-center">
                  <p className="text-lg font-semibold text-gold">{asset}</p>
                  <p className="text-gold">{amount} (${usd} USD)</p>
                </div>
              ))}
            </div>
          </div>
          <div className="flex justify-center gap-4 mb-8">
            {['Utilities', 'Entertainment', 'DeFi'].map((section) => (
              <NavLink
                key={section}
                to={`/${section.toLowerCase()}`}
                className="bg-gray-900 text-gold px-6 py-3 rounded-lg hover:bg-gray-800 transition text-center w-40"
              >
                Goate {section}
              </NavLink>
            ))}
          </div>
          <div className="w-full max-w-4xl bg-gray-900 p-6 rounded-lg border-2 border-gold">
            <h2 className="text-xl font-bold text-gold mb-4 text-center">Transaction History</h2>
            {transactions.length === 0 ? (
              <p className="text-gold text-center">No transactions yet.</p>
            ) : (
              transactions.map((tx, index) => (
                <div
                  key={index}
                  className={`border-l-4 p-4 mb-2 rounded-r-lg ${
                    tx.status === 'success'
                      ? 'border-green-500 bg-green-500/10'
                      : tx.status === 'failed'
                      ? 'border-red-500 bg-red-500/10'
                      : tx.status === 'pending'
                      ? 'border-blue-500 bg-blue-500/10'
                      : 'border-yellow-500 bg-yellow-500/10'
                  }`}
                >
                  <p>
                    <span className="text-gold">Hash: </span>
                    <a
                      href={`https://sepolia.etherscan.io/tx/${tx.hash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-gold underline hover:text-yellow-400"
                    >
                      {tx.hash.slice(0, 10)}...
                    </a>
                  </p>
                  <p>
                    <span className="text-gold">From: </span>
                    {tx.usernameFrom || tx.from.slice(0, 6) + '...' + tx.from.slice(-4)}
                  </p>
                  <p>
                    <span className="text-gold">To: </span>
                    {tx.usernameTo || tx.to.slice(0, 6) + '...' + tx.to.slice(-4)}
                  </p>
                  <p>
                    <span className="text-gold">Token: </span>
                    {tx.token}
                  </p>
                  <p>
                    <span className="text-gold">Amount: </span>
                    {tx.amount}
                  </p>
                  <p>
                    <span className="text-gold">Status: </span>
                    <span
                      className={
                        tx.status === 'success'
                          ? 'text-green-500'
                          : tx.status === 'failed'
                          ? 'text-red-500'
                          : tx.status === 'pending'
                          ? 'text-blue-500'
                          : 'text-yellow-500'
                      }
                    >
                      {tx.status.charAt(0).toUpperCase() + tx.status.slice(1)}
                    </span>
                  </p>
                  <p>
                    <span className="text-gold">Time: </span>
                    {new Date(tx.timestamp * 1000).toLocaleString()}
                  </p>
                </div>
              ))
            )}
          </div>
          <footer className="text-center mt-8 text-sm text-gold">
            Last Updated: {timestamp}
          </footer>
        </main>
        <Routes>
          <Route
            path="/utilities"
            element={
              <UtilitiesPage
                account={account}
                devices={devices}
                fetchDevices={fetchDevices}
                balances={balances}
                modemStatus={modemStatus}
                toggleModem={(status) => setModemStatus(status)}
                provider={provider}
              />
            }
          />
          <Route
            path="/defi"
            element={
              <DeFiPage
                account={account}
                balances={balances}
                fetchBalances={fetchBalances}
                signTransfer={signTransfer}
                provider={provider}
                username={username}
              />
            }
          />
          <Route
            path="/entertainment"
            element={<EntertainmentPage account={account} balances={balances} provider={provider} />}
          />
          <Route
            path="/settings"
            element={
              <SettingsPage
                account={account}
                provider={provider}
                username={username}
                setUsername={setUsername}
                fetchUserData={fetchUserData}
              />
            }
          />
        </Routes>
        <ToastContainer position="top-right" autoClose={3000} />
      </div>
    </BrowserRouter>
  );
};

export default App;


----------------

@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  padding: 0;
  font-family: 'Arial', sans-serif;
  overflow-x: hidden;
}

header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 50;
  background-color: #000;
  border-bottom: 2px solid #FFD700;
}

main {
  padding-top: 80px; /* Adjust for fixed header height */
  min-height: calc(100vh - 80px);
  display: flex;
  flex-direction: column;
  align-items: center;
}

.bg-gray-900 {
  background-color: #1a1a1a;
}

.text-gold {
  color: #FFD700;
}

.bg-gold {
  background-color: #FFD700;
}

.bg-gray-800 {
  background-color: #2d2d2d;
}

.transition {
  transition: all 0.2s ease-in-out;
}

button, a {
  transition: background-color 0.2s ease-in-out;
}

/* Ensure header doesn't resize on zoom */
@media (min-width: 0px) {
  header {
    transform: none !important;
    transform-origin: none !important;
  }
}
-----------------------
import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { getAddresses, getAbis } from './contractConfig';
import { ToastContainer, toast } from 'react-toastify';

const EntertainmentPage = ({ account, balances, provider }) => {
  const [gameState, setGameState] = useState({
    CardWars: { score: 0, active: false },
    Spades: { score: 0, active: false },
    HomeTeamBets: { bet: 0, active: false },
    GerastyxOpol: { dice: 0, active: false }
  });
  const [loading, setLoading] = useState(false);

  const playGame = async (gameName) => {
    setLoading(true);
    try {
      const contractAddress = getAddresses()[gameName];
      const contractAbi = getAbis()[gameName];
      const contract = new ethers.Contract(contractAddress, contractAbi, provider.getSigner());

      let tx;
      if (gameName === 'CardWars') {
        tx = await contract.playCard(ethers.utils.parseUnits('1', 18)); // Mock play
        await tx.wait();
        setGameState((prev) => ({ ...prev, CardWars: { score: prev.CardWars.score + 1, active: true } }));
      } else if (gameName === 'Spades') {
        tx = await contract.bid(ethers.utils.parseUnits('1', 18));
        await tx.wait();
        setGameState((prev) => ({ ...prev, Spades: { score: prev.Spades.score + 1, active: true } }));
      } else if (gameName === 'HomeTeamBets') {
        tx = await contract.placeBet(ethers.utils.parseUnits('1', 18), 1);
        await tx.wait();
        setGameState((prev) => ({ ...prev, HomeTeamBets: { bet: prev.HomeTeamBets.bet + 1, active: true } }));
      } else if (gameName === 'GerastyxOpol') {
        tx = await contract.rollDice();
        await tx.wait();
        setGameState((prev) => ({ ...prev, GerastyxOpol: { dice: Math.floor(Math.random() * 6) + 1, active: true } }));
      }
      toast.success(`${gameName} played successfully`);
    } catch (error) {
      console.error(`Error playing ${gameName}:`, error);
      toast.error(`Failed to play ${gameName}`);
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-black text-gold font-sans flex flex-col items-center pt-20">
      {loading && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div className="text-gold text-xl">Loading...</div>
        </div>
      )}
      <h2 className="text-2xl font-bold mb-4">Goate Entertainment</h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full max-w-4xl">
        {['CardWars', 'Spades', 'HomeTeamBets', 'GerastyxOpol'].map((game) => (
          <div key={game} className="bg-gray-900 p-6 rounded-lg text-center">
            <h3 className="text-lg font-semibold mb-2">{game}</h3>
            <p>Balance: {balances.GOATE?.amount || 0} $GOATE</p>
            <p>
              {game === 'GerastyxOpol'
                ? `Dice: ${gameState[game].dice}`
                : game === 'HomeTeamBets'
                ? `Bet: ${gameState[game].bet}`
                : `Score: ${gameState[game].score}`}
            </p>
            <button
              className="bg-gold text-black px-4 py-2 rounded-lg hover:bg-yellow-400 transition mt-2"
              onClick={() => playGame(game)}
              disabled={loading}
            >
              Play {game}
            </button>
          </div>
        ))}
      </div>
      <ToastContainer position="top-right" autoClose={3000} />
    </div>
  );
};

export default EntertainmentPage;
--------------------
export const initializeOfflineModem = async () => {
  // Simulate ZeropointWifi modem initialization
  console.log('ZeropointWifi modem initialized');
  return true;
};

export const syncOfflineData = async () => {
  // Simulate syncing with Firebase and blockchain
  console.log('Syncing offline data...');
};

-----------------------

import DeviceConnectABI from './abis/DeviceConnect.json';
import ZeropointABI from './abis/Zeropoint.json';
import ZeropointWifiABI from './abis/ZeropointWifi.json';
import ZeropointPhoneServiceABI from './abis/ZeropointPhoneService.json';
import ZeropointGoateInsuranceABI from './abis/ZeropointGoateInsurance.json';
import TheGoateTokenABI from './abis/TheGoateToken.json';
import GoateStakingABI from './abis/GoateStaking.json';
import TokenPairStakingABI from './abis/TokenPairStaking.json';
import p2pLendingAndBorrowingABI from './abis/p2pLendingAndBorrowing.json';
import InstilledInteroperabilityABI from './abis/InstilledInteroperability.json';
import CardWarsABI from './abis/CardWars.json';
import HomeTeamBetsABI from './abis/HomeTeamBets.json';
import GerastyxOpolABI from './abis/GerastyxOpol.json';
import SpadesABI from './abis/Spades.json';
import GerastyxOpolPropertyNFTABI from './abis/GerastyxOpolPropertyNFT.json';
import ZeropointDigitalStockNFTABI from './abis/ZeropointDigitalStockNFT.json';
import ContractRegistryABI from './abis/ContractRegistry.json';
import DataStorageABI from './abis/DataStorage.json';
import GhostTransactionsABI from './abis/GhostTransactions.json';
import GhostGoateABI from './abis/GhostGoate.json';

import { ethers } from 'ethers';

let addresses = {
  DeviceConnect: '0x...',
  Zeropoint: '0x...',
  ZeropointWifi: '0x...',
  ZeropointPhoneService: '0x...',
  ZeropointGoateInsurance: '0x...',
  TheGoateToken: '0x...',
  GoateStaking: '0x...',
  TokenPairStaking: '0x...',
  p2pLendingAndBorrowing: '0x...',
  InstilledInteroperability: '0x...',
  CardWars: '0x...',
  HomeTeamBets: '0x...',
  GerastyxOpol: '0x...',
  Spades: '0x...',
  GerastyxOpolPropertyNFT: '0x...',
  ZeropointDigitalStockNFT: '0x...',
  ContractRegistry: '0x...',
  DataStorage: '0x...',
  GhostTransactions: '0x...',
  GhostGoate: '0x...'
};

const abis = {
  DeviceConnect: DeviceConnectABI,
  Zeropoint: ZeropointABI,
  ZeropointWifi: ZeropointWifiABI,
  ZeropointPhoneService: ZeropointPhoneServiceABI,
  ZeropointGoateInsurance: ZeropointGoateInsuranceABI,
  TheGoateToken: TheGoateTokenABI,
  GoateStaking: GoateStakingABI,
  TokenPairStaking: TokenPairStakingABI,
  p2pLendingAndBorrowing: p2pLendingAndBorrowingABI,
  InstilledInteroperability: InstilledInteroperabilityABI,
  CardWars: CardWarsABI,
  HomeTeamBets: HomeTeamBetsABI,
  GerastyxOpol: GerastyxOpolABI,
  Spades: SpadesABI,
  GerastyxOpolPropertyNFT: GerastyxOpolPropertyNFTABI,
  ZeropointDigitalStockNFT: ZeropointDigitalStockNFTABI,
  ContractRegistry: ContractRegistryABI,
  DataStorage: DataStorageABI,
  GhostTransactions: GhostTransactionsABI,
  GhostGoate: GhostGoateABI
};

export const getAddresses = () => addresses;
export const getAbis = () => abis;

export const updateContractConfig = async () => {
  if (window.ethereum) {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const contract = new ethers.Contract(addresses.ContractRegistry, abis.ContractRegistry, provider);
    const contractNames = [
      'DeviceConnect', 'Zeropoint', 'ZeropointWifi', 'ZeropointPhoneService', 'ZeropointGoateInsurance',
      'TheGoateToken', 'GoateStaking', 'TokenPairStaking', 'p2pLendingAndBorrowing',
      'InstilledInteroperability', 'CardWars', 'HomeTeamBets', 'GerastyxOpol', 'Spades',
      'GerastyxOpolPropertyNFT', 'ZeropointDigitalStockNFT', 'DataStorage', 'GhostTransactions', 'GhostGoate'
    ];
    for (const name of contractNames) {
      const addr = await contract.getAddress(name);
      if (addr !== '0x0000000000000000000000000000000000000000') {
        addresses[name] = addr;
      }
    }
  }
};

export const storeData = async (key, value) => {
  const db = await openDB();
  const tx = db.transaction(['cache'], 'readwrite');
  const store = tx.objectStore('cache');
  store.put({ key, value });
  return new Promise((resolve, reject) => {
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
};

export const getData = async (key) => {
  const db = await openDB();
  const tx = db.transaction(['cache'], 'readonly');
  const store = tx.objectStore('cache');
  const request = store.get(key);
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result?.value);
    request.onerror = () => reject(request.error);
  });
};

const openDB = () => {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('GoateElectricDB', 1);
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      db.createObjectStore('cache', { keyPath: 'key' });
    };
    request.onsuccess = (event) => resolve(event.target.result);
    request.onerror = (event) => reject(event.target.error);
  });
};

---------------------
DeviceConnect.sol
--------------------
Zeropoint.sol
// SPDX-License-Identifier: MITpragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";import "@openzeppelin/contracts/access/Ownable.sol";
contract Zeropoint is ERC20, Ownable {    constructor() ERC20("Zeropoint", "ZPE") {        _mint(msg.sender, 1000000 * 10 ** decimals());    }
    function mint(address to, uint256 amount) public onlyOwner {        _mint(to, amount);    }
    function burn(address from, uint256 amount) public onlyOwner {        _burn(from, amount);    }
    // Provide energy and reward with $ZPE    function provideEnergy(address user, uint256 amount) external onlyOwner {        _mint(user, amount);    }
    // Consume energy by burning $ZPE    function consumeEnergy(address user, uint256 amount) external {        require(balanceOf(user) >= amount, "Insufficient $ZPE");        _burn(user, amount);    }}
----------------------
ZeropointPhoneService.sol
-----------------------
ZeropointWifi.sol
-------------------------
TheGoateToken.sol
--------------------------
GoatePig.sol
------------------------
GoateStaking.sol
-------------------
TokenPairStaking.sol
--------------------
ZeropointDigitalStockNFT.sol
----------------------------
p2pLendingAndBorrowing.sol
------------------------------
InstilledInteroperability.sol
------------------------------
PayWithCrypto.sol
---------------------------
TheGoateCard.sol
-------------------------
USDMediator.sol
------------------------
ContractRegistry.sol
-------------------------
GhostGoate.sol
-----------------------
ZeropointInsurance.sol
-------------------------
ZeropointShield.sol
-----------------------
CardWars.sol
--------------------
HomeTeamBets.sol
---------------------
Spades.sol
---------------------
GerastyxOpol.sol
-----------------------
GerastyxOpolPropertyNFT.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract GerastyxPropertyNFT is ERC721, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    uint256 public constant TOTAL_PROPERTIES = 30;
    uint256 public constant TOKENS_PER_PROPERTY = 1_000_000_000;
    uint256 public tokenCounter;

    mapping(uint256 => uint256) public propertyValues; // Token ID => Value in USDC
    mapping(uint256 => uint256) public propertyMarketCaps; // Token ID => Market cap
    mapping(address => uint256[]) public userDecks; // User's selected deck (max 15 NFTs)
    mapping(uint256 => mapping(string => uint256)) public assetAllocations; // Token ID => Asset => Amount

    string[] public supportedAssets = [
        "AQUA", "XLM", "yUSD", "yXLM", "yBTC", "WFM", "TTWO", "BBY", "SFM", "DOLE"
    ];

    event PropertyMinted(uint256 tokenId, address owner, uint256 value);
    event DeckUpdated(address owner, uint256[] tokenIds);
    event RevenueDistributed(uint256 tokenId, uint256 amount, string asset);

    constructor(address _usdMediator, address _interoperability, address initialOwner)
        ERC721("GerastyxPropertyNFT", "GPNFT")
        Ownable(initialOwner)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        initializeProperties();
    }

    function initializeProperties() internal {
        propertyValues[1] = 100 * 10**6; // Duck Crossing
        propertyValues[2] = 110 * 10**6; // Duck Coast
        // Initialize remaining 28 properties with values
        for (uint256 i = 3; i <= TOTAL_PROPERTIES; i++) {
            propertyValues[i] = 100 * 10**6 + (i - 1) * 10 * 10**6;
        }
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        require(tokenId <= TOTAL_PROPERTIES * TOKENS_PER_PROPERTY, "Exceeds total supply");
        _safeMint(to, tokenId);
        tokenCounter++;
        emit PropertyMinted(tokenId, to, propertyValues[tokenId]);
    }

    function buyPropertyNFT(address buyer, uint256 tokenId, uint256 amount) external {
        require(tokenId <= TOTAL_PROPERTIES, "Invalid property");
        require(amount >= propertyValues[tokenId], "Insufficient payment");
        require(tokenCounter < TOTAL_PROPERTIES * TOKENS_PER_PROPERTY, "Max supply reached");

        // Allocate payment across supported assets
        uint256 perAsset = amount / supportedAssets.length;
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            assetAllocations[tokenId][supportedAssets[i]] += perAsset;
            usdMediator.buyStock(supportedAssets[i], perAsset);
        }

        _safeMint(buyer, tokenId);
        tokenCounter++;
        propertyMarketCaps[tokenId] += amount;
        emit PropertyMinted(tokenId, buyer, amount);
    }

    function sellPropertyNFT(address seller, uint256 tokenId, bool isAuction) external {
        require(ownerOf(tokenId) == seller, "Not owner");
        uint256 value = propertyValues[tokenId];
        uint256 payout = isAuction ? (value * 80) / 100 : value;

        // Sell underlying assets
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            uint256 assetAmount = assetAllocations[tokenId][supportedAssets[i]];
            usdMediator.sellStock(supportedAssets[i], assetAmount, "USDC", seller);
            assetAllocations[tokenId][supportedAssets[i]] = 0;
        }

        if (isAuction) {
            uint256 mediatorShare = value / 10;
            usdMediator.transferUSD(address(interoperability), mediatorShare / 2);
            usdMediator.transferUSD(address(usdMediator), mediatorShare / 2);
        }

        _burn(tokenId);
        propertyMarketCaps[tokenId] -= value;
    }

    function distributeDividends(uint256 tokenId, uint256 amount) external onlyOwner {
        uint256 revenueShare = (amount * 50) / 100;
        uint256 nftShare = (amount * 30) / 100;
        uint256 userShare = (amount * 20) / 100;

        // Revenue distribution
        usdMediator.transferUSD(0xCj03nesRevenueAddress, revenueShare / 2);
        usdMediator.transferUSD(address(interoperability), revenueShare / 4);
        usdMediator.transferUSD(address(usdMediator), revenueShare / 4);

        // NFT share (1% to each of 30 properties)
        for (uint256 i = 1; i <= TOTAL_PROPERTIES; i++) {
            propertyMarketCaps[i] += nftShare / TOTAL_PROPERTIES;
        }

        // User share (split across GOATE, GySt, BTC, USD)
        address owner = ownerOf(tokenId);
        usdMediator.transferUSD(owner, userShare / 4); // USD
        interoperability.crossChainTransfer(1, 1, "GOATE", userShare / 4, owner);
        interoperability.crossChainTransfer(1, 1, "GySt", userShare / 4, owner);
        interoperability.crossChainTransfer(1, 1, "BTC", userShare / 4, owner);

        emit RevenueDistributed(tokenId, amount, "USDC");
    }

    function updateDeck(uint256[] memory tokenIds) external {
        require(tokenIds.length <= 15, "Deck cannot exceed 15 NFTs");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not owner of NFT");
        }
        userDecks[msg.sender] = tokenIds;
        emit DeckUpdated(msg.sender, tokenIds);
    }
}

