const { 
  getGrowthStage, 
  getAgeMultiplier, 
  calculatePetBonusPercent,
  calculateShopBonusPercent 
} = require('../src/utils/petMechanics');

describe('petMechanics', () => {
  
  describe('getGrowthStage', () => {
    it('should determine stage based on xp thresholds', () => {
      expect(getGrowthStage({ pet_xp: 50 })).toBe('baby');
      expect(getGrowthStage({ pet_xp: 150 })).toBe('toddler');
      expect(getGrowthStage({ pet_xp: 300 })).toBe('puppy');
      expect(getGrowthStage({ pet_xp: 750 })).toBe('child');
      expect(getGrowthStage({ pet_xp: 10000 })).toBe('old_dog');
    });
  });

  describe('getAgeMultiplier', () => {
    it('should return correct multiplier for stage', () => {
      expect(getAgeMultiplier({ pet_xp: 50 })).toBe(1.0); // baby
      expect(getAgeMultiplier({ pet_xp: 300 })).toBe(1.10); // puppy
      expect(getAgeMultiplier({ pet_xp: 10000 })).toBe(2.0); // old_dog
    });
  });

  describe('calculatePetBonusPercent', () => {
    it('should return 0 if pet is sick', () => {
      expect(calculatePetBonusPercent({ hunger: 100, happiness: 100, energy: 100 }, { pet_sick: true })).toBe(0);
    });

    it('should grant 10% bonus for high stats', () => {
      expect(calculatePetBonusPercent({ hunger: 90, happiness: 90, energy: 90 }, {})).toBe(10);
    });

    it('should grant 5% bonus for medium stats', () => {
      expect(calculatePetBonusPercent({ hunger: 60, happiness: 60, energy: 60 }, {})).toBe(5);
    });

    it('should grant 0% bonus for low stats', () => {
      expect(calculatePetBonusPercent({ hunger: 30, happiness: 30, energy: 30 }, {})).toBe(0);
    });
  });
  
  describe('calculateShopBonusPercent', () => {
    it('should calculate bonus based on equipped accessories', () => {
      const userData = {
        pet_equipped_accessories: ['sunglasses', 'gold_chain'] // 20 + 30 = 50
      };
      expect(calculateShopBonusPercent(userData)).toBe(50);
    });
  });

});
