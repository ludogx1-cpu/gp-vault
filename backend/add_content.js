require('dotenv').config();
const { admin } = require('./src/services/firebaseService');

const BLOG_TOPIC = "The Golden Paw Self-Discipline Guide & Savings Plan";
const BLOG_CONTENT = `Accumulating crypto is only the first step of your Web3 journey—learning how to hold and protect your portfolio from high-risk impulses is where real long-term value is unlocked. Many faucet and task sites are designed to hook you into losing your hard-earned micro-earnings on high-risk games or gambling tools.

Golden Paw is built with a different philosophy. We operate purely as a safe, transparent digital companion bank. Below is a systematic, step-by-step strategy to help you build discipline, leverage your resources safely, and grow your balance securely.

### Step 1: Secure Your Base Camp
To protect your account from bad actors and keep our collective reward pool thriving, your first priority must be strict account security.
* **Validate Instantly:** Always verify your email immediately after signing up. This security layer is required to process any withdrawals cleanly to FaucetPay.
* **Play Fair:** Never use proxies, VPNs, or automated bots. Our anti-bot and reCAPTCHA integrations immediately flag suspicious activity to preserve resources for genuine, honest users.

### Step 2: Set Up the Anti-Gambling Savings Vault
Don't keep loose crypto sitting idle in wallets where you are constantly tempted to make risky multiplayer bets or double-or-nothing plays.
* **Deposit to Protect:** Transfer your external Dogecoin balances from FaucetPay directly into the Golden Paw Bank.
* **Lock it Away:** Once stored inside your secure Golden Paw account, your funds are safely locked away from fast-paced gambling urges, functioning as a dedicated savings vault.

### Step 3: Run the Daily Earning Loop
Establish a daily habit to steadily stack your balance without risking any of your own funds.
* **Claim the Faucet:** Check in on your dashboard every 5 minutes to claim your free Dogecoin rewards.
* **Use the Premium TimeWall Portal:** We completely removed annoying, intrusive ad redirects. Navigate to the dedicated TimeWall Clicks portal to complete high-paying surveys, tasks, and quick PTC ad views.
* **Claim Daily Drops:** Log in once every 24 hours to automatically grab your Daily Doge Drops.

### Step 4: The Path to Staking & Compound Growth
Staking with Golden Paw is strictly designed to reward on-platform activity.
* **Earnings-Only Staking:** To maintain complete transparency, you can only stake what you actively earn directly through our internal faucets and tasks. External funds deposited from FaucetPay are held securely in your bank storage but cannot be moved to the staking vaults.
* **Let It Compound:** Leave your organic faucet and task earnings in the staking vault to grow over time, adding a second tier of passive compound rewards to your active savings.

### Step 5: Plan Your Safe Exit
When you have hit your milestones and are ready to cash out, do so with a structured plan.
* **Low Thresholds:** Withdrawals can be initiated cleanly back to FaucetPay as soon as your bank balance hits the low minimum limit of 1 $DOGE.
* **Withdrawal Discipline:** Only cash out when you have a specific, secure use case for your on-chain assets, avoiding the trap of moving funds back to active wallets without a plan.`;

const UPDATES = [
  {
    title: "The Temptation Shield (Golden Paw Bank)",
    message: "You can now transfer loose DOGE from FaucetPay into the Golden Paw Bank! Lock it away safely in our vault where it is shielded from impulsive gambling urges."
  },
  {
    title: "Major Dogeogotcha Mechanics Update",
    message: "Physical fetch is here! Your Shiba will run to grab the ball. We also added baby/old dog stages, speech bubbles, and made sleep/medicine 100% FREE (you get paid to do it!)."
  },
  {
    title: "TimeWall Integration",
    message: "Massive earning potential added with TimeWall! Complete surveys, tasks, and PTC clicks with no annoying ad redirects."
  }
];

async function addContent() {
  try {
    const db = admin.firestore();
    
    // 1. Add Blog Post
    await db.collection('blog_posts').add({
      content: BLOG_CONTENT,
      topic: BLOG_TOPIC,
      category: 'daily_blog',
      approved: true,
      likedBy: [],
      dislikedBy: [],
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("✅ Blog post added successfully.");

    // 2. Add Updates
    for (const update of UPDATES) {
      await db.collection('updates').add({
        title: update.title,
        message: update.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log("✅ Update " + update.title + " added successfully.");
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to upload:', error);
    process.exit(1);
  }
}

addContent();
