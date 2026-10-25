# 🐾 Golden Paw — Appy Pie & F-Droid Publishing Guide

This guide details all assets, metadata, requirements, and exact step-by-step submission procedures to get **Golden Paw** published on both **Appy Pie** and **F-Droid**.

---

## 📦 Ready-to-Use Publishing Assets

All metadata and graphics have been generated and packaged into standard directories:

| Asset | Specifications | Location |
|---|---|---|
| **App Title** | `Golden Paw` | [`fastlane/metadata/android/en-US/title.txt`](fastlane/metadata/android/en-US/title.txt) |
| **Short Description** | 72 chars (App stores max 80) | [`fastlane/metadata/android/en-US/short_description.txt`](fastlane/metadata/android/en-US/short_description.txt) |
| **Full Description** | Markdown / Feature highlights | [`fastlane/metadata/android/en-US/full_description.txt`](fastlane/metadata/android/en-US/full_description.txt) |
| **App Icon** | 512 × 512 PNG (Square, Hi-Res) | [`fastlane/metadata/android/en-US/images/icon.png`](fastlane/metadata/android/en-US/images/icon.png) |
| **Feature Graphic** | 1024 × 500 PNG (Banner) | [`fastlane/metadata/android/en-US/images/featureGraphic.png`](fastlane/metadata/android/en-US/images/featureGraphic.png) |
| **Open Source License** | MIT License | [`LICENSE`](LICENSE) |
| **F-Droid Build Recipe** | F-Droid YAML specification | [`fdroid/com.goldenpaw.app.yml`](fdroid/com.goldenpaw.app.yml) |
| **Automated Cloud Builder**| GitHub Actions Release Workflow | [`.github/workflows/release-apk.yml`](.github/workflows/release-apk.yml) |
| **Existing Release APK** | Signed Android APK (74.5 MB) | [`build/web/golden-paw.apk`](build/web/golden-paw.apk) |
| **Privacy Policy URL** | Live HTTPS URL | `https://goldenpaw.dog/privacy/` |
| **Terms of Service URL**| Live HTTPS URL | `https://goldenpaw.dog/terms/` |
| **Official Website / PWA** | Live HTTPS URL | `https://goldenpaw.dog/` |

---

## 🥧 Part 1: Publishing on Appy Pie

Appy Pie offers two main ways to distribute apps:
1. **Appy Pie App Market**: Hosting your app in Appy Pie's open developer marketplace.
2. **Appy Pie Publishing Assistance**: Appy Pie concierge services to submit to Google Play and Apple App Store on your behalf.

### Step-by-Step Submission to Appy Pie:

1. **Sign in to Appy Pie**:
   - Go to [Appy Pie](https://www.appypie.com/) and log in (or create a developer account).
   - Navigate to the **Developer Dashboard** or **App Market** section.

2. **Create / Submit App Listing**:
   - Click **Submit App** / **Add New Listing**.
   - Select **Android** (or **PWA / Web App** if submitting the web version).

3. **Fill in App Details**:
   - **App Name**: `Golden Paw`
   - **Tagline / Short Description**: 
     > `Earn DOGE, care for your virtual Shiba Inu pet, and grow your staking vault.`
   - **Category**: Select `Finance`, `Entertainment`, or `Casual / Simulation Games`.
   - **Content Rating**: Everyone / Teen (due to Dogecoin cryptocurrency rewards).
   - **Tags / Keywords**: `doge, dogecoin, crypto faucet, shiba inu, staking, virtual pet, rewards`
   - **Full Description**: Paste the content of [`fastlane/metadata/android/en-US/full_description.txt`](fastlane/metadata/android/en-US/full_description.txt).

4. **Upload Graphics & Media**:
   - **App Icon**: Upload [`fastlane/metadata/android/en-US/images/icon.png`](fastlane/metadata/android/en-US/images/icon.png) (512x512).
   - **Feature Banner / Graphic**: Upload [`fastlane/metadata/android/en-US/images/featureGraphic.png`](fastlane/metadata/android/en-US/images/featureGraphic.png) (1024x500).

5. **Provide URLs & Binaries**:
   - **Package File (APK)**: Upload `golden-paw.apk` (or provide the direct link `https://goldenpaw.dog/golden-paw.apk`).
   - **Privacy Policy**: `https://goldenpaw.dog/privacy/`
   - **Terms of Service**: `https://goldenpaw.dog/terms/`
   - **Website**: `https://goldenpaw.dog/`

6. **Submit for Review**:
   - Review all fields and click **Submit**. Appy Pie reviews submissions typically within 24–48 hours.

---

## 🤖 Part 2: Publishing on F-Droid

F-Droid is the premier Android app store dedicated exclusively to **Free and Open-Source Software (FOSS)**.

### Crucial Architectural Consideration for Golden Paw:
F-Droid has strict policies regarding third-party services:
- **Source Code**: F-Droid builds apps *directly from source* on their build server (`fdroiddata`).
- **Dependencies**: Golden Paw contains Firebase services (`firebase_analytics`, `google_sign_in`, `google_maps_flutter`). 
  - In F-Droid, apps connecting to proprietary services or tracking SDKs require **Anti-Feature flags** (`AntiFeatures: [NonFreeNet, Tracking]`), which we have already declared in `fdroid/com.goldenpaw.app.yml`.

### Two Recommended Paths for F-Droid:

### 🌟 Path A: Submit to IzzyOnDroid (Fastest & Highly Recommended)
**IzzyOnDroid** is an official F-Droid partner repository directly integrated into the F-Droid app ecosystem. IzzyOnDroid is specifically tailored for open-source apps distributed via GitHub Releases with Firebase/Google services.

1. **Push a Release Tag to GitHub**:
   - Create a git tag and push it:
     ```bash
     git tag v1.1.1
     git push origin v1.1.1
     ```
   - The `.github/workflows/release-apk.yml` workflow will automatically compile `GoldenPaw-release.apk` and attach it to your GitHub Release!
2. **Submit to IzzyOnDroid (Codeberg)**:
   - *Note: IzzyOnDroid recently migrated from GitLab to Codeberg.*
   - Go to the active tracker: 👉 **[IzzyOnDroid Codeberg Issue Tracker](https://codeberg.org/IzzyOnDroid/repodata/issues/new/choose)**
   - Click **"App Inclusion Request"** (or click **"New Issue"**).
   - Enter:
     - **App Name**: Golden Paw
     - **Package ID**: `com.goldenpaw.app`
     - **Git Repository**: `https://github.com/ludogx1-cpu/gp-vault`
     - **License**: MIT
     - **Release Asset Name**: `GoldenPaw-release.apk`
3. **Approval**:
   - The IzzyOnDroid maintainer inspects the repo and approves it. From then on, every new release tag you push automatically updates in the F-Droid client for all users!

---

### 🏛️ Path B: Official F-Droid Repository (`fdroiddata`)
To submit Golden Paw directly to the official core F-Droid repository:

1. **Create an account on GitLab**:
   - Go to [GitLab.com](https://gitlab.com) and sign in.
2. **Fork `fdroiddata`**:
   - Navigate to [https://gitlab.com/fdroid/fdroiddata](https://gitlab.com/fdroid/fdroiddata) and click **Fork**.
3. **Add the Metadata File**:
   - In your fork, create a new file: `metadata/com.goldenpaw.app.yml`.
   - Paste the contents of [`fdroid/com.goldenpaw.app.yml`](fdroid/com.goldenpaw.app.yml).
4. **Submit a Merge Request**:
   - Commit the file to a branch (e.g. `add-golden-paw`).
   - Open a Merge Request against `fdroid/fdroiddata:master`.
   - Title: `Add com.goldenpaw.app (Golden Paw)`
   - The F-Droid automated CI will run checks, build the app, and F-Droid maintainers will review the inclusion.

---

## 🚀 Summary Checklist

- [x] App Icon generated (512×512 PNG)
- [x] Feature Banner generated (1024×500 PNG)
- [x] Fastlane Store Text prepared (Title, Short Description, Full Description)
- [x] Open-source MIT License added
- [x] F-Droid Metadata YAML prepared (`fdroid/com.goldenpaw.app.yml`)
- [x] GitHub Actions automated APK release workflow configured (`.github/workflows/release-apk.yml`)
- [x] Privacy Policy & Terms URLs active on `https://goldenpaw.dog/`
