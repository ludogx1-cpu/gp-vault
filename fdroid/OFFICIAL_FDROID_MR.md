# 🏛️ Official F-Droid (`fdroiddata`) Submission Guide

F-Droid builds all applications directly from source code using automated build workers.

---

## 🛠️ Step 1: Push Your Code & Release Tag to GitHub

Ensure all new files (`LICENSE`, `.fdroid.yml`, `fastlane/`, `.github/workflows/`) are committed and pushed to your GitHub repository:

```bash
git add .
git commit -m "Add F-Droid metadata, open-source license, and store assets"
git push origin feature/animated-puppy  # or main

# Create and push the release tag matching the version in pubspec.yaml (1.1.1)
git tag v1.1.1
git push origin v1.1.1
```

---

## 🍴 Step 2: Fork `fdroiddata` on GitLab

1. Sign in to your account on [GitLab](https://gitlab.com/).
2. Navigate to the official F-Droid data repository:
   👉 **https://gitlab.com/fdroid/fdroiddata**
3. Click the **Fork** button (top right) to create a fork under your GitLab namespace.

---

## 📄 Step 3: Add the Golden Paw Recipe File

1. In your forked repository, switch to a new branch, e.g. `add-goldenpaw`.
2. Click **Add file** -> **New file**.
3. Name the file:
   ```
   metadata/com.goldenpaw.app.yml
   ```
4. Paste the recipe below:

```yaml
Categories:
  - Money
  - Games
License: MIT
AuthorName: Golden Paw Team
AuthorEmail: support@goldenpaw.dog
AuthorWebSite: https://goldenpaw.dog
SourceCode: https://github.com/ludogx1-cpu/gp-vault
IssueTracker: https://github.com/ludogx1-cpu/gp-vault/issues
Changelog: https://github.com/ludogx1-cpu/gp-vault/releases
Donate: https://github.com/sponsors/ludogx1-cpu

AutoName: Golden Paw

RepoType: git
Repo: https://github.com/ludogx1-cpu/gp-vault.git

AntiFeatures:
  NonFreeNet:
    en-US: Relies on Firebase backend services and third-party Dogecoin network APIs.
  Tracking:
    en-US: Contains Firebase Analytics.

Builds:
  - versionName: 1.1.1
    versionCode: 3
    commit: v1.1.1
    output: build/app/outputs/flutter-apk/app-release.apk
    srclibs:
      - flutter@stable
    rm:
      - ios
      - linux
      - macos
      - web
      - windows
    prebuild:
      - flutterVersion=$(sed -n -E "s/.*flutter-version:\ '(.*)'/\1/p" .github/workflows/release-apk.yml)
      - '[[ $flutterVersion ]]'
      - git -C $$flutter$$ checkout -f $flutterVersion
      - export PUB_CACHE=$(pwd)/.pub-cache
      - $$flutter$$/bin/flutter config --no-analytics
      - $$flutter$$/bin/flutter pub get --enforce-lockfile
    scandelete:
      - .pub-cache
    build:
      - export PUB_CACHE=$(pwd)/.pub-cache
      - $$flutter$$/bin/flutter build apk --release

AutoUpdateMode: Version
UpdateCheckMode: Tags
UpdateCheckData: pubspec.yaml|version:\s.+\+(\d+)|.|version:\s(.+)\+
CurrentVersion: 1.1.1
CurrentVersionCode: 3
```

5. Commit the file: `Add metadata for com.goldenpaw.app`.

---

## 📬 Step 4: Open the Merge Request (MR)

1. On your forked repository page, click **Create Merge Request**.
2. Source branch: `your-username/fdroiddata:add-goldenpaw`
3. Target branch: `fdroid/fdroiddata:master`
4. Set the Title:
   ```
   Add com.goldenpaw.app (Golden Paw)
   ```
5. Set the Description:
   ```markdown
   ### Application Summary
   * **App Name:** Golden Paw
   * **Package:** com.goldenpaw.app
   * **License:** MIT
   * **Source:** https://github.com/ludogx1-cpu/gp-vault
   * **Tag:** v1.1.1

   ### Anti-Features Declared
   * `NonFreeNet`: Interacts with Firebase and third-party crypto/offerwall servers.
   * `Tracking`: Uses Firebase Analytics.

   Fastlane metadata (descriptions, icon, feature graphic, and screenshots) is already located at `fastlane/metadata/android/en-US/` in the source repository.
   ```
6. Submit the Merge Request.

The F-Droid CI bot will run automated linting (`fdroid checkupdates`, `fdroid lint`, `fdroid build`) and test compiling the app from source. F-Droid reviewers will then approve the MR.
