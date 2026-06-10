const axios = require('axios');

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

module.exports = {
  getDogePrice,
};
