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
    const topic = "TimeWall Payout Status & 2x XP Boost";
    const content = `
Hey Golden Paw fam! Just a quick update: TimeWall payouts are temporarily suspended while Golden Paw undergoes routine background and ID checks with our provider. You can absolutely still complete tasks and earn from TimeWall in the meantime—your earnings are safe!

Please note that our main features are completely unaffected. You can still use the Golden Paw faucet, watch ads, roll the daily promo, and withdraw your earnings from those as normal!

To apologize for the delay with TimeWall, all pets will get a **2x XP boost** for the next week. Payouts will resume as soon as this is sorted out. Thank you for your patience!
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
