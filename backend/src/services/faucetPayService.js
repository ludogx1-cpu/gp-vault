const axios = require('axios');

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

module.exports = {
  faucetPaySend,
};
