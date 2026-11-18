# QA test phones & roles

Use these numbers on **https://luxury-phoenix-403a4a.netlify.app** (or local) against **https://maekel-api.onrender.com**.

| Always the same | Value |
|-----------------|--------|
| OTP code | `123456` |
| Country code | `+251` |
| App entry | 9-digit local number (e.g. `911111111`) |

After granting a role in **Staff**, the target user must **sign out → OTP again** so the JWT picks up the new role.

Staff grants now **persist across Render restarts**. If `role_grants` only shows the four defaults (`ride_passenger`, `food_customer`, `market_buyer`, `market_seller`), the staff role was never granted (or was wiped by an older API build) — grant again from Staff.

---

## 1. Bootstrap admin (already wired)

| Local | E.164 | Roles (auto on login) | What to test |
|-------|-------|------------------------|--------------|
| `999999999` | `+251999999999` | `platform_admin`, `market_moderator`, `food_ops`, `food_merchant`, `food_rider` (+ default customer roles) | Staff grants, Market ops, Food ops, full admin paths |

This phone is set via `ADMIN_PHONES` on Render. Log in first with it, then create/grant the accounts below.

---

## 2. Suggested test roster (create these)

Every new user also gets defaults: `ride_passenger`, `food_customer`, `market_buyer`, `market_seller`.

| # | Local (type in app) | E.164 | Grant these roles (Staff) | Persona | What to test |
|---|---------------------|-------|---------------------------|---------|--------------|
| 1 | `911111111` | `+251911111111` | *(none — defaults only)* | Everyday customer | Ride passenger, Food order, Market buy/sell |
| 2 | `922222222` | `+251922222222` | `market_moderator` | Market reviewer | Market ops: approve/reject ads, reports, categories |
| 3 | `933333333` | `+251933333333` | `market_ops` | Market ops (non-moderator label) | Same Market ops access as moderator |
| 4 | `944444444` | `+251944444444` | `food_ops` | Food ops | Food ops board, onboard merchant, assign owner, support cancel |
| 5 | `955555555` | `+251955555555` | `food_merchant` | Restaurant staff | Merchant console: **only their** menu + accept/prepare/ready |
| 6 | `966666666` | `+251966666666` | `food_rider` | Food rider | Claim job → pickup → on the way → OTP + COD |
| 7 | `977777777` | `+251977777777` | *(defaults only)* | Second customer | Place orders against restaurant #5; Market buyer |
| 8 | `988888888` | `+251988888888` | `food_merchant` | Second restaurant | Prove they **cannot** edit restaurant #5’s menu |

**Optional**

| # | Local | E.164 | Grant | Persona |
|---|-------|-------|-------|---------|
| 9 | `900000001` | `+251900000001` | `platform_admin` | Backup admin (only if needed) |

Ride “driver” is **not** a staff role — any logged-in user can open Ride → Driver tab. Use customer #1 or #7 for that.

---

## 3. How to create each account

1. Open the web app → enter **local** digits → OTP `123456`.
2. Log in as bootstrap admin `999999999`.
3. Home → **Staff**.
4. Enter the **local** 9 digits → choose role → **Grant**.
5. That person signs out and OTP again.

Repeat grants if someone needs more than one staff role.

---

## 4. Food restaurant ownership (important)

Menu edits are **owner-only**. Do not rely on “Claim a store” for restaurant staff.

1. Staff: grant `food_merchant` to `955555555`.
2. That user OTP once (so they exist in the DB).
3. Food ops (`944444444` or admin): **Food ops** → create merchant **or** Assign owner phone = `955555555`.
4. Restaurant staff (`955555555`) opens **Merchant** → only their menu.

Second restaurant test: assign `988888888` to a different merchant; confirm they cannot change the first restaurant’s dishes.

---

## 5. Happy-path scripts by role

### A. Customer (`911111111`)
- Market: post an ad → wait for moderator.
- Food: pick delivery pin → order COD → note OTP on order detail.
- Ride: request trip (separate driver session helps).

### B. Market moderator (`922222222`)
- Home → Market ops → Approve pending ads / handle reports.

### C. Food ops (`944444444`)
- Use **Food ops** (not Merchant console).
- Onboard restaurant → set **Owner phone** `955555555` (or Assign owner on the list).
- Order board: support cancel / clear rider if needed.
- Merchant console is for restaurant staff only; ops should not “claim” other stores.

### D. Restaurant (`955555555`)
- Merchant → Add dishes/prices → Accept → Preparing → Ready.
- Confirm they do **not** see other restaurants’ menus.

### E. Food rider (`966666666`)
- Food → Rider → Claim ready job → Pickup → On the way → Complete with customer OTP + COD.

### F. Platform admin (`999999999`)
- Staff grants/revokes.
- Market ops + Food ops shortcuts on Home.

---

## 6. Role cheat sheet

| Role | How you get it | Main screens |
|------|----------------|--------------|
| Defaults (customer/seller/passenger) | Automatic on OTP | Ride / Food / Market customer flows |
| `platform_admin` | `ADMIN_PHONES` or Staff | Staff, all ops |
| `market_moderator` / `market_ops` | Staff | `/market/ops` |
| `food_ops` | Staff | `/food/ops` |
| `food_merchant` | Staff + owner assign | `/food/console` (own store only) |
| `food_rider` | Staff | `/food/rider` |
| Ride driver | No staff role | `/ride/driver` |

---

## 7. Printable checklist

- [ ] `999999999` admin login + Staff works  
- [ ] `911111111` customer Market + Food + Ride  
- [ ] `922222222` Market approve  
- [ ] `944444444` Food ops onboard + assign owner `955555555`  
- [ ] `955555555` menu CRUD + kitchen queue  
- [ ] `966666666` rider OTP delivery  
- [ ] `988888888` cannot edit other restaurant  
- [ ] After every grant: target user re-OTP  

---

*Demo API may sleep on Render free tier — first request after idle can take ~30–60s.*
