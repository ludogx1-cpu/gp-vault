# Agent Handoff

Date: 2026-08-19

## Context

The user asked to fix all issues found in a review of `gp-vault-main`.

## Fixed

- Restored `firebase.json` Firestore and Hosting deployment configuration that had been removed.
- Tightened `firestore.rules` for `/users/{userId}`:
  - users can only create lightweight profile fields;
  - server-owned fields such as balances, XP, role, reward timestamps, and pet stats cannot be client-created;
  - users can no longer delete their own user document.
- Added explicit anonymous-user checks to admin routes so unauthenticated requests return 401 instead of 500.
- Removed hardcoded offerwall fallback secrets:
  - `BITCOTASKS_SECRET` is now required from the environment;
  - `TIMEWALL_SECRET` is now required from the environment.
- Reduced offerwall debug logging so headers, signatures, and full signed payloads are not persisted.
- Tightened offerwall IP matching to exact normalized IPs instead of substring matching.
- Switched offerwall signature/hash comparison to `crypto.timingSafeEqual`.
- Fixed Data Connect sync so Firestore `FieldValue.increment(...)` transform sentinels are resolved to concrete numbers before syncing.
- Fixed withdrawal failure handling so a Firestore refund is followed by a Data Connect resync.
- Fixed `faucetService` importing only `syncUserBalances` while calling `syncPetStats`.
- Added backend regression tests for:
  - anonymous admin route rejection;
  - Data Connect sync handling increment transforms.

## Verification Run

- `node --check backend\src\routes\offerwallRoutes.js`
- `node --check backend\src\utils\dataConnectSync.js`
- `node --check backend\src\services\faucetService.js`
- `node --check backend\src\routes\adminRoutes.js`
- `npm test -- --runInBand` from `backend` passed: 6 suites, 20 tests.
- `flutter analyze` passed.
- `flutter test` passed: 9 tests.

## Follow-Up For Next Agent

- Run Firebase rules tests or deploy validation if Firebase emulator/tooling is available.
- Confirm production environment contains `BITCOTASKS_SECRET` and `TIMEWALL_SECRET` before deploying the backend.
- Review whether client-side profile creation needs any extra non-sensitive fields beyond the current allowlist in `firestore.rules`.
