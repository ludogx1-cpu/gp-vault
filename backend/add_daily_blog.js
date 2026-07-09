require('dotenv').config();
const { admin } = require('./src/services/firebaseService');

const TOPIC = "Major Update: TimeWall is Officially Integrated! 🚀";
const blog_content = `Hello Golden Paw Community! 🐾

We have some massive news for you today. We've officially partnered with **TimeWall**, one of the top offerwall and PTC networks in the space!

### 📈 What is TimeWall?
TimeWall provides some of the highest-paying tasks, surveys, and clicks available. If you've been looking for a way to quickly boost your DOGE balance, this is exactly what you need.

### 🎮 Where can I find it?
1. **Offerwall Hub:** Head over to the Offerwall section from the side menu. You'll see a brand new TimeWall button. Click it to access the main offerwall.
2. **Quick Links:** We added some fancy quick links right underneath the TimeWall button so you can instantly jump to your favorite sections like Tasks, Clicks, Games, and BuyPoints!
3. **PTC Earn Page:** We’ve completely replaced the old Monetag ads on the PTC Earn page with a dedicated "TimeWall Clicks" portal!

### 💰 Why did we do this?
We removed Monetag completely because the ads were temperamental and annoying. We want the best user experience for you, and TimeWall delivers exactly that!

Go check it out and start earning right now!

To the moon! 🌕🚀
**- The Golden Paw Team**`;

async function uploadDailyBlog() {
  try {
    const db = admin.firestore();
    
    await db.collection('blog_posts').add({
      content: blog_content,
      topic: TOPIC,
      category: 'daily_blog',
      approved: true,
      likedBy: [],
      dislikedBy: [],
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log("✅ SUCCESS! The daily blog is now LIVE.");
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to upload:', error);
    process.exit(1);
  }
}

uploadDailyBlog();
