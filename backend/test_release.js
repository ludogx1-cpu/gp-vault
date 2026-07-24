const { releasePendingOffers } = require('./src/services/offerwallCronService');
async function run() {
  await releasePendingOffers();
  process.exit(0);
}
run();
