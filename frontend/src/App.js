import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_BASE_URL = '';

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [accounts, setAccounts] = useState([]);
  const [selectedAccount, setSelectedAccount] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [showForm, setShowForm] = useState('');

  useEffect(() => {
    if (token) {
      fetchAccounts();
    }
  }, [token]);

  const fetchAccounts = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/accounts`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setAccounts(response.data);
      if (response.data.length > 0) {
        setSelectedAccount(response.data[0]);
      }
    } catch (error) {
      console.error('Error fetching accounts:', error);
    }
  };

  const fetchTransactions = async (accountId) => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/accounts/${accountId}/transactions`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setTransactions(response.data);
    } catch (error) {
      console.error('Error fetching transactions:', error);
    }
  };

  const handleLogin = async (email, password) => {
    try {
      const response = await axios.post(`${API_BASE_URL}/api/login`, { email, password });
      const newToken = response.data.access_token;
      setToken(newToken);
      localStorage.setItem('token', newToken);
    } catch (error) {
      alert('Login failed: ' + error.response.data.error);
    }
  };

  const handleRegister = async (email, password, fullName) => {
    try {
      await axios.post(`${API_BASE_URL}/api/register`, {
        email,
        password,
        full_name: fullName
      });
      alert('Registration successful! Please login.');
    } catch (error) {
      alert('Registration failed: ' + error.response.data.error);
    }
  };

  const handleTransaction = async (type, amount, description, toAccount = '') => {
    try {
      let url, data;
      if (type === 'transfer') {
        url = `${API_BASE_URL}/api/transfer`;
        data = {
          from_account_id: selectedAccount.id,
          to_account_number: toAccount,
          amount: parseFloat(amount)
        };
      } else {
        url = `${API_BASE_URL}/api/accounts/${selectedAccount.id}/${type}`;
        data = { amount: parseFloat(amount), description };
      }

      await axios.post(url, data, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      fetchAccounts();
      setShowForm('');
      alert(`${type} successful!`);
    } catch (error) {
      alert(`${type} failed: ` + error.response.data.error);
    }
  };

  const logout = () => {
    setToken(null);
    localStorage.removeItem('token');
    setAccounts([]);
    setSelectedAccount(null);
  };

  if (!token) {
    return <AuthForm onLogin={handleLogin} onRegister={handleRegister} />;
  }

  return (
    <div className="app">
      <header className="bank-header">
        <div className="bank-logo">
          <h1>🏢 Shell Bank</h1>
          <p>Banking made simple</p>
        </div>
        <div className="user-info">
          <span>Welcome back!</span>
          <button className="logout-btn" onClick={logout}>Logout</button>
        </div>
      </header>

      <div className="dashboard">
        <div className="sidebar">
          <div className="accounts-section">
            <h2>💳 Your Accounts</h2>
            {accounts.map(account => (
              <div 
                key={account.id} 
                className={`account-card ${selectedAccount?.id === account.id ? 'selected' : ''}`}
                onClick={() => setSelectedAccount(account)}
              >
                <div className="account-header">
                  <h3>{account.account_type.toUpperCase()} ACCOUNT</h3>
                  <span className="account-status">Active</span>
                </div>
                <p className="account-number">**** **** **** {account.account_number.slice(-4)}</p>
                <div className="balance-section">
                  <span className="balance-label">Available Balance</span>
                  <h2 className="balance-amount">${account.balance.toFixed(2)}</h2>
                </div>
              </div>
            ))}
          </div>
          
          <div className="quick-access">
            <h3>Quick Access</h3>
            <div className="quick-links">
              <div className="quick-link">
                <span className="link-icon">📊</span>
                <div>
                  <p className="link-title">Account Statement</p>
                  <p className="link-desc">Download monthly statements</p>
                </div>
              </div>
              <div className="quick-link">
                <span className="link-icon">💳</span>
                <div>
                  <p className="link-title">Card Management</p>
                  <p className="link-desc">Block/unblock your cards</p>
                </div>
              </div>
              <div className="quick-link">
                <span className="link-icon">🔒</span>
                <div>
                  <p className="link-title">Security Center</p>
                  <p className="link-desc">Manage security settings</p>
                </div>
              </div>
            </div>
          </div>
          
          <div className="notifications">
            <h3>Recent Activity</h3>
            <div className="notification-item">
              <div className="notif-icon success">✓</div>
              <div>
                <p className="notif-title">Login Successful</p>
                <p className="notif-time">2 minutes ago</p>
              </div>
            </div>
            <div className="notification-item">
              <div className="notif-icon info">i</div>
              <div>
                <p className="notif-title">Account Statement Ready</p>
                <p className="notif-time">1 hour ago</p>
              </div>
            </div>
          </div>
        </div>

        <div className="actions-section">
          <div className="services-grid">
            <div className="service-category">
              <h3>Banking Services</h3>
              <div className="service-buttons">
                <button className="service-btn" onClick={() => setShowForm('deposit')}>
                  <div className="service-icon">💵</div>
                  <span>Deposit</span>
                </button>
                <button className="service-btn" onClick={() => setShowForm('withdraw')}>
                  <div className="service-icon">💸</div>
                  <span>Withdraw</span>
                </button>
                <button className="service-btn" onClick={() => setShowForm('transfer')}>
                  <div className="service-icon">🔄</div>
                  <span>Transfer</span>
                </button>
                <button className="service-btn" onClick={() => {
                  fetchTransactions(selectedAccount.id);
                  setShowForm('transactions');
                }}>
                  <div className="service-icon">📈</div>
                  <span>History</span>
                </button>
              </div>
            </div>
            
            <div className="service-category">
              <h3>Digital Services</h3>
              <div className="service-buttons">
                <button className="service-btn">
                  <div className="service-icon">📱</div>
                  <span>Mobile Pay</span>
                </button>
                <button className="service-btn">
                  <div className="service-icon">💳</div>
                  <span>Cards</span>
                </button>
                <button className="service-btn">
                  <div className="service-icon">📉</div>
                  <span>Investments</span>
                </button>
                <button className="service-btn">
                  <div className="service-icon">🏠</div>
                  <span>Loans</span>
                </button>
              </div>
            </div>
            
            <div className="service-category">
              <h3>Support & More</h3>
              <div className="service-buttons">
                <button className="service-btn">
                  <div className="service-icon">📞</div>
                  <span>Support</span>
                </button>
                <button className="service-btn">
                  <div className="service-icon">📍</div>
                  <span>Branches</span>
                </button>
                <button className="service-btn">
                  <div className="service-icon">⚙️</div>
                  <span>Settings</span>
                </button>
                <button className="service-btn">
                  <div className="service-icon">📊</div>
                  <span>Reports</span>
                </button>
              </div>
            </div>
          </div>

          {showForm === 'deposit' && (
            <TransactionForm 
              type="deposit" 
              onSubmit={handleTransaction}
              onCancel={() => setShowForm('')}
            />
          )}

          {showForm === 'withdraw' && (
            <TransactionForm 
              type="withdraw" 
              onSubmit={handleTransaction}
              onCancel={() => setShowForm('')}
            />
          )}

          {showForm === 'transfer' && (
            <TransferForm 
              onSubmit={handleTransaction}
              onCancel={() => setShowForm('')}
            />
          )}

          {showForm === 'transactions' && (
            <TransactionsList 
              transactions={transactions}
              onClose={() => setShowForm('')}
            />
          )}
        </div>
      </div>
    </div>
  );
}

function AuthForm({ onLogin, onRegister }) {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (isLogin) {
      onLogin(email, password);
    } else {
      onRegister(email, password, fullName);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-wrapper">
        <div className="bank-branding">
          <h1>🏢 Shell Bank</h1>
          <p>Simple • Fast • Secure</p>
        </div>
        <form onSubmit={handleSubmit} className="auth-form">
          <h2>{isLogin ? 'Welcome Back' : 'Create Account'}</h2>
        
        {!isLogin && (
          <input
            type="text"
            placeholder="Full Name"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            required
          />
        )}
        
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        
        <button type="submit">{isLogin ? 'Login' : 'Register'}</button>
        
          <p className="auth-switch" onClick={() => setIsLogin(!isLogin)}>
            {isLogin ? 'Need an account? Register' : 'Have an account? Login'}
          </p>
        </form>
      </div>
    </div>
  );
}

function TransactionForm({ type, onSubmit, onCancel }) {
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(type, amount, description);
  };

  return (
    <form onSubmit={handleSubmit} className="transaction-form">
      <h3>{type.charAt(0).toUpperCase() + type.slice(1)}</h3>
      <input
        type="number"
        step="0.01"
        placeholder="Amount"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        required
      />
      <input
        type="text"
        placeholder="Description (optional)"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />
      <div className="form-buttons">
        <button type="submit">Submit</button>
        <button type="button" onClick={onCancel}>Cancel</button>
      </div>
    </form>
  );
}

function TransferForm({ onSubmit, onCancel }) {
  const [amount, setAmount] = useState('');
  const [toAccount, setToAccount] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit('transfer', amount, '', toAccount);
  };

  return (
    <form onSubmit={handleSubmit} className="transaction-form">
      <h3>Transfer Money</h3>
      <input
        type="text"
        placeholder="To Account Number"
        value={toAccount}
        onChange={(e) => setToAccount(e.target.value)}
        required
      />
      <input
        type="number"
        step="0.01"
        placeholder="Amount"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        required
      />
      <div className="form-buttons">
        <button type="submit">Transfer</button>
        <button type="button" onClick={onCancel}>Cancel</button>
      </div>
    </form>
  );
}

function TransactionsList({ transactions, onClose }) {
  return (
    <div className="transactions-list">
      <div className="transactions-header">
        <h3>Transaction History</h3>
        <button onClick={onClose}>Close</button>
      </div>
      {transactions.map(transaction => (
        <div key={transaction.id} className="transaction-item">
          <span className={`transaction-type ${transaction.type}`}>
            {transaction.type.replace('_', ' ')}
          </span>
          <span className="transaction-amount">${transaction.amount.toFixed(2)}</span>
          <span className="transaction-description">{transaction.description}</span>
          <span className="transaction-date">
            {new Date(transaction.date).toLocaleDateString()}
          </span>
        </div>
      ))}
    </div>
  );
}

export default App;