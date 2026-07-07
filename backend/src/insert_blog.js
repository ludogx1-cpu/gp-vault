const admin = require('firebase-admin');
require('dotenv').config({ path: '../.env' });

// Initialize Firebase Admin
if (!admin.apps.length) {
    let serviceAccount;
    try {
        serviceAccount = require('../../service-account.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (err) {
        console.warn("No local service account found, attempting application default credentials.");
        admin.initializeApp();
    }
}

const db = admin.firestore();

async function addBlogPost() {
    const topic = "Best Crypto Faucets 2026: Why Golden Paw is the Ultimate Choice";
    const content = `
# Best Crypto Faucets 2026: Why Golden Paw is the Ultimate Choice

If you're looking to earn free cryptocurrency in 2026, the landscape of crypto faucets has completely changed. Gone are the days of mindlessly solving captchas for fractions of a penny. Today, users demand **engagement, real yields, and gamification**.

Here is why **Golden Paw** stands out as the ultimate Dogecoin faucet in 2026:

## 1. The Instant 5-Minute Faucet
While other platforms make you wait hours, Golden Paw lets you claim free DOGE every 5 minutes. No hidden limits, just pure rewards. The interface is completely clean and optimized for speed.

## 2. The 8.5% APY Vault
Earning free crypto is great, but *growing* it is even better. Golden Paw features "The Vault", an integrated staking protocol that pays out an incredible **8.5% APY**, compounded and calculated every single second. 

## 3. Dogeogotcha: Gamified Earnings
Why just click a button when you can raise a virtual Shiba Inu?
By feeding, playing with, and buying items for your virtual pet, you can boost your base faucet claims by up to **150%**. This gamified approach makes earning crypto actually fun.

## 4. Massive 20% Referral Program
If you invite friends to Golden Paw, you earn **20% of every claim they make for life**. This is entirely passive income. 

### Conclusion
Golden Paw isn't just a faucet; it's a complete Dogecoin ecosystem designed to maximize your earnings while keeping you entertained. 

**[Create your free account today and start claiming!](https://goldenpaw.dog)**
`;

    try {
        await db.collection('blog_posts').add({
            topic: topic,
            content: content,
            category: 'daily_blog',
            approved: true,
            likedBy: [],
            dislikedBy: [],
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log("Blog post inserted successfully!");
    } catch (e) {
        console.error("Error inserting blog post:", e);
    }
}

addBlogPost();
