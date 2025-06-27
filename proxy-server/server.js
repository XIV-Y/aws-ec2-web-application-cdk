const express = require('express');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

const API_SERVER_IP = process.env.API_SERVER_IP || '';
const PORT = process.env.PORT || 8080;
const API_BASE_URL = `http://${API_SERVER_IP}:3001`;

app.use(express.static(path.join(__dirname, 'public')));

app.use('/api', createProxyMiddleware({
  target: API_BASE_URL,
  changeOrigin: true
}));

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`API proxy: ${API_BASE_URL}`);
});
