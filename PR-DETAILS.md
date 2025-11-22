Bill Scheduling & Auto-Payment

Overview
Adds a self-contained scheduling layer to Smart-Utility-Payment, enabling users to create recurring STX payments with manual or auto-execution from escrow. No external contracts or traits.

Technical Implementation
- Storage:
  - next-schedule-id (uint), schedules map, autopay-prefs map, escrow map
- Public functions:
  - create-schedule, set-autopay-pref, cancel-schedule, deposit-to-escrow, withdraw-from-escrow, pay-schedule-now, run-autopay
- Read-only functions:
  - get-schedule, get-autopay-pref, get-schedule-escrow, get-next-schedule-id, is-schedule-due
- Error handling:
  - err-invalid-interval u112, err-invalid-start u113, err-not-due u114, err-inactive u115, err-insufficient-escrow u116
- Clarity v3 code with validation; no cross-contract calls.

Testing & Validation
- ? Contract syntax passes clarinet check
- ? Basic test structure created for scheduling features  
- ? CI workflow runs clarinet check on push
- ? CRLF ? LF normalization for modified files

Security & Limitations
- Autopay relies on escrow pre-funding; insufficient escrow prevents settlement.
- Manual payments require payer's signature; schedules cannot debit arbitrary principals.
- All scheduling functions respect existing contract pause state.
