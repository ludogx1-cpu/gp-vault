const { admin } = require('./src/services/firebaseService');

async function run() {
  const db = admin.firestore();
  
  const title = "🚀 Latest Golden Paw Updates!";
  const message = `👤 **Global Usernames & Leaderboards!**
You can now officially set a **Global Username** directly from your Account Profile! Setting your username will instantly replace your "Anonymous" tag on the Leaderboard and will automatically link up with your Community Chat profile. Go set yours now to claim your spot on the Leaderboard!

📱 **Install the App directly to your Device!**
You can now officially install Golden Paw directly to your mobile home screen or desktop! Enjoy a faster, full-screen, native app experience without needing an app store. 

🔔 **Push Notifications & Reminders**
Never let your pet go hungry again! We've added web push notifications so you can receive automated Pet Care reminders and updates directly to your device. 

🖥️ **Sleek New Navigation Sidebar**
We've completely overhauled our layout on desktop and tablets! Say goodbye to the old pop-out menu and hello to a new, lightning-fast persistent sidebar that makes navigating the Vault easier than ever.

🐾 **Easier Pet Care & Balancing**
We heard your feedback! We have officially **halved** the rate at which your pet's stats decay. It is now much easier to keep your furry friends happy and healthy!

💸 **Offerwall & Withdrawal Upgrades**
* **Automated Offerwalls:** Pending offerwall earnings will now automatically release into your available balance exactly after the 7-day holding period!
* **Bulletproof Withdrawals:** We've heavily upgraded our FaucetPay integration. If you have had any issues around the withdrawals please contact us and we will get it sorted.

🤝 **Partnership News: BitcoTasks!**
Great news! **BitcoTasks** has officially accepted our site for running ads! We are also currently waiting on our Offerwall request with them and are very hopeful that it will be accepted soon!`;

  // Find and delete the old update
  const snapshot = await db.collection('updates').where('title', '==', title).get();
  
  if (!snapshot.empty) {
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      console.log(`Deleting old update: ${doc.id}`);
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('Old updates deleted.');
  }

  // Insert the new one
  const newDocRef = await db.collection('updates').add({
    title: title,
    message: message,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log(`New update added successfully with ID: ${newDocRef.id}!`);
  process.exit(0);
}

run();
