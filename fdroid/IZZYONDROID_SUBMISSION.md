# 🚀 IzzyOnDroid Form Submission Data

Direct Link to Form:
👉 **https://codeberg.org/IzzyOnDroid/repodata/issues/new?template=.forgejo%2fissue_template%2fapp-inclusion-request.yaml**

---

### 1. Title
```text
[AppRequest] Golden Paw
```

---

### 2. Guidelines (Checkboxes)
- [x] **I am the developer of the app.**
- [x] **The app complies with the App Inclusion Policy.**
- [x] **The app is not already listed in the repo or issue tracker.**
- [x] **The Fastlane folder is available in the app's repo.**

---

### 3. App meta-data

#### **Link to the source code** (Required)
```text
https://github.com/ludogx1-cpu/gp-vault
```

#### **Link to app in another app store** (Optional)
```text
https://goldenpaw.dog/
```

#### **License used** (Required)
```text
MIT
```

#### **Categories** (Select from dropdown)
* Select: `Money`
* Select: `Games`

#### **Summary** (Required)
```text
Earn DOGE, care for your virtual Shiba Inu pet, and grow your staking vault.
```

#### **Description** (Required)
```markdown
Welcome to Golden Paw — the ultimate Dogecoin faucet, staking vault, and virtual Shiba Inu companion ecosystem!

🐾 RAISE YOUR VIRTUAL SHIBA INU
• Adopt your very own digital Shiba Inu companion.
• Feed, bathe, pet, and play with your Shiba to keep its happiness and energy high.
• Level up your pet through multiple evolution stages from puppyhood to adult.
• Equip stylish accessories, sunglasses, luxury coats, and royal crowns.

🪙 DOGECOIN FAUCET & REWARDS
• Claim DOGE directly from the faucet at regular intervals.
• Daily check-in bonuses and milestone multiplier rewards.
• Complete quick tasks and offerwalls to supercharge your earnings.
• Clean, transparent transactions with fast payouts.

🔒 THE GOLDEN VAULT & STAKING
• Stake your DOGE in The Vault to earn competitive daily interest yields.
• Flexible compounding options to grow your holdings over time.
• Live yield calculations and transparent staking analytics.
```

---

### 4. Technical instructions

#### **Build instructions** (Required)
```bash
# Prerequisites: Flutter SDK 3.47.2, Java 17

# 1. Clone repository
git clone https://github.com/ludogx1-cpu/gp-vault.git
cd gp-vault

# 2. Get dependencies
flutter pub get

# 3. Build release APK (split per ABI to stay under 30 MB)
flutter build apk --release --split-per-abi
# Output APKs located in: build/app/outputs/flutter-apk/
```

---

### 5. AI Tools Usage

#### **Assistance Level** (Select from dropdown)
* Select: `Moderate – Used for specific tasks or modules`

#### **"AI" Tool(s)** (Optional)
```text
Claude / Gemini
```

#### **What did the tools help with, and how?** (Optional)
```text
Assisted with UI component layout, Fastlane metadata structuring, code refactoring, and CI build automation.
```

#### **AI Accountability** (Checkboxes)
- [x] **The human developer(s) reviewed and edited all "AI"-generated outputs**
- [x] **The human developer(s) ran manual tests and manually verified all changes**

---

### 6. Further Notices (Optional)
```markdown
* Official release APKs are automatically built via GitHub Actions (`.github/workflows/release-apk.yml`) with `--split-per-abi` and published on GitHub Releases for release tags (`v*`). The primary target `GoldenPaw-arm64-v8a.apk` binary is attached to https://github.com/ludogx1-cpu/gp-vault/releases/tag/v1.1.1 (~36.5 MB, containing Flutter runtime, Google Maps/Firebase services, and graphic assets).
* Fastlane metadata (512x512 app icon, 1024x500 feature banner, phone screenshots, title, and descriptions) is included in the source repo under `fastlane/metadata/android/en-US/`.
* Anti-features note: The app utilizes Firebase for push notifications and account data synchronization, and interacts with Dogecoin payout networks (`NonFreeNet`, `Tracking`).
```
