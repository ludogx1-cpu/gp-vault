const { admin } = require('./firebaseService');

const AI_USERNAMES = [
  "DogeLover99", "CryptoKing", "MoonWalker", "ShibaFanatic", 
  "DiamondHands", "FaucetHunter", "GoldenPawPro", "SatoshiN", 
  "Hodler4Life", "MuchWow"
];

const AI_MESSAGES = [
  "Just claimed my 5 min faucet, the rewards are so good here!",
  "Has anyone tried the new blog page? It looks amazing.",
  "I'm staking my DOGE in the Vault, the 8.5% APY is crazy 🚀",
  "Doge to the moon! 🐕🌕",
  "Remember to feed your Shiba so it doesn't get sick guys.",
  "I just got a 20% referral bonus from my friend claiming! Easiest passive income.",
  "Does anyone know when the next update is?",
  "Booping the nose gives 0.002 DOGE, don't miss out every 30 mins!",
  "Just hit level 10 on my Dogeogotcha, the XP boosts are totally worth it.",
  "What is everyone's favorite trick for the pet?",
  "I'm saving up for the Royal Crown in the shop 😎",
  "If you leave the tab open, does the pet still wander around?",
  "This is the cleanest faucet I've ever used. No annoying popups!"
];

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function startAiChatService() {
  console.log("AI Chat Service started.");

  const scheduleNextMessage = () => {
    // Random delay between 5 and 15 minutes
    const delayMinutes = getRandomInt(5, 15);
    const delayMs = delayMinutes * 60 * 1000;

    setTimeout(async () => {
      try {
        const username = AI_USERNAMES[getRandomInt(0, AI_USERNAMES.length - 1)];
        const message = AI_MESSAGES[getRandomInt(0, AI_MESSAGES.length - 1)];

        await admin.firestore().collection('chat_messages').add({
          chat_username: username,
          message: message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          is_ai: true // internal flag, invisible to frontend
        });
        
        console.log(`[AI Chat] Posted message as ${username}`);
      } catch (error) {
        console.error("Error posting AI chat message:", error);
      } finally {
        // Schedule the next one regardless of success or failure
        scheduleNextMessage();
      }
    }, delayMs);
  };

  // Start the first cycle
  scheduleNextMessage();
}

module.exports = { startAiChatService };
