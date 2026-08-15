const { admin } = require('./src/services/firebaseService');

async function run() {
  const db = admin.firestore();
  await db.collection('updates').add({
    title: 'Development Update & Offerwall Notice',
    content: `We are very sorry there have been no updates recently! We took some time to sit and reflect on Golden Paw and its foreseeable future. Honestly, we became overwhelmed with our accomplishments over the last couple of months—we have been working so hard around the clock to turn this idea into a reality, and we just had to take a minute to breathe. 

We are so happy with the progress that has been made, and let us tell you, there are bigger things to come! If you like what you see so far, then be sure to stick around. Feel free to make any suggestions; we would love to hear them.

Important Notice Regarding Offerwall Withdrawals:
We are currently experiencing a delay with offerwall withdrawals while we get some backend systems fully configured. We will try to get things sorted in that area as soon as we can. You can still complete tasks from the offerwall, but for the time being, we will have to hold those funds securely in your balance. 

Please note: You can still earn from doing the Faucet and PTC ads, and you can still withdraw from that section of Golden Paw! It is just the offerwall withdrawals that are temporarily on hold.

The Good News!
While we were busy, we released a ton of highly-requested features to improve your experience:
- 📱 Android App Launch: You can now download and sideload our native Android APK directly from the site!
- ⚡ Smoother Mobile Experience: We removed annoying CAPTCHAs on mobile and introduced seamless native Google Sign-In.
- 🏎️ Web Performance: We fixed several pesky caching and login popup bugs, making the web app significantly faster.
- ✏️ Username Flexibility: We listened to your feedback and completely removed the 3-month restriction on username changes!

Thank you for your patience and for being part of Golden Paw!`,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log("Update posted!");
  process.exit(0);
}
run();
