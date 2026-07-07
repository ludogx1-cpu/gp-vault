require('dotenv').config();
const { admin } = require('./src/services/firebaseService');

const TOPIC = "Golden Paw Monthly Newsletter";
const newsletter_content = `**Hey Golden Paw Family!** 🐶

Welcome to the latest update from the Golden Paw Vault! We’ve been working overtime behind the scenes to optimize the platform, squash some bugs, and prepare some massive new earning features for you. 

Here is everything you need to know about what we've been building and what's coming next!

### 🛠️ Platform Updates & Improvements
First, we've rolled out several quality-of-life updates to make your experience smoother:
*   **Performance Boosts:** We've fine-tuned our backend servers so your faucet claims and PTC ad credits process faster and more reliably.
*   **Collaborator Integration:** We've recently completed our site verification with Collaborator and Google Search Console to bring more trusted, high-quality advertisers to the platform, meaning better ads and higher yields for you!
*   **Anti-Fraud Upgrades:** We've strengthened our security and leveling systems to keep the ecosystem safe and fair for our genuine earners.

### 🔥 Coming VERY SOON: The Ultimate Offerwall Hub! 💰
We know you've been asking for more ways to earn big, and we are incredibly close to launching our new **Offerwall Hub**. 
*   We are putting the final touches on integrations with premium networks like **Lootably**, **Torox**, and **BitcoTasks**. 
*   Once these go live, you’ll be able to earn massive DOGE rewards for playing games, testing apps, and taking surveys. Stay tuned—we'll send out an alert the moment the gates open!

### 🐕 Teaser: Dogeogotcha is Evolving...
If you've been taking care of your virtual pets, keep them happy and fed! We are currently working on a **major update for Dogeogotcha**. We can't reveal all the secrets just yet, but let's just say your digital companions are about to become a lot more interesting (and rewarding!). You won't want to miss this one.

### 🌟 Pro-Tip: Level Up Now!
Did you know that reaching **Level 3** will unlock those premium offerwalls the moment they go live? To protect our ecosystem, the biggest tasks are reserved for our leveled-up members. Start claiming from the Faucet and clicking PTC ads today to boost your XP so you are ready for launch day!

### 🚀 Ready to Earn?
Your vault is waiting for you. Log in now and claim your daily rewards!

👉 **[Log In to Golden Paw Now](https://goldenpaw.dog)**

Thank you for being the best part of the Golden Paw community. We are building something special together!

To the moon! 🌕🐕

**The Golden Paw Team**  
[goldenpaw.dog](https://goldenpaw.dog)
`;

async function uploadNewsletter() {
  try {
    const db = admin.firestore();
    
    // Explicit date: July 2, 2026, 12:00:00 UTC
    const releaseDate = admin.firestore.Timestamp.fromDate(new Date(Date.UTC(2026, 6, 2, 12, 0, 0)));
    
    await db.collection('blog_posts').add({
      content: newsletter_content,
      topic: TOPIC,
      created_at: releaseDate
    });

    console.log("✅ SUCCESS! The newsletter is now LIVE on your website's blog.");
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to upload to website:', error);
    process.exit(1);
  }
}

uploadNewsletter();
