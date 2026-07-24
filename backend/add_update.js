const { admin } = require('./src/services/firebaseService');

async function run() {
  const db = admin.firestore();
  
  const title = "🚀 Latest Golden Paw Updates!";
  const message = `📱 **Install the App directly to your Device!**
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

  await db.collection('updates').add({
    title: title,
    message: message,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log("Update added successfully!");
  process.exit(0);
}

run();
