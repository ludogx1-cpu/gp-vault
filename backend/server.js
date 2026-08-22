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
const leaderboardRoutes = require('./src/routes/leaderboardRoutes');
const emailRoutes = require('./src/routes/emailRoutes');
const promoRoutes = require('./src/routes/promoRoutes');
const { startAiChatService } = require('./src/services/aiChatService');
const { startWeeklyResetService } = require('./src/services/weeklyResetService');
const { startPromoCronService } = require('./src/services/promoCronService');
const { startPetCronService } = require('./src/services/petCronService');
const { startOfferwallCronService } = require('./src/services/offerwallCronService');
const { startDataconnectRetryCronService } = require('./src/services/dataconnectRetryCron');
const { startStakingCronService } = require('./src/services/stakingCronService');
const { startTreasuryMonitorService } = require('./src/services/treasuryMonitorService');
const app = express();
app.set('trust proxy', 1); // Trust the first proxy (Render) to fix X-Forwarded-For rate limit errors
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

// Ping endpoint to keep Render awake
app.get('/ping', (req, res) => {
  res.json({ success: true, message: 'pong' });
});

// Middleware to secure cron endpoints
const cronAuth = (req, res, next) => {
  const secret = process.env.CRON_SECRET;
  if (!secret) {
    console.warn('CRON_SECRET is not set in environment variables');
    return res.status(500).json({ success: false, error: 'Server configuration error' });
  }
  if (req.headers['x-cron-secret'] !== secret) {
    return res.status(401).json({ success: false, error: 'Unauthorized' });
  }
  next();
};

// Manual trigger endpoints for cron jobs
app.get('/cron/trigger-promo', cronAuth, async (req, res) => {
  const { runDailyPromoLogic } = require('./src/services/promoCronService');
  await runDailyPromoLogic();
  res.json({ success: true, message: 'Promo logic executed' });
});

app.get('/cron/trigger-pet-reminders', cronAuth, async (req, res) => {
  const { runPetCareLogic } = require('./src/services/petCronService');
  await runPetCareLogic();
  res.json({ success: true, message: 'Pet care logic executed' });
});

app.get('/cron/trigger-offerwall-release', cronAuth, async (req, res) => {
  const { releasePendingOffers } = require('./src/services/offerwallCronService');
  await releasePendingOffers();
  res.json({ success: true, message: 'Offerwall release logic executed' });
});

app.get('/cron/trigger-dataconnect-retry', cronAuth, async (req, res) => {
  const { retryFailedDataConnectSyncs } = require('./src/services/dataconnectRetryCron');
  await retryFailedDataConnectSyncs();
  res.json({ success: true, message: 'Data Connect DLQ retry logic executed' });
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
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/chat', chatRoutes);
app.use('/', emailRoutes);
app.use('/admin', adminRoutes);
app.use('/', promoRoutes);

if (require.main === module) {
  const port = process.env.PORT || 3000;
  
  startAiChatService(); // Start the AI Chat bots
  startWeeklyResetService(); // Start the Weekly Leaderboard Reset Service
  startPromoCronService(); // Start the Daily Promo Cron
  startPetCronService(); // Start the Pet Care Reminder Cron
  startOfferwallCronService(); // Start the Offerwall Release Cron
  startDataconnectRetryCronService(); // Start the Data Connect DLQ Retry Cron
  startStakingCronService(); // Start Staking Daily Reminders
  startTreasuryMonitorService(); // Start Treasury Monitoring

  app.listen(port, '0.0.0.0', () => {
    console.log(`GoldenPaw faucet backend listening on port ${port}`);
  });
}

module.exports = { app };
