import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Login from './pages/Login';
import SignUp from './pages/SignUp';
import Dashboard from './pages/Dashboard';
import RadarDetail from './pages/RadarDetail';
import Messages from './pages/Messages';
import AssessmentConfig from './pages/AssessmentConfig';
import Layout from './components/Layout';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<SignUp />} />
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="/assessments" element={<Dashboard />} />
          <Route path="/radar/:id" element={<RadarDetail />} />
          <Route path="/messages" element={<Messages />} />
          <Route path="/config" element={<AssessmentConfig />} />
        </Route>
      </Routes>
    </Router>
  );
}

export default App;