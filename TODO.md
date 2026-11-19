# To do

## Waiting on others

- [ ] **Turn TimeWall back on** once TimeWall has finished verifying the owner's ID.
  - Unlock the TimeWall button in `lib/screens/offerwall_hub_page.dart` and add
    `TimewallQuickLinksWidget` back below it (`lib/widgets/ads/timewall_quick_links.dart`).
  - Unlock the "TimeWall Clicks" button in `lib/screens/ptc_earn_page.dart`
    (the comment there has the link to restore).
  - The publisher ID (`oid`) in the links is already correct.

## Owner tasks (not in the code)

- [ ] **Update the keystore backup.** Copy the re-locked `android/app/release.keystore`
  and `android/key.properties` from the working copy over the older backup copy,
  so the backup opens with the new password. Never commit either file.
- [ ] Keep the new keystore password in a password manager. Without it, app
  updates can't be signed.

## Done

- [x] Removed the hard-coded keystore password from the release workflow and
  changed the keystore password (GitHub secrets updated, release build passing).
- [x] Release workflow checks the keystore and password early with clear errors.
- [x] Offerwalls page shows only TimeWall, locked as "Coming soon".
