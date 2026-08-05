const { admin } = require('./src/services/firebaseService');

async function run() {
  const db = admin.firestore();
  
  const title = "🛠️ Recent App Updates & Apology";
  const message = `We've been hard at work deploying some major backend improvements and bug fixes for Golden Paw!

📱 **Native Android App Update**
Our Android App has been heavily updated! We've removed the annoying captcha on the Android mobile login (it's now secured silently in the background by Firebase App Check) and fixed the Google Sign-In button!

🙏 **Apology regarding Profile Popups**
We sincerely apologize for the recent bug where the Username and Pet Name setup screens kept popping up repeatedly. This issue has been fully resolved! You may need to enter your username and pet name **one last time** to finalize it, but it will not bother you again after that.

Thanks for your patience and for playing Golden Paw! 🐾`;

  // Insert the new update
  const newDocRef = await db.collection('updates').add({
    title: title,
    message: message,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log(`New update added successfully with ID: ${newDocRef.id}!`);
  process.exit(0);
}

run();
