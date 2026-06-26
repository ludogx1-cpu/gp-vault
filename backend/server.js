const express = require('express');
const cors = require('cors');
const { admin } = require('./src/services/firebaseService');
const { getDogePrice } = require('./src/services/priceService');
const faucetRoutes = require('./src/routes/faucetRoutes');
const ptcRoutes = require('./src/routes/ptcRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const bannerRoutes = require('./src/routes/bannerRoutes');
const stakingRoutes = require('./src/routes/stakingRoutes');
const petRoutes = require('./src/routes/petRoutes');
const offerwallRoutes = require('./src/routes/offerwallRoutes');
const chatRoutes = require('./src/routes/chatRoutes');

const app = express();
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean)
  : [];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      callback(new Error(`CORS origin denied: ${origin}`));
    },
  })
);

app.get('/', (req, res) => {
  res.json({ success: true, message: 'GoldenPaw faucet backend is running' });
});

app.get('/price', async (req, res) => {
  try {
    const priceResult = await getDogePrice();
    res.json({ success: true, usdPrice: priceResult.price, source: priceResult.source });
  } catch (error) {
    console.error('Price endpoint error:', error.message || error);
    res.status(500).json({ success: false, error: 'Unable to fetch DOGE price' });
  }
});

app.post('/ipn', async (req, res) => {
  console.log('IPN received:', JSON.stringify(req.body || {}));
  res.json({ success: true, message: 'IPN received' });
});

app.get('/get-updates', async (req, res) => {
  try {
    const snapshot = await admin.firestore()
      .collection('updates')
      .orderBy('timestamp', 'desc')
      .limit(3)
      .get();
    
    const newsList = [];
    snapshot.forEach(doc => {
      newsList.push({ id: doc.id, ...doc.data() }); 
    });
    
    res.status(200).json(newsList);
  } catch (error) {
    console.error("Error fetching news:", error);
    res.status(500).json([]);
  }
});


// Register grouped routes
app.use('/', faucetRoutes);
app.use('/', ptcRoutes);
app.use('/', bannerRoutes);
app.use('/', stakingRoutes);
app.use('/', petRoutes);
app.use('/api/offerwall', offerwallRoutes);
app.use('/chat', chatRoutes);
app.use('/admin', adminRoutes);

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, '0.0.0.0', () => {
    console.log(`GoldenPaw faucet backend listening on port ${port}`);
  });
}

module.exports = { app };
