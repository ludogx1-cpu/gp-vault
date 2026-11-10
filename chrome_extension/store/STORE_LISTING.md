# Chrome Web Store submission: Golden Paw

Upload `golden-paw-extension-1.0.0.zip` (in `chrome_extension/dist`).
Developer dashboard: https://chrome.google.com/webstore/devconsole

## Store listing

**Name:** Golden Paw: Pet & Faucet

**Summary (132 chars max):**
Look after your Golden Paw Shiba and claim the 5-minute Dogecoin faucet from your toolbar.

**Category:** Lifestyle (or Fun)

**Description:**
Golden Paw puts your virtual Shiba and the Golden Paw faucet in your Chrome toolbar.

• See your pet's hunger, happiness and energy at a glance
• Feed, play with and boop your Shiba without opening the site
• Claim the Golden Paw faucet every 5 minutes, to your Golden Paw Vault or to your FaucetPay account
• Get a notification when the faucet is ready again or your pet needs attention

You need a free Golden Paw account from https://goldenpaw.dog. Sign in with Google or with your email and password.
Faucet rewards are small amounts of Dogecoin paid by Golden Paw and depend on the current DOGE price.
Golden Paw is not a wallet, does not mine cryptocurrency, and never asks for private keys.

**Graphic assets**
- Icon 128×128: `icons/icon128.png`
- Small promo tile 440×280: `store/promo-tile-440x280.png`
- Screenshots (at least 1, 1280×800 or 640×400): take these after signing in with your real account, so they show real data.

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
