const express = require('express');
const axios = require('axios');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();
app.use(express.json({ limit: '1mb' }));

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
  }),
);

let cachedDogePrice = 0.11; 
let lastFetchTime = 0;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

async function getLiveDogePrice() {
  const now = Date.now();
  
  if (now - lastFetchTime < CACHE_DURATION) {
    return cachedDogePrice;
  }

  try {
    const response = await axios.get('https://api.coinbase.com/v2/prices/DOGE-USD/spot');
    cachedDogePrice = parseFloat(response.data.data.amount);
    lastFetchTime = now;
    console.log(`Live DOGE price updated: $${cachedDogePrice}`);
    return cachedDogePrice;
  } catch (error) {
    console.error("Price fetch failed, using fallback:", error.message);
    return cachedDogePrice; 
  }
}

const firebaseServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
  : process.env.FIREBASE_PRIVATE_KEY
  ? {
      type: process.env.FIREBASE_TYPE || 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_uri: 'https://oauth2.googleapis.com/token',
      auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
      client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL,
    }
  : null;

if (firebaseServiceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(firebaseServiceAccount),
  });
} else {
  admin.initializeApp();
}

async function verifyFirebaseToken(req, res, next) {
  const authorization = req.headers.authorization || '';
  const token = authorization.startsWith('Bearer ') ? authorization.split(' ')[1] : null;

  if (!token) {
    return next();
  }

  try {
    req.user = await admin.auth().verifyIdToken(token);
    next();
  } catch (error) {
    console.error('Firebase token verification failed:', error.message || error);
    return res.status(401).json({ success: false, error: 'Invalid authentication token' });
  }
}

function parseUsdNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

async function getDogePrice() {
  try {
    const price = await getLiveDogePrice();
    return { price, source: 'coinbase_cached' };
  } catch (error) {
    const fallbackPrice = 0.11;
    console.warn('Falling back to default DOGE price:', fallbackPrice);
    return { price: fallbackPrice, source: 'fallback' };
  }
}

function formatAmount(amount) {
  return Number(Number(amount).toFixed(8)).toString();
}

async function faucetPaySend(address, amountInDecimal) {
  if (!process.env.FAUCETPAY_API_KEY) {
    throw new Error('Missing FAUCETPAY_API_KEY environment variable');
  }

  const amountInSatoshis = Math.floor(Number(amountInDecimal) * 100000000);

  const params = new URLSearchParams({
    api_key: process.env.FAUCETPAY_API_KEY,
    currency: 'DOGE',
    amount: amountInSatoshis.toString(),
    to: address, 
  });

  const url = 'https://faucetpay.io/api/v1/send';
  const response = await axios.post(url, params.toString(), { 
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    timeout: 15000 
  });

  if (!response.data) {
    throw new Error('FaucetPay returned no response body');
  }

  return response.data;
}

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

app.post('/send-doge', verifyFirebaseToken, async (req, res) => {
  try {
    const {
      address: bodyAddress,
      user_address,
      captcha_token,
      captcha_provider,
      source,
    } = req.body;

    const address = bodyAddress || user_address;
    if (!address) {
      return res.status(400).json({ success: false, error: 'Missing destination address' });
    }

    const priceResult = await getDogePrice();
    const price = priceResult.price;
    let dogeAmount = 0;
    
    if (price <= 0.05) {
      dogeAmount = 0.0008;
    } else if (price >= 0.50) {
      dogeAmount = 0.0002;
    } else {
      dogeAmount = 0.0008 - ((price - 0.05) / 0.45) * 0.0006;
    }

    const faucetPayResponse = await faucetPaySend(address, dogeAmount);

    const resultPayload = {
      success: true,
      address,
      amount: dogeAmount,
      usdPrice: price,
      priceSource: priceResult.source,
      faucetPayResponse,
      source: source || 'send-doge',
      captchaToken: captcha_token,
      captchaProvider: captcha_provider,
      authUser: req.user || null,
    };

    console.log('Send DOGE success:', JSON.stringify({ address, amount: dogeAmount }));
    res.json(resultPayload);
  } catch (error) {
    console.error('send-doge error:', error.response?.data || error.message || error);
    res.status(500).json({
      success: false,
      error: error.response?.data?.message || error.message || 'Failed to send DOGE',
    });
  }
});

app.post('/claim-vault', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for vault claim' });
    }

    console.log('Claim vault request for user:', req.user.uid);

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const now = admin.firestore.Timestamp.now();
    const cooldownMs = 5 * 60 * 1000; // 5 minutes

    const priceResult = await getDogePrice();
    const price = priceResult.price;
    let baseReward = 0;
    
    if (price <= 0.05) {
      baseReward = 0.0008;
    } else if (price >= 0.50) {
      baseReward = 0.0002;
    } else {
      baseReward = 0.0008 - ((price - 0.05) / 0.45) * 0.0006;
    }

    let finalReward = 0;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }

      const data = snapshot.data() || {};
      
      const lastClaim = data.last_claim_time;
      if (lastClaim && Date.now() - lastClaim.toDate().getTime() < cooldownMs) {
        const secondsLeft = Math.ceil((cooldownMs - (Date.now() - lastClaim.toDate().getTime())) / 1000);
        const cooldownError = new Error(`Cooldown active. Try again in ${secondsLeft} seconds.`);
        cooldownError.statusCode = 429;
        throw cooldownError;
      }

      const xp = Number(data.xp || 0);
      const streak = Number(data.streak_count || 0);
      let level = Math.floor(Math.sqrt(xp / 100));
      if (level > 100) level = 100;
      
      const totalBonusPercent = level + streak;
      finalReward = baseReward * (1 + (totalBonusPercent / 100));

      transaction.update(userRef, {
        doge_balance: Number(data.doge_balance || 0) + finalReward,
        xp: xp + 10,
        last_claim_time: now,
      });
    });

    res.json({
      success: true,
      message: 'Vault claim verified. Your reward has been recorded.',
      earned: finalReward,
      authUser: req.user.uid,
    });
  } catch (error) {
    console.error('claim-vault error:', error.response?.data || error.message || error);
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Failed to claim vault',
    });
  }
});

// ==========================================
// SECURED WITHDRAWAL (WITH BALANCE CHECKS & COOLDOWN)
// ==========================================
app.post('/withdraw', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for withdrawal' });
    }

    const { user_address, amount } = req.body;
    if (!user_address) {
      return res.status(400).json({ success: false, error: 'Missing destination address' });
    }

    const sendAmount = Number(amount);
    if (!Number.isFinite(sendAmount) || sendAmount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid withdrawal amount' });
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const cooldownMs = 60 * 1000; // 1-minute spam block

    // Firestore Transaction: Lock database validation rules tightly
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }

      const data = snapshot.data();
      const currentBalance = Number(data.doge_balance || 0);
      const lastWithdrawal = data.last_withdrawal;

      if (lastWithdrawal && Date.now() - lastWithdrawal.toDate().getTime() < cooldownMs) {
        throw new Error('Please wait a minute between withdrawals.');
      }

      if (currentBalance < sendAmount) {
        throw new Error('Insufficient balance for this withdrawal.');
      }

      transaction.update(userRef, {
        doge_balance: currentBalance - sendAmount,
        last_withdrawal: admin.firestore.Timestamp.now()
      });
    });

    const formattedAmount = formatAmount(sendAmount);
    const faucetPayResponse = await faucetPaySend(user_address, formattedAmount);

    const resultPayload = {
      success: true,
      address: user_address,
      amount: formattedAmount,
      faucetPayResponse,
      authUser: req.user,
    };

    console.log('Withdraw request:', JSON.stringify(resultPayload));
    res.json(resultPayload);
  } catch (error) {
    console.error('withdraw error:', error.response?.data || error.message || error);
    res.status(500).json({
      success: false,
      error: error.message || error.response?.data || 'Failed to process withdrawal',
    });
  }
});

app.post('/ipn', async (req, res) => {
  console.log('IPN received:', JSON.stringify(req.body || {}));
  res.json({ success: true, message: 'IPN received' });
});

app.post('/swap-doge', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for swap' });
    }

    const { amount } = req.body;
    const swapAmount = Number(amount);
    if (!Number.isFinite(swapAmount) || swapAmount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid swap amount' });
    }

    console.log('Swap DOGE request:', { user: req.user.uid, amount: swapAmount });
    res.json({ success: true, message: 'Swap completed successfully', swappedAmount: formatAmount(swapAmount) });
  } catch (error) {
    console.error('swap-doge error:', error.response?.data || error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process DOGE swap' });
  }
});

app.post('/buy-banner', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for banner purchase' });
    }

    const { doc_id, image_url, target_url } = req.body;
    if (!doc_id || !image_url || !target_url) {
      return res.status(400).json({ success: false, error: 'Missing required banner fields' });
    }

    console.log('Buy banner request:', { user: req.user.uid, doc_id, image_url, target_url });
    res.json({ success: true, message: 'Banner campaign registered successfully' });
  } catch (error) {
    console.error('buy-banner error:', error.response?.data || error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process banner purchase' });
  }
});

app.post('/buy-ptc', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for PTC purchase' });
    }

    const { target_url, tier, clicks } = req.body;
    if (!target_url || !tier || !clicks) {
      return res.status(400).json({ success: false, error: 'Missing required PTC fields' });
    }

    console.log('Buy PTC request:', { user: req.user.uid, target_url, tier, clicks });
    res.json({ success: true, message: 'PTC ad added to the pool successfully' });
  } catch (error) {
    console.error('buy-ptc error:', error.response?.data || error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process PTC purchase' });
  }
});

app.post('/claim-ptc', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for PTC claim' });
    }

    const { captcha_token, captcha_provider } = req.body;
    if (!captcha_token || !captcha_provider) {
      return res.status(400).json({ success: false, error: 'Missing captcha verification data' });
    }

    console.log('Claim PTC request:', { user: req.user.uid, captcha_provider });
    res.json({ success: true, message: 'PTC claim processed successfully' });
  } catch (error) {
    console.error('claim-ptc error:', error.response?.data || error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process PTC claim' });
  }
});

app.post('/claim-bonus-sponsor', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for sponsor bonus claim' });
    }

    const { captcha_token, captcha_provider } = req.body;
    if (!captcha_token || !captcha_provider) {
      return res.status(400).json({ success: false, error: 'Missing captcha verification data' });
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const rewardAmount = 0.003;
    const xpReward = 30;
    const cooldownMs = 3 * 60 * 60 * 1000;
    const now = admin.firestore.Timestamp.now();

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }

      const data = snapshot.data() || {};
      const lastClaim = data.last_bonus_sponsor_claim;
      if (lastClaim && Date.now() - lastClaim.toDate().getTime() < cooldownMs) {
        const minutesLeft = Math.ceil((cooldownMs - (Date.now() - lastClaim.toDate().getTime())) / 60000);
        const cooldownError = new Error(`Sponsor bonus cooldown active. Try again in ${minutesLeft} minutes.`);
        cooldownError.statusCode = 429;
        throw cooldownError;
      }

      transaction.update(userRef, {
        doge_balance: Number(data.doge_balance || 0) + rewardAmount,
        xp: Number(data.xp || 0) + xpReward,
        last_bonus_sponsor_claim: now,
      });
    });

    console.log('Claim bonus sponsor request:', { user: req.user.uid, captcha_provider });
    res.json({
      success: true,
      message: 'Sponsor bonus claim processed successfully',
      rewardAmount,
      xpReward,
    });
  } catch (error) {
    console.error('claim-bonus-sponsor error:', error.response?.data || error.message || error);
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Failed to process sponsor bonus claim',
    });
  }
});

app.post('/admin/add-update', verifyFirebaseToken, async (req, res) => {
  try {
    const ADMIN_UID = 'P8iffVqbUgetAVA4MdHVZ1CfvUv1'; 
    
    if (req.user.uid !== ADMIN_UID) {
      return res.status(403).json({ success: false, error: 'Access Denied: Admins only.' });
    }

    const { title, message } = req.body;
    if (!title || !message) {
      return res.status(400).json({ success: false, error: 'Missing title or message' });
    }

    await admin.firestore().collection('updates').add({
      title,
      message,
      timestamp: admin.firestore.Timestamp.now(),
    });

    console.log('Admin update posted:', title);
    res.json({ success: true, message: 'Update posted successfully to all users!' });
  } catch (error) {
    console.error('add-update error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to post update' });
  }
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

app.delete('/admin/delete-update/:id', verifyFirebaseToken, async (req, res) => {
  try {
    const ADMIN_UID = 'P8iffVqbUgetAVA4MdHVZ1CfvUv1'; 
    if (req.user.uid !== ADMIN_UID) {
      return res.status(403).json({ success: false, error: 'Admins only.' });
    }

    const docId = req.params.id;
    await admin.firestore().collection('updates').doc(docId).delete();
    
    res.json({ success: true, message: 'Deleted successfully' });
  } catch (error) {
    console.error('delete-update error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete update' });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`GoldenPaw faucet backend listening on port ${port}`);
});
