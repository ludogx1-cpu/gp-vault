# Golden Paw review fixes — 7 September 2026

These are local changes. No deployment, payout, database migration, or production write was performed.

## Implemented

- Firestore user updates now allow explicit profile fields, with type and length checks. Reward timestamps, boosts, pending payouts, inventory and future server fields are protected by default.
- Signup creates a lightweight profile with a merge write, matching the rules and avoiding overwriting a profile created by notification registration. Existing screens already default missing balances and XP to zero.
- Profile setup and notification-token removal remain allowed. The existing admin pet unlock action retains narrowly scoped permission for the administrator's own inventory and buffs. Ordinary users cannot use it.
- Chat writes now use the moderated backend; direct client creation, modification and deletion are denied.
- Offerwall releases reread each transaction and commit its release status and balance credit together. Repeated jobs, concurrent jobs and interrupted commits cannot credit that transaction twice. The seven-day hold is unchanged.
- Failed Data Connect recovery includes the user ID and rebuilds values from the current Firestore document instead of replaying a historical balance snapshot.
- Vault withdrawals reserve funds and create a durable `withdrawal_requests` record atomically. Documented processor rejections refund once; timeouts retain the reservation for reconciliation. Successful settlement records the payout, ledger entry and total withdrawn atomically. A pending request prevents another payout until resolved.
- Payout decimal conversion no longer uses floating-point multiplication followed by floor. Vault debits accept at most eight decimal places.
- Withdrawal UI has a timeout and avoids claiming that an unknown result was declined. Bank text explains the existing pause.
- App Check activation is awaited so initialization failures are caught. Flutter context and sprite API lint issues are corrected.
- CI covers backend tests/audit, Flutter analysis/tests/build, and isolated Firestore rules tests. README startup instructions now match the service-account loader.

## Deliberately preserved or deferred

- **Bank/offerwall payments remain unconditionally disabled.** The `bankWithdraw` function and transfer backend are unchanged. A regression test asserts the payment pause and confirms it never calls the processor.
- Reward amounts, staking rates, pet mechanics, payment minimums and cooldowns are unchanged.
- Provider reversals are still handled manually as documented in the existing route comments. Automatic reversal deductions require a confirmed policy and provider protocol; they were not introduced by this patch. The original review's reversal concern remains open.
- Data Connect recovery no longer replays stale queue payloads, but this does not provide cross-database serializability. Versioned writes/outbox processing remain a separate migration for overlapping live writes.
- Mandatory App Check enforcement has not been enabled: production platform configuration must be verified before rejecting existing clients.
- A full migration of money to integer storage, broad component refactors, navigation redesign and onboarding changes remain separate work. They would add substantially more regression risk to this patch.
- The locked dependency audit reports 11 moderate advisories and no high/critical advisories. No forced dependency downgrade or lockfile update was applied. In particular, the suggested forced Firebase Admin downgrade is unsuitable for this change.

## Recovery and rollout

Apply and verify rules before enabling the new backend withdrawal flow; its `pending_withdrawal` field must be server-owned. Then deploy the backend and updated signup client together in the normal release process. Nothing here deploys automatically.

Successful payouts continue to appear in the existing `withdrawals` collection. Pending/unknown requests are stored separately in `withdrawal_requests` so they are not reported as successful payments.

A trusted operator must reconcile a `pending` or `unknown` request against FaucetPay's payout history before choosing an outcome. A timeout alone is never evidence that a payout failed. The backend-only `settleWithdrawal(id, outcome, response)` helper in `withdrawalService.js` accepts `succeeded` or `refunded`, updates the balance/logs once, and rejects conflicting terminal outcomes. Supply the confirmed processor response when settling a paid request. A `paid` record already contains processor evidence and can be settled as succeeded without resending money. Never delete the reservation or send again to resolve an uncertain result.

The rejection-code classification was checked against [FaucetPay's official v1 reference](https://faucetpay.io/page/api-documentation). No real payout was used for testing.

## Validation

- Backend: 41 tests passed across 10 suites, including concurrency, interrupted commits, timeout/refund handling, settlement recovery, exact decimal conversion, legacy retry records, cron failure responses, and the payment pause.
- Flutter: existing 9 tests passed; analysis passes with no issues.
- Release web build passed. Its optional WebAssembly dry run reports the existing `geolocator_web` dependency's `dart:html` incompatibility; the standard JavaScript build succeeds.
- Firestore: isolated demo-project emulator test passes, covering profile creation/setup, token updates/removal, invalid types and oversized values, reward-field writes/deletes, other-user access, chat forgery/modification/deletion, and the admin pet unlock exception.
- Local backend tests ran on Node 24.18.1; CI targets the project's declared Node 26. Flutter SDK is 3.47.2. Production configurations and every rendered screen have not been checked.
