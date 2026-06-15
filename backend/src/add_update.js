const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const newUpdateRef = admin.firestore().collection('updates').doc();
    await newUpdateRef.set({
      title: 'PTC Updates & Dogeogotcha! 🐾',
      message: 'PTC Ads Overhaul: When buying ads, you can now add custom titles to brand your campaigns. For earners, watched ads no longer disappear! They stay visible and grey out with a 24-hour "COOLDOWN" timer so you can easily track what you\'ve claimed today.\n\nDogeogotcha: We know you love your virtual pets! We are actively working behind the scenes to bring exciting new features, interactions, and rewards to the Dogeogotcha system very soon.\n\nNote: Golden Paw is a brand new site currently in early development. We are constantly updating the platform, balancing features, and fixing bugs. Thank you for being an early supporter!',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Added new update successfully!");
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}
run();
