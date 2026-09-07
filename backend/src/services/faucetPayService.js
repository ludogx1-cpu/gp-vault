const axios = require('axios');

async function faucetPaySend(address, amountInDecimal) {
  if (!process.env.FAUCETPAY_API_KEY) {
    const error = new Error('Missing FAUCETPAY_API_KEY environment variable');
    error.paymentDefinitelyNotSent = true;
    throw error;
  }

  // Parse the formatted decimal exactly; floating-point multiplication followed
  // by floor can silently send one smallest unit less than was debited.
  const decimal = Number(amountInDecimal).toFixed(8);
  const amountInSatoshis = BigInt(decimal.replace('.', ''));

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

  if (response.data.status !== 200 || response.data.success === false) {
    const error = new Error(`FaucetPay API Error: ${response.data.message || 'Unknown error'}`);
    // Documented v1 rejection codes; unknown outcomes require reconciliation.
    error.paymentDefinitelyNotSent = [401, 402, 403, 404, 405, 410, 450, 456, 457]
      .includes(Number(response.data.status));
    throw error;
  }

  return response.data;
}

module.exports = {
  faucetPaySend,
};
