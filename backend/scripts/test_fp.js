const axios = require('axios');
async function test() {
  const url = 'https://faucetpay.io/api/v1/send';
  const params = new URLSearchParams({
    api_key: 'invalid_key_123',
    currency: 'DOGE',
    amount: '1000000',
    to: 'D8HkZ3sM6qXh8nB4A5d8yQhL2vTj1K9mP'
  });
  try {
    const res = await axios.post(url, params.toString(), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    console.log("HTTP Code:", res.status);
    console.log("Response Body:", res.data);
  } catch(e) {
    console.error("Axios Error:", e.response ? e.response.data : e.message);
  }
  process.exit(0);
}
test();
