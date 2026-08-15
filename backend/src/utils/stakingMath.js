const APY = 0.085;
const SECONDS_PER_YEAR = 31536000;

function calculatePendingInterest(stakedBalance, stakeTimestamp) {
  if (!stakedBalance || stakedBalance <= 0 || !stakeTimestamp) return 0.0;
  const now = Date.now();
  const stakeTimeMs = typeof stakeTimestamp.toDate === 'function' 
    ? stakeTimestamp.toDate().getTime() 
    : new Date(stakeTimestamp).getTime();
    
  const secondsPassed = Math.floor((now - stakeTimeMs) / 1000);
  if (secondsPassed <= 0) return 0.0;
  
  return stakedBalance * (APY / SECONDS_PER_YEAR) * secondsPassed;
}

module.exports = {
  calculatePendingInterest,
  APY,
  SECONDS_PER_YEAR
};
