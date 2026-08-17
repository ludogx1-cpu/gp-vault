const { summarizeRewardLedger, detectRewardAnomalies } = require('../src/utils/rewardAudit');

describe('rewardAudit utilities', () => {
  it('summarizes a ledger correctly', () => {
    const entries = [
      { amount: 0.02 },
      { amount: -0.005 },
      { amount: 0.01 },
      { amount: 0.03 },
    ];

    const summary = summarizeRewardLedger(entries);

    expect(summary.count).toBe(4);
    expect(summary.totalEarned).toBe(0.06);
    expect(summary.totalSpent).toBe(0.005);
    expect(summary.totalNet).toBe(0.055);
    expect(summary.largestSingleReward).toBe(0.03);
  });

  it('detects suspicious outlier rewards', () => {
    const entries = [
      { amount: 0.01 },
      { amount: 0.012 },
      { amount: 0.011 },
      { amount: 0.2 },
    ];

    const result = detectRewardAnomalies(entries);

    expect(result.suspicious).toBe(true);
    expect(result.highest).toBe(0.2);
  });
});
