const { admin } = require('./firebaseService');

const AI_USERNAMES = [
  "DogeLover99", "CryptoKing", "MoonWalker", "ShibaFanatic", 
  "DiamondHands", "FaucetHunter", "GoldenPawPro", "SatoshiN", 
  "Hodler4Life", "MuchWow"
];

const AI_MESSAGES = [
  "Just claimed my 5 min faucet, the rewards are so good here!",
  "Has anyone tried the new blog page? It looks amazing.",
  "I'm staking my DOGE in the Vault, the 33% APY is crazy 🚀",
  "Doge to the moon! 🐕🌕",
  "Remember to feed your Shiba so it doesn't get sick guys.",
  "I just got a 20% referral bonus from my friend claiming! Easiest passive income.",
  "Does anyone know when the next update is?",
  "Booping the nose gives 0.002 DOGE, don't miss out every 30 mins!",
  "Just hit level 10 on my Dogeogotcha, the XP boosts are totally worth it.",
  "What is everyone's favorite trick for the pet?",
  "I'm saving up for the Royal Crown in the shop 😎",
  "If you leave the tab open, does the pet still wander around?",
  "This is the cleanest faucet I've ever used. No annoying popups!",
  "I love checking in on my Dogeogotcha every day! So cute.",
  "The smartlink bonus sponsor just paid out really well for me.",
  "Make sure to read the guides if you want to maximize earnings.",
  "Wow, the physical fetch mechanic is actually really fun to play with.",
  "Does anyone else have the luxury coat for their Shiba? It looks so premium.",
  "I've been harvesting my vault every week, compounding is key!",
  "I just discovered you can pet the dog by wiggling the cursor over it!",
  "Who else is grinding for that next level up on their pet?",
  "Honestly this faucet is way better than the others I've tried.",
  "I just bought some free medicine to cure my sick Shiba.",
  "Are you guys holding your DOGE or converting it to something else?",
  "Don't forget the 5 min cooldown timer is perfect for multitasking.",
  "I love that we can track our reward history now, helps a lot.",
  "The new Timewall integration is awesome, so many tasks to do!",
  "Just transferred some DOGE from my Offerwall balance to the Bank. Smooth.",
  "Has anyone tried the Timewall surveys yet? They pay pretty well.",
  "Love the new Bank update! Much easier to track my earnings.",
  "I'm checking Timewall every day now, the rewards are piling up.",
  "Did anyone catch that Chat Rain earlier? Thanks Admin! 🌧️",
  "I've been grinding PTC ads all morning. It really adds up.",
  "Is the Swear Jar shared randomly or equally? I got some DOGE from it today.",
  "Just reached my first withdrawal! So happy.",
  "The Dogeogotcha is literally the best part of this faucet.",
  "Make sure to do your PTC ads every day for the streak bonus!",
  "I almost forgot to boop the nose today, thanks for the reminder chat!",
  "Anyone else addicted to watching their Bank balance grow?",
  "I'm totally going to win the weekly leaderboard this time!",
  "Who else is trying to get top 5 on the leaderboard?",
  "I need that 50 DOGE from the leaderboard prize, I'm feeding my pet constantly.",
  "DogeLover99 is always so high on the leaderboard, how do they do it?",
  "Just checked the leaderboard, it's getting competitive!"
];

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function startAiChatService() {
  console.log("AI Chat Service started.");

  const scheduleNextMessage = () => {
    // Random delay between 15 and 90 minutes (in milliseconds)
    const delayMs = getRandomInt(15 * 60 * 1000, 90 * 60 * 1000);

    setTimeout(async () => {
      try {
        const username = AI_USERNAMES[getRandomInt(0, AI_USERNAMES.length - 1)];
        const message = AI_MESSAGES[getRandomInt(0, AI_MESSAGES.length - 1)];

        await admin.firestore().collection('chat_messages').add({
          display_name: username,
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
  setTimeout(async () => {
    try {
      const username = AI_USERNAMES[getRandomInt(0, AI_USERNAMES.length - 1)];
      const message = AI_MESSAGES[getRandomInt(0, AI_MESSAGES.length - 1)];

      await admin.firestore().collection('chat_messages').add({
        display_name: username,
        message: message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        is_ai: true
      });
      console.log(`[AI Chat] Posted initial boot message as ${username}`);
    } catch (error) {
      console.error("Error posting AI chat message:", error);
    }
    
    // Begin the regular loop
    scheduleNextMessage();
  }, 10000); // 10 seconds after boot
}

module.exports = { startAiChatService };
