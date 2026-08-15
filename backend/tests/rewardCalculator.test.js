const { calculateDogeReward } = require('../src/utils/rewardCalculator');

describe('calculateDogeReward', () => {
  it('should return 0.002 when price is <= 0.02', () => {
    expect(calculateDogeReward(0.01)).toBe(0.002);
    expect(calculateDogeReward(0.02)).toBe(0.002);
  });
  
  it('should return 0.0002 when price is >= 0.20', () => {
    expect(calculateDogeReward(0.20)).toBe(0.0002);
    expect(calculateDogeReward(0.30)).toBe(0.0002);
  });
  
  it('should calculate scaled reward between 0.02 and 0.20', () => {
    const price = 0.11; 
    expect(calculateDogeReward(price)).toBeCloseTo(0.0011, 5);
  });
});
