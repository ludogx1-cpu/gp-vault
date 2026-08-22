const APY = 0.33;
const SECONDS_PER_YEAR = 31536000;
const MAX_ACCRUAL_SECONDS = 86400; // 24 hours

function calculatePendingInterest(stakedBalance, stakeTimestamp) {
  if (!stakedBalance || stakedBalance <= 0 || !stakeTimestamp) return 0.0;
  const now = Date.now();
  const stakeTimeMs = typeof stakeTimestamp.toDate === 'function' 
    ? stakeTimestamp.toDate().getTime() 
    : new Date(stakeTimestamp).getTime();
    
  let secondsPassed = Math.floor((now - stakeTimeMs) / 1000);
  if (secondsPassed <= 0) return 0.0;
  if (secondsPassed > MAX_ACCRUAL_SECONDS) {
    secondsPassed = MAX_ACCRUAL_SECONDS;
  }
  
  return stakedBalance * (APY / SECONDS_PER_YEAR) * secondsPassed;
}

module.exports = {
  calculatePendingInterest,
  APY,
  SECONDS_PER_YEAR
};
