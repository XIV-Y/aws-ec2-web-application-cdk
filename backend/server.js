const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors({
  origin: [
    'http://localhost:3000',
    /^http:\/\/.*:3000$/,
  ],
  credentials: true
}));

app.use(express.json());

app.get('/api/data', (req, res) => {
  const responseData = {
    message: 'Hello from Node.js API Server!',
    timestamp: new Date().toISOString(),
    randomValue: Math.floor(Math.random() * 1000),
  };
  
  res.json(responseData);
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`API Server is running on http://0.0.0.0:${PORT}`);
});

const gracefulShutdown = (signal) => {
  console.log(`\n ${signal} received, shutting down gracefully...`);
  
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
  
  setTimeout(() => {
    console.log('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
