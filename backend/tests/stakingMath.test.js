const { calculatePendingInterest, APY, SECONDS_PER_YEAR } = require('../src/utils/stakingMath');

describe('calculatePendingInterest', () => {
  beforeAll(() => {
    jest.useFakeTimers();
  });
  afterAll(() => {
    jest.useRealTimers();
  });

  it('should return 0 if balance is invalid', () => {
    const mockTimestamp = { toDate: () => new Date() };
    expect(calculatePendingInterest(0, mockTimestamp)).toBe(0.0);
    expect(calculatePendingInterest(-10, mockTimestamp)).toBe(0.0);
    expect(calculatePendingInterest(null, mockTimestamp)).toBe(0.0);
  });
  
  it('should return 0 if no timestamp is provided', () => {
    expect(calculatePendingInterest(100, null)).toBe(0.0);
  });

  it('should correctly calculate interest over time', () => {
    const now = new Date('2026-01-01T00:00:00Z');
    jest.setSystemTime(now);
    
    // Stake timestamp was 1 day ago
    const oneDayAgo = new Date(now.getTime() - (24 * 60 * 60 * 1000));
    
    // Test with mock Firestore Timestamp object
    const mockTimestamp = { toDate: () => oneDayAgo };
    const interest = calculatePendingInterest(100, mockTimestamp);
    
    const expectedInterest = 100 * (APY / SECONDS_PER_YEAR) * (24 * 60 * 60);
    expect(interest).toBeCloseTo(expectedInterest, 6);
    
    // Test with plain string/date
    const interest2 = calculatePendingInterest(100, oneDayAgo.toISOString());
    expect(interest2).toBeCloseTo(expectedInterest, 6);
  });
});
