# Chrome Web Store submission: Golden Paw

Upload the zip of `chrome_extension/` (version 1.0.3: new icon and the new Golden Paw look). Claude can make it for you.
Developer dashboard: https://chrome.google.com/webstore/devconsole

## Store listing

**Name:** Golden Paw: Virtual Shiba Pet

**Summary (132 chars max):**
Look after your Golden Paw Shiba from your toolbar: feed, play and boop your pet. Optional DOGE faucet for adults (18+).

**Category:** Entertainment

**Support URL:** https://goldenpaw.dog/support/

**Description:**
Your Golden Paw Shiba, one click away in your Chrome toolbar.

Golden Paw is a free virtual pet game for dog lovers. Raise your own Shiba, watch it grow, and share your real dog with a friendly community in The Book Of Dog. This extension lets you check on your pet without opening the full site.

🐾 LOOK AFTER YOUR SHIBA
• See your pet's hunger, happiness and energy at a glance
• Feed, play with and boop your Shiba straight from the toolbar
• Watch your pup grow through 8 life stages, from sleepy baby to wise old dog

🔔 GENTLE REMINDERS
• Get a nudge when your Shiba is hungry, sad or tired

📖 MORE FROM GOLDEN PAW
• Jump straight to The Book Of Dog, where dog lovers share photos of their real dogs (with a new photo challenge from Zen every Monday)
• Quick link to our free dog care guide

🪙 OPTIONAL EXTRA FOR ADULTS (18+)
• A 5-minute faucet that pays small Dogecoin rewards, saved to your Golden Paw Vault or sent to FaucetPay
• A countdown shows when the next claim is ready, and you can get a notification when it is
• A quick captcha keeps it fair for real players. You never need to deposit anything, and it's entirely optional.

🔐 SIMPLE, SAFE SIGN-IN
• Sign in with Google or your Golden Paw email and password, using the same account as goldenpaw.dog

Good to know
• You need a free Golden Paw account. Sign up at https://goldenpaw.dog
• Golden Paw is entertainment, not an investment, and nothing here is financial advice. Faucet rewards are small and depend on the current DOGE price.
• Golden Paw is not a wallet, never mines cryptocurrency on your computer, and will never ask for your private keys or seed phrase.
• Made in the UK by Golden Paw Studios. Help and support: https://goldenpaw.dog/support/

Privacy policy: https://goldenpaw.dog/privacy/

**Graphic assets**
- Icon 128×128: `icons/icon128.png`
- Small promo tile 440×280: `store/promo-tile-440x280.png`
- Marquee 1400×560 (optional): `store/marquee-1400x560.png`
- Screenshot 1280×800: `store/screenshot-1280x800.png` (or take one after signing in with your real account, so it shows real data).

## Privacy practices tab

**Single purpose:**
Lets Golden Paw users look after their Golden Paw pet and claim the Golden Paw faucet from the browser toolbar.

**Permission justifications**
- `storage`: keeps the user signed in and remembers the faucet cooldown, payout choice and FaucetPay address.
- `alarms`: wakes the extension when the 5-minute faucet cooldown ends and every 30 minutes to check the pet's needs.
- `notifications`: tells the user the faucet is ready or their pet needs care.
- `identity`: opens Google's sign-in window so users who joined Golden Paw with Google can sign in.
- Host `golden-paw-vault.onrender.com`: the Golden Paw backend that returns pet status and processes faucet claims.
- Hosts `identitytoolkit.googleapis.com` and `securetoken.googleapis.com`: Firebase Authentication, for signing in to the user's Golden Paw account.

**Remote code:** No. All JavaScript ships in the package. The captcha is shown in an iframe of https://goldenpaw.dog/captcha.html.

**Data usage (tick these):**
- Personally identifiable information: email address (sign-in)
- Authentication information: password (sent only to Firebase Authentication, never stored), sign-in tokens
- Financial and payment information: FaucetPay address (only when the user chooses FaucetPay payouts)

Certify: not sold to third parties, not used for unrelated purposes, not used for creditworthiness.

**Privacy policy URL:** https://goldenpaw.dog/privacy/
