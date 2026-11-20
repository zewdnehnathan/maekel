# Food & Market — QA remaining (as of 20 Nov 2026)

Snapshot against [mvp-qa-guide.md](./mvp-qa-guide.md) Groups D, E, and F.

Phones / roles: [qa-test-phones-and-roles.md](./qa-test-phones-and-roles.md).

---

## Status

| Area | Stories ready | Notes |
|------|---------------|--------|
| Food D + E | **7 / 7** | D04 ops force-deliver without OTP implemented (rider path still OTP-only) |
| Market F | **6 / 6** | F02 real chat + F06 my-ads cache merge fixed |

**Setup only (not a code gap):** Food still needs create merchant → assign owner → menu → grant `food_rider`. No demo shops.

**Deploy needed for demo host:**

- `food-service` — ops advance may mark `onTheWay` → `delivered`
- `chat-service` — remove demo seller auto-reply

Until those redeploy, local/API client fixes for F06 + chat polling still help; D04 last step and fake chat replies need the service builds above.

---

## Soft (optional, not blocking AC)

**D02 modifiers:** Customer UI can pick options if present; merchant create/edit menu does not expose modifiers yet. Cart AC still passes without them.

---

## What was fixed (20 Nov 2026)

### F06 — Manage my listings
Catalog poll no longer wipes pending / rejected / sold. After each public catalog refresh, signed-in users re-merge `/v1/market/my-ads` (and threads). Sign-out clears private cache.

### F02 — Open listing + contact seller
Removed demo seller auto-reply (chat-service + in-memory). Chat screen polls messages every 2s while open. Inbox threads refresh with the market poll when signed in.

### D04 — Follow order + delivery code
Ops force-advance can move `onTheWay` → `delivered` without OTP. Rider complete remains OTP-gated. Order detail button label: “Ops: mark delivered (no OTP)” on that step.

---

## Ready checklist

- Food: pin coverage, COD checkout, cancel rules, merchant console, rider OTP handover, ops deliver override
- Market: categories + filters, favorites, sell → pending → approve, real two-way chat (after chat-service deploy), My ads statuses, ops reports / reject reason
