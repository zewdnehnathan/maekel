# Maekel QA — Step-by-step guided runbook

**Purpose:** Walk a tester through Maekel end-to-end with **exact phones, roles, screens, and clicks**.  
**PDF copy:** [`qa-step-by-step-guide.pdf`](./qa-step-by-step-guide.pdf)  
**Companion checklist stories:** [mvp-qa-guide.md](./mvp-qa-guide.md)  
**Phone / role reference:** [qa-test-phones-and-roles.md](./qa-test-phones-and-roles.md)  
**Module bars:** [qa-ride-remaining.md](./qa-ride-remaining.md) · [qa-food-market-remaining.md](./qa-food-market-remaining.md) · [qa-events-remaining.md](./qa-events-remaining.md)

**Version:** 1.0 · **Date:** 23 Nov 2026  
**App:** https://maekel.pages.dev/  
**Backup app:** https://zewdnehnathan.github.io/maekel/  
**API:** https://maekel-api.onrender.com  

---

## 0. Before you start

| Item | Value |
|------|--------|
| OTP (always) | `123456` |
| Phone entry | **9 local digits only** (app adds `+251`) |
| Sessions | Use **2 browsers** or **1 normal + 1 Incognito** so two roles can act at once |
| Cold start | Render free tier may sleep — first API call can take **30–60s**. Wait, then retry. |
| After every Staff grant | Target user must **Sign out → OTP again** or the new role will not appear |

**Pass / fail rule:** Tick every checkbox. A module is done only when its golden path and the listed fail checks pass.

---

## 1. Who is who (test roster)

Create these accounts once (Section 2). Keep this table open while testing.

| # | Local phone | Role(s) to grant | Persona | Use for |
|---|-------------|------------------|---------|---------|
| **A** | `999999999` | *(auto)* `platform_admin`, all ops | Bootstrap admin | Staff grants, Ride/Food/Market/Events ops |
| **C1** | `911111111` | *(defaults only)* | Everyday customer | Ride passenger, Food order, Market sell/buy, Events host/RSVP |
| **C2** | `977777777` | *(defaults only)* | Second customer | Food second order, Events guest, Market buyer |
| **D** | `911111112` | *(defaults)* then Ride ops **Approve** as driver | Ride driver | Drive online, accept trips *(or reuse C2 after approve)* |
| **MM** | `922222222` | `market_moderator` | Market reviewer | Approve / reject ads |
| **FO** | `944444444` | `food_ops` | Food ops | Create restaurant, assign owner |
| **FM** | `955555555` | `food_merchant` | Restaurant | Menu + kitchen queue |
| **FR** | `966666666` | `food_rider` | Food rider | Claim → OTP delivery |
| **FM2** | `988888888` | `food_merchant` | Second restaurant | Isolation (cannot edit FM’s menu) |
| **EO** | `900000010` | `events_ops` | Events ops | Approve / reject events |

**Defaults every new user already gets:** `ride_passenger`, `food_customer`, `market_buyer`, `market_seller`, `events_attendee`, `events_organizer`.

**Tip:** Admin **A** already has `ride_ops` and is auto-approved as a Ride driver — you can use **A** as the driver for the first Ride pass if you want fewer accounts.

---

## 2. Setup — create accounts and grant roles

### 2.1 Create each phone (2 minutes each)

1. Open https://maekel.pages.dev/  
2. Enter local digits (e.g. `911111111`) → **Continue**  
3. OTP `123456` → **Verify**  
4. Confirm you land on **Home** (tiles: Ride, Market, Food, Events, Games)  
5. **Sign out** (power icon) before creating the next account  

Do this for: `911111111`, `977777777`, `922222222`, `944444444`, `955555555`, `966666666`, `988888888`, `900000010`, and optionally `911111112` (driver).

Also log in once as admin `999999999` so Staff works.

### 2.2 Grant staff roles (as Admin A)

1. Sign in as **`999999999`**  
2. Home → **Staff**  
3. For each row below: enter **local 9 digits** → choose role → **Grant**  

| Grant to | Role |
|----------|------|
| `922222222` | `market_moderator` |
| `944444444` | `food_ops` |
| `955555555` | `food_merchant` |
| `966666666` | `food_rider` |
| `988888888` | `food_merchant` |
| `900000010` | `events_ops` |

4. Tell each of those users to **Sign out → OTP again**.  

**Checks**
- [ ] Staff list shows the grants  
- [ ] After re-OTP, Home shows the correct ops shortcut (Market ops / Food ops / Events ops) when that role is present  

---

## 3. Group A — Sign-in and Home

**Actor:** C1 `911111111`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Open app signed out | Phone screen |
| 2 | Enter `911111111` → Continue | OTP screen |
| 3 | Enter wrong OTP e.g. `000000` | Clear error, stay signed out |
| 4 | Enter `123456` | Home loads |
| 5 | Open Ride, back to Home, open Food, Market, Events | No re-login; no crash |
| 6 | Sign out | Back to phone screen |

**Checks**
- [ ] Wrong OTP fails clearly  
- [ ] Correct OTP → Home  
- [ ] Module tiles work without signing in again  
- [ ] Sign out clears session  

---

## 4. Group B+C — Ride (passenger + driver)

**Actors**
- Passenger: **C1** `911111111` (Browser 1)  
- Driver: **A** `999999999` *or* dedicated driver after Ride ops Approve (Browser 2)  

### 4.1 Approve a driver (if not using admin)

1. Browser 2: sign in as future driver (`911111112` or `977777777`) → Home → **Ride** → **Drive**  
2. Confirm they **cannot** go Online (unapproved).  
3. Browser 1 (or admin): sign in as **A** `999999999` → Home → **Ride ops** → find driver → **Approve**.  
4. Driver: Sign out → OTP again → Ride → Drive → **Online**.  

**Checks**
- [ ] Unapproved driver blocked from Online  
- [ ] After Approve + re-OTP, Online works  

### 4.2 Passenger quote + request

**Passenger (C1)**

| Step | Action | Expect |
|------|--------|--------|
| 1 | Home → **Ride** | Map / request UI |
| 2 | Set **pickup** (GPS or search e.g. Bole) and **dropoff** (another Addis place) | Pins set |
| 3 | Get quote | Price in ETB, distance, ETA; Economy class |
| 4 | Tap **Request** | Searching / matching state |
| 5 | Wait for match (driver Online nearby) | Driver name / car / ETA |

**Driver (A or approved D)** — keep Online before passenger requests

| Step | Action | Expect |
|------|--------|--------|
| 1 | Ride → Drive → **Online** | Ready for offers |
| 2 | When offer appears | See pickup area + fare; accept within TTL (~45s) |
| 3 | **Accept** | Trip assigned |
| 4 | **Arrived** → **Start** → **Complete** | Status advances |
| 5 | Confirm cash | Earnings today updates |

**Passenger finish**

| Step | Action | Expect |
|------|--------|--------|
| 6 | Follow map while assigned / in progress | Driver marker updates (poll) |
| 7 | After complete, **rate** 1–5 | Rating saved |
| 8 | Ride → **Trips / History** | Trip shows fare, time, driver |

### 4.3 Ride fail / edge checks

| Step | Action | Expect |
|------|--------|--------|
| 1 | Passenger Request with **no** Online driver | Clear no-driver / timeout message |
| 2 | Passenger **Cancel** before trip starts | Trip cancelled; driver freed |
| 3 | Double-tap Request | Only **one** active trip |
| 4 | Pins far outside Addis | Blocked / out of service message |

**Module done when**
- [ ] Full cash trip C1 ↔ driver completes  
- [ ] History + rating work  
- [ ] No-driver and cancel paths are clear  

---

## 5. Group D+E — Food (customer + kitchen + rider)

Food has **no seed restaurants**. You must create one before ordering.

### 5.1 Ops: create restaurant and assign owner

**Actor:** FO `944444444` (or Admin A)

| Step | Action | Expect |
|------|--------|--------|
| 1 | Sign in → Home → **Food ops** | Ops board |
| 2 | **Create merchant** (name, area, fee as prompted) | Merchant appears |
| 3 | Set **Owner phone** = `955555555` (Assign owner) | Owner linked |
| 4 | Confirm FM `955555555` has re-OTP’d after `food_merchant` grant | — |

### 5.2 Merchant: menu + modifiers

**Actor:** FM `955555555`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Home → Food → **Merchant / Console** | Own store only |
| 2 | Add dish (name, price ETB, available) | Dish listed |
| 3 | Add **option** / modifier (e.g. Extra sauce +20 ETB) | Option saved |
| 4 | Optionally add photo | Image shows on customer menu |

**Isolation check (FM2 `988888888`)**  
Create/assign a **second** merchant to `988888888`. Confirm they **cannot** edit FM’s dishes.

### 5.3 Customer order (COD)

**Actor:** C1 `911111111`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Food → set delivery pin / place | Shops for that area |
| 2 | Open the restaurant → add item + modifier | Cart totals include option |
| 3 | Cart → see fee + total → Checkout **COD** | Order placed |
| 4 | Open order detail | Status + **delivery OTP** visible — **write it down** |

### 5.4 Kitchen queue (live poll ~3s)

**Actor:** FM `955555555` (keep console open)

| Step | Action | Expect |
|------|--------|--------|
| 1 | New order appears without hard refresh | Live board |
| 2 | **Accept** → **Preparing** → **Ready** | Status moves; customer order updates |

### 5.5 Rider delivery (OTP + COD)

**Actor:** FR `966666666`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Food → **Rider** | See ready jobs |
| 2 | **Claim** | Pickup shows restaurant name/address |
| 3 | Pickup → On the way | Customer status updates |
| 4 | Complete with **customer OTP** + confirm COD amount | Delivered |

### 5.6 Food fail checks

| Step | Action | Expect |
|------|--------|--------|
| 1 | Customer cancel after **Preparing** | Cancel blocked + clear message |
| 2 | Rider wrong OTP | Rejected; order not delivered |
| 3 | Food ops force-deliver (no OTP) if supported | Ops override works |
| 4 | Unavailable menu item | Cannot add / clear block |

**Module done when**
- [ ] Merchant created + owned by FM  
- [ ] Order → kitchen → rider OTP complete  
- [ ] Second merchant cannot edit first menu  
- [ ] Cancel-after-preparing blocked  

---

## 6. Group F — Market (sell + moderate + buy)

Categories are seeded; **ads are not**.

### 6.1 Seller posts

**Actor:** C1 `911111111`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Home → **Market** → Sell / post | Form |
| 2 | Fill title, price ETB, category, subcity, photos if available → Submit | Ad **pending** |
| 3 | **My ads** | Sees own ad (pending) |

### 6.2 Moderator approves

**Actor:** MM `922222222`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Home → **Market ops** | Pending queue |
| 2 | **Approve** the ad | Removed from pending |
| 3 | Optionally reject another test ad with reason | Seller sees rejected |

### 6.3 Buyer finds and contacts

**Actor:** C2 `977777777`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Market → browse / search | Approved ad visible |
| 2 | Open ad → Favorite | In Favorites |
| 3 | Chat and/or Call | Message thread and/or `tel:` works |

### 6.4 Market fail checks

| Step | Action | Expect |
|------|--------|--------|
| 1 | Browse before approve | Pending ad **not** in public catalog |
| 2 | Report ad (as buyer) | Report reaches ops queue |
| 3 | Seller marks sold / unpublish | Ad leaves active browse |

**Module done when**
- [ ] Post → approve → browse → favorite → chat/call  
- [ ] Pending ads hidden from public  

---

## 7. Group G — Events (host + ops + guest)

### 7.1 Host creates event

**Actor:** C1 `911111111`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Home → **Events** → **+** / Host → Create | Form |
| 2 | Title, category, subcity, venue, start time, capacity, price `0` (free) or pay-at-door → Submit | Status **pending** |
| 3 | **Host** tab | Event listed pending |

### 7.2 Ops approve

**Actor:** EO `900000010` (or Admin A)

| Step | Action | Expect |
|------|--------|--------|
| 1 | Home → **Events ops** | Pending queue (polls ~4s) |
| 2 | **Approve** | Event becomes live |

### 7.3 Guest RSVP

**Actor:** C2 `977777777`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Events → Browse | Approved event visible |
| 2 | Open → **RSVP** | Ticket code shown — **write it down** |
| 3 | **Tickets** tab | Ticket listed |

### 7.4 Host check-in

**Actor:** C1 (host)

| Step | Action | Expect |
|------|--------|--------|
| 1 | Host → event → **Attendees** | Guest ticket listed |
| 2 | Check in by ticket code or one-tap | Status **checked_in** |

### 7.5 Events fail checks

| Step | Action | Expect |
|------|--------|--------|
| 1 | Browse before approve | Pending event hidden |
| 2 | Ops **Reject** with reason | Host sees reason |
| 3 | Guest cancel RSVP (if reserved) | Seat freed |
| 4 | Ops force cancel / suspend organizer | Live event stops |

**Module done when**
- [ ] Create → approve → RSVP → check-in works  
- [ ] Pending hidden from browse  

---

## 8. Ops & Staff smoke (Admin A)

**Actor:** `999999999`

| Step | Action | Expect |
|------|--------|--------|
| 1 | Home shows ops shortcuts | Market / Food / Ride / Events ops + Staff |
| 2 | **Staff** grant + revoke a test role | Persists after refresh |
| 3 | Ride ops: fare params readable/editable | Config saves |
| 4 | Food ops: order board visible | Can cancel / reassign if needed |
| 5 | Events ops: pending + live lists | Approve/reject works |

---

## 9. Suggested one-day schedule

| Block | Focus | Actors |
|-------|--------|--------|
| 0:00–0:20 | Section 2 setup + grants | A + all phones OTP once |
| 0:20–0:50 | **Ride** golden path + cancel/no-driver | C1 + driver |
| 0:50–1:40 | **Food** onboard → menu → order → rider | FO + FM + C1 + FR |
| 1:40–2:10 | **Market** post → approve → chat | C1 + MM + C2 |
| 2:10–2:40 | **Events** create → approve → RSVP → check-in | C1 + EO + C2 |
| 2:40–3:00 | Fail checks + Admin smoke | A |

---

## 10. Final release gate

Only call this QA pass **green** if all are true:

- [ ] Section 2 roster exists; re-OTP after grants  
- [ ] Ride: cash trip complete + history/rate  
- [ ] Food: ops merchant + kitchen + rider OTP delivery  
- [ ] Market: pending → approved → browse → contact  
- [ ] Events: pending → approved → RSVP → check-in  
- [ ] Role isolation: second food merchant cannot edit first menu  
- [ ] No critical “Failed to fetch” / crash on happy paths (wake API if slept)  

**Not required to fail the gate:** Games polish, push notifications, mobile money, QR tickets, road-network routing.

---

## 11. Quick troubleshooting

| Symptom | What to do |
|---------|------------|
| First action hangs | Wait 60s (Render wake), hard refresh, retry |
| Role button missing after grant | Sign out → OTP again |
| Food browse empty | FO must create merchant + FM must add dishes |
| Market empty | Seller must post; MM must approve |
| Events empty | Host create; EO approve |
| Ride never matches | Driver Online + approved + near pickup (offer radius) |
| `Failed to fetch` on trip place | Confirm API CORS includes `Idempotency-Key` (shipped); hard refresh app |

---

*Print or keep this file open beside two browser windows. Tick as you go.*
