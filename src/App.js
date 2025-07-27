import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, Navigate } from 'react-router-dom';
import Login from './Login';
import Register from './Register';

function App() {
  const [user, setUser] = useState(null);

  return (
    <Router>
      <nav style={{ margin: 10 }}>
        <Link to="/login" style={{ marginRight: 10 }}>Login</Link>
        <Link to="/register">Register</Link>
        {user && <span style={{ marginLeft: 20 }}>Welcome, {user.username}!</span>}
      </nav>
      <Routes>
        <Route path="/login" element={user ? <Navigate to="/" /> : <Login onLogin={setUser} />} />
        <Route path="/register" element={<Register />} />
        <Route path="/" element={user ? <div>Welcome to Plant Care!</div> : <Navigate to="/login" />} />
      </Routes>
    </Router>
  );
}

export default App;
