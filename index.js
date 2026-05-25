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

const isFirebaseEnabled = !!firebaseServiceAccount;

async function verifyFirebaseToken(req, res, next) {
  const authorization = req.headers.authorization || '';
  let token = authorization.startsWith('Bearer ') ? authorization.split(' ')[1] : null;

  if (!token && req.body && req.body.idToken) {
    token = req.body.idToken;
  }

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
  const fallbackPrice = 0.11;

  try {
    const binanceResponse = await axios.get('https://api.binance.com/api/v3/ticker/price', {
      params: { symbol: 'DOGEUSDT' },
      timeout: 8000,
    });
    const price = parseFloat(binanceResponse.data.price);
    if (price > 0) {
      return { price, source: 'binance' };
    }
    throw new Error('Binance returned invalid price');
  } catch (binanceError) {
    console.warn('Binance price fetch failed:', binanceError.message || binanceError);
  }

  try {
    const coinGeckoResponse = await axios.get('https://api.coingecko.com/api/v3/simple/price', {
      params: { ids: 'dogecoin', vs_currencies: 'usd' },
      timeout: 8000,
    });
    const price = Number(coinGeckoResponse.data.dogecoin?.usd);
    if (price > 0) {
      return { price, source: 'coingecko' };
    }
    throw new Error('CoinGecko returned invalid price');
  } catch (coingeckoError) {
    console.warn('CoinGecko fallback failed:', coingeckoError.message || coingeckoError);
  }

  console.warn('Falling back to default DOGE price:', fallbackPrice);
  return { price: fallbackPrice, source: 'fallback' };
}

function formatAmount(amount) {
  return Number(Number(amount).toFixed(8)).toString();
}

async function faucetPaySend(address, amount) {
  if (!process.env.FAUCETPAY_API_KEY) {
    throw new Error('Missing FAUCETPAY_API_KEY environment variable');
  }

  const params = new URLSearchParams({
    api_key: process.env.FAUCETPAY_API_KEY,
    currency: 'DOGE',
    amount: amount.toString(),
    address,
  });

  const url = 'https://faucetpay.io/api/v1/send';
  const response = await axios.get(url, { params, timeout: 15000 });

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
      amount,
      usdValue,
      captcha_token,
      captcha_provider,
      source,
    } = req.body;

    const address = bodyAddress || user_address;
    if (!address) {
      return res.status(400).json({ success: false, error: 'Missing destination address' });
    }

    const priceResult = await getDogePrice();
    const dogeAmount = amount
      ? parseFloat(amount)
      : parseUsdNumber(usdValue)
      ? parseUsdNumber(usdValue) / priceResult.price
      : 10;

    if (!Number.isFinite(dogeAmount) || dogeAmount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid DOGE amount' });
    }

    const formattedAmount = formatAmount(dogeAmount);
    const faucetPayResponse = await faucetPaySend(address, formattedAmount);

    const resultPayload = {
      success: true,
      address,
      amount: formattedAmount,
      usdPrice: priceResult.price,
      priceSource: priceResult.source,
      faucetPayResponse,
      source: source || 'send-doge',
      captchaToken: captcha_token,
      captchaProvider: captcha_provider,
      authUser: req.user || null,
    };

    console.log('Send DOGE request:', JSON.stringify({ address, formattedAmount, captcha_provider, authUser: req.user?.uid || null }));
    console.log('Send DOGE result:', JSON.stringify(resultPayload));
    res.json(resultPayload);
  } catch (error) {
    console.error('send-doge error:', error.response?.data || error.message || error);
    res.status(500).json({
      success: false,
      error: error.response?.data || error.message || 'Failed to send DOGE',
    });
  }
});

app.post('/claim-vault', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for vault claim' });
    }

    console.log('Claim vault request for user:', req.user.uid);

    res.json({
      success: true,
      message: 'Vault claim verified. Your reward has been recorded.',
      authUser: req.user,
    });
  } catch (error) {
    console.error('claim-vault error:', error.response?.data || error.message || error);
    res.status(500).json({
      success: false,
      error: error.response?.data || error.message || 'Failed to claim vault',
    });
  }
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  console.log(`GoldenPaw faucet backend listening on port ${port}`);
});
