# Maekel User Stories & Acceptance Checklist

**What Maekel is:** One app for Addis Ababa with Ride, Food, Market, and Events — one phone number, many roles.  
**Version:** 1.0  
**Aligned with:** [qa-step-by-step-guide.md](./qa-step-by-step-guide.md) (click-by-click runbook)  
**PDF copy:** [`mvp-qa-guide.pdf`](./mvp-qa-guide.pdf)  
**App:** https://maekel.pages.dev/ · **API:** https://maekel-api.onrender.com/ · **OTP:** `828694`

**How to use**
1. Run steps in the [step-by-step runbook](./qa-step-by-step-guide.md) using the phones below.  
2. Tick every box under **What must be true** for each story.  
3. A story passes only when every box is ticked.  
4. Do not call the release ready if any **Critical** item in §10 is open.

---

## 1. What “ready” means

With one Maekel login a tester can:

| # | Module | Done when |
|---|--------|-----------|
| 1 | Sign-in / Home | Phone + OTP → Home; open Ride, Food, Market, Events without signing in again |
| 2 | Ride | Quote → request → matched driver → live map → cash complete → rate + history |
| 3 | Food | Ops creates shop → merchant menu → COD order → kitchen → rider OTP handover |
| 4 | Market | Post ad → moderator approve → browse → favorite → chat/call |
| 5 | Events | Host create → ops approve → guest RSVP → host check-in |

**Not required to fail readiness:** Games polish, push notifications, mobile money, QR tickets, road-network routing, surge, scheduled rides.

---

## 2. Test people (phones & roles)

Same roster as the runbook §1. Create once (runbook §2), then reuse.

| Label | Local phone | Roles | Acts as |
|-------|-------------|-------|---------|
| **A** | `999999999` | Admin + all ops (auto) | Staff, Ride/Food/Market/Events ops; can drive |
| **C1** | `911111111` | Defaults only | Passenger, food customer, Market seller/buyer, Events host |
| **C2** | `977777777` | Defaults only | Second customer, Market buyer, Events guest |
| **D** | `911111112` | Defaults + Ride ops **Approve** | Ride driver *(or use A)* |
| **MM** | `922222222` | `market_moderator` | Market reviewer |
| **FO** | `944444444` | `food_ops` | Food ops |
| **FM** | `955555555` | `food_merchant` | Restaurant kitchen |
| **FR** | `966666666` | `food_rider` | Food delivery |
| **FM2** | `988888888` | `food_merchant` | Second restaurant (isolation) |
| **EO** | `900000010` | `events_ops` | Events moderator |

**Defaults on every new OTP:** `ride_passenger`, `food_customer`, `market_buyer`, `market_seller`, `events_attendee`, `events_organizer`.

**Rule:** After every Staff grant → that user **Sign out → OTP again**.

---

## 3. Group A — Sign-in and Home

*Runbook §3 · Actor C1*

#### Story A01 — Sign in with phone and OTP
**As a** new customer, **I want to** sign in with my Ethiopian number and OTP, **so that** I use one Maekel account.

**Actors:** C1 `911111111`  
**What must be true**
- [ ] I enter 9 local digits; country is +251
- [ ] Wrong OTP shows a clear error and I stay signed out
- [ ] Correct OTP `828694` opens Home
- [ ] Sign out returns me to the phone screen and clears the session

#### Story A02 — Home shortcuts
**As a** signed-in customer, **I want** clear tiles for Ride, Market, Food, and Events, **so that** I open each module quickly.

**Actors:** C1  
**What must be true**
- [ ] Home shows Maekel branding and tiles for Ride, Market, Food, Events (Games may exist)
- [ ] Each tile opens without crash
- [ ] Moving between modules does not ask for OTP again

#### Story A03 — One phone, many roles
**As a** customer, **I want** one number for passenger/driver and buyer/seller (and food/events roles when granted), **so that** I do not need two accounts.

**Actors:** C1 + A (grants)  
**What must be true**
- [ ] Same account can use Ride as passenger and, after Ride ops approve, as driver
- [ ] Same account can buy and sell on Market
- [ ] Staff roles stay blocked until granted and re-OTP’d
- [ ] After grant + re-OTP, the matching ops shortcut appears on Home when expected

#### Story A04 — Staff grants persist
**As an** admin, **I want** role grants to stick, **so that** QA accounts keep working after API restarts.

**Actors:** A `999999999`  
**What must be true**
- [ ] Staff can grant `market_moderator`, `food_ops`, `food_merchant`, `food_rider`, `events_ops`, `ride_ops`
- [ ] Grants appear on the Staff list after refresh
- [ ] Target must re-OTP before the role works in the app

---

## 4. Group B — Ride (passenger)

*Runbook §4 · Passenger C1 · Driver A or approved D*

#### Story B01 — Choose pickup and drop-off
**As a** passenger, **I want to** set pickup and drop-off in Addis, **so that** I can request a trip.

**Actors:** C1  
**What must be true**
- [ ] Pickup via GPS, map pin, or place search
- [ ] Drop-off via pin or search
- [ ] Outside the service area, request is blocked with a clear message

#### Story B02 — See price before request
**As a** passenger, **I want** an ETB quote before Request, **so that** I am not surprised later.

**Actors:** C1  
**What must be true**
- [ ] Quote shows total ETB, distance, and ETA
- [ ] One vehicle class (Economy) in this release
- [ ] Request is not available until a quote is shown
- [ ] On a normal completed trip, end fare matches the quote

#### Story B03 — Request and get a driver
**As a** passenger, **I want to** request and be matched, **so that** a driver comes for me.

**Actors:** C1 + Online approved driver  
**What must be true**
- [ ] After Request I see searching / matching
- [ ] When matched I see driver identity (name/car/plate or clear summary) and ETA
- [ ] Double Request does not create two active trips
- [ ] If no driver is found, I see a clear message and can try again

#### Story B04 — Follow the trip on the map
**As a** passenger, **I want** live trip status on the map, **so that** I know progress.

**Actors:** C1  
**What must be true**
- [ ] After assign, map/status updates toward pickup
- [ ] Status moves: assigned → arriving/arrived → in progress → completed/cancelled
- [ ] Driver position refreshes while online (polling is OK)
- [ ] I can reopen an active trip if I leave and come back

#### Story B05 — Contact the driver
**As a** passenger, **I want to** contact my driver, **so that** we can coordinate pickup.

**Actors:** C1  
**What must be true**
- [ ] After match, Call (`tel:`) and/or in-app contact works (at least one)

#### Story B06 — Cancel before the trip starts
**As a** passenger, **I want to** cancel before the trip is in progress, **so that** I am not forced to ride.

**Actors:** C1  
**What must be true**
- [ ] Cancel is available before in-progress
- [ ] After cancel, trip is cancelled and the driver is free for other offers

#### Story B07 — Cash, rate, and history
**As a** passenger, **I want to** pay cash, rate, and see past trips, **so that** the trip feels complete.

**Actors:** C1  
**What must be true**
- [ ] Cash amount is clear at complete
- [ ] I can rate 1–5 after complete
- [ ] History shows fare, time, and driver summary

---

## 5. Group C — Ride (driver & ops)

*Runbook §4.1–4.2 · Driver A or D · Ops A*

#### Story C01 — Go online and receive offers
**As an** approved driver, **I want to** go online and get offers, **so that** I can earn.

**Actors:** D (or A)  
**What must be true**
- [ ] Unapproved driver cannot go Online
- [ ] After Ride ops Approve (+ re-OTP if needed), Online works
- [ ] Offline means no new offers
- [ ] Offer shows pickup area, fare estimate, and accept time limit (~45s)

#### Story C02 — Complete driver trip steps
**As a** driver, **I want to** Accept → Arrived → Start → Complete + cash confirm, **so that** the trip closes correctly.

**Actors:** Driver matched to C1  
**What must be true**
- [ ] Accept links me to the passenger trip
- [ ] Arrived → Start → Complete work in order
- [ ] Cash confirm works
- [ ] Today’s earnings updates after complete
- [ ] Report problem (e.g. no-show) does not crash the app

#### Story C03 — Ride ops thin control
**As** Ride ops, **I want to** approve drivers and manage fare params, **so that** supply and pricing stay under control.

**Actors:** A  
**What must be true**
- [ ] Approve / suspend drivers from Ride ops
- [ ] Force-cancel an active trip when needed
- [ ] Fare config (base / per-km / min) is readable and savable

---

## 6. Group D — Food (customer)

*Runbook §5.3 · Actor C1 · Prerequisite: FO+FM setup (§5.1–5.2)*

#### Story D01 — See shops that deliver to me
**As a** customer, **I want** restaurants/groceries for my pin, **so that** I only browse what I can order.

**Actors:** C1  
**What must be true**
- [ ] I set/confirm a delivery place before or while browsing
- [ ] Shops for that area appear (after ops created a merchant)
- [ ] Empty / out-of-area messaging is clear when nothing applies

#### Story D02 — Build a cart from one shop
**As a** customer, **I want** items with quantities and options from one shop, **so that** I can check out one order.

**Actors:** C1  
**What must be true**
- [ ] Item shows ETB price and availability
- [ ] Unavailable items cannot be added (or are clearly blocked)
- [ ] Modifiers/options adjust the line total
- [ ] Cart shows items, subtotal, delivery fee, and total
- [ ] One cart = one shop in this release

#### Story D03 — Place COD order
**As a** customer, **I want to** place a cash-on-delivery order, **so that** the shop can prepare.

**Actors:** C1  
**What must be true**
- [ ] Delivery fee and total are clear before place
- [ ] COD is available
- [ ] After place I get order id/status and a **delivery OTP** on the order detail

#### Story D04 — Follow order and OTP handover
**As a** customer, **I want** status updates and OTP handover, **so that** delivery is safer.

**Actors:** C1 (+ FR completes)  
**What must be true**
- [ ] Status moves through confirmed → preparing → ready/picked up → on the way → delivered (or clear equivalents)
- [ ] Order cannot show delivered without correct OTP (unless ops force-deliver)
- [ ] Order appears in history

#### Story D05 — Cancel only before preparing
**As a** customer, **I want to** cancel only before preparing, **so that** shops do not waste food.

**Actors:** C1  
**What must be true**
- [ ] Cancel works while still only confirmed
- [ ] After preparing starts, cancel is blocked with a clear message

---

## 7. Group E — Food (ops, kitchen, rider)

*Runbook §5.1–5.5 · FO / FM / FR / FM2*

#### Story E01 — Ops onboard merchant and owner
**As** Food ops, **I want to** create a merchant and assign an owner phone, **so that** kitchen staff can manage their menu.

**Actors:** FO `944444444` (or A), owner FM `955555555`  
**What must be true**
- [ ] Create merchant from Food ops
- [ ] Assign owner phone `955555555`
- [ ] Owner only reaches their console after `food_merchant` grant + re-OTP
- [ ] Ops uses Food ops board, not “claiming” another store’s console as primary flow

#### Story E02 — Merchant menu and kitchen
**As** restaurant staff, **I want to** manage menu (with options) and advance orders, **so that** riders can pick up.

**Actors:** FM `955555555`  
**What must be true**
- [ ] Add/edit dishes with ETB prices and availability
- [ ] Add modifiers/options (name + ETB)
- [ ] New orders appear on the console without hard refresh (live poll OK)
- [ ] Accept → Preparing → Ready works
- [ ] Pause shop stops new orders when designed

#### Story E03 — Merchant isolation
**As** second restaurant staff, **I must not** edit another restaurant’s menu.

**Actors:** FM2 `988888888` vs FM  
**What must be true**
- [ ] FM2 only sees/edits their assigned merchant
- [ ] FM2 cannot change FM’s dishes

#### Story E04 — Rider OTP delivery
**As a** food rider, **I want to** claim ready jobs and complete with customer OTP + COD, **so that** handover is checked.

**Actors:** FR `966666666`  
**What must be true**
- [ ] Ready jobs appear on Rider board (live poll OK)
- [ ] Pickup shows clear merchant name/address
- [ ] Pickup → on the way → complete requires correct customer OTP
- [ ] Wrong OTP is rejected; order not delivered
- [ ] COD amount to collect is clear
- [ ] Food riders are separate from Ride drivers (job lists do not mix)

#### Story E05 — Food ops support actions
**As** Food ops, **I want** thin support tools, **so that** stuck orders can be unblocked.

**Actors:** FO or A  
**What must be true**
- [ ] Ops board shows orders
- [ ] Support cancel / reassign rider when available
- [ ] Force-deliver without OTP works when designed

---

## 8. Group F — Market

*Runbook §6 · C1 seller · MM moderator · C2 buyer*

#### Story F01 — Browse and search
**As a** buyer, **I want to** browse and search approved ads, **so that** I find items near me.

**Actors:** C2  
**What must be true**
- [ ] Seeded categories are available
- [ ] Keyword / filters (subcity, price as designed) work
- [ ] Cards show title, price ETB, place (photo when provided)
- [ ] Only **approved** ads appear in public browse

#### Story F02 — Contact seller
**As a** buyer, **I want to** chat or call the seller, **so that** we can arrange meetup.

**Actors:** C2  
**What must be true**
- [ ] Detail shows description and seller context
- [ ] In-app chat sends/receives (no fake auto-reply as the only path)
- [ ] Call works per design (`tel:` / reveal)
- [ ] Safety guidance is visible around contact

#### Story F03 — Favorites
**As a** buyer, **I want** favorites, **so that** I can return to ads later.

**Actors:** C2  
**What must be true**
- [ ] Add/remove favorite from detail
- [ ] Favorites list shows saved approved ads

#### Story F04 — Post for sale
**As a** seller, **I want to** post an ad, **so that** buyers can find it after approval.

**Actors:** C1  
**What must be true**
- [ ] Sell flow covers category, details, price, place, photos as designed
- [ ] After submit, status is **pending** and ad is **not** public
- [ ] My ads shows the pending listing

#### Story F05 — Moderate listings
**As a** Market moderator, **I want to** approve or reject ads, **so that** only safe ads go live.

**Actors:** MM `922222222`  
**What must be true**
- [ ] Ops queue shows pending ads
- [ ] Approve makes the ad public
- [ ] Reject keeps it off browse and can show a reason to the seller
- [ ] Buyer reports appear for ops handling

#### Story F06 — Manage my ads
**As a** seller, **I want to** manage my ads, **so that** I can edit, close, or mark sold.

**Actors:** C1  
**What must be true**
- [ ] My ads shows pending / approved / rejected / sold (or clear equivalents)
- [ ] Edit works (material edits may re-pending)
- [ ] Sold / unpublish removes the ad from active browse

---

## 9. Group G — Events

*Runbook §7 · Host C1 · Ops EO · Guest C2*

#### Story G01 — Host creates an event
**As an** organizer, **I want to** create an event for review, **so that** guests can discover it after approval.

**Actors:** C1  
**What must be true**
- [ ] Create form covers title, category, subcity, venue, time, capacity, free or pay-at-door price
- [ ] Submit creates **pending** event
- [ ] Host tab lists my pending/live events

#### Story G02 — Ops approve or reject
**As** Events ops, **I want to** approve or reject pending events, **so that** only valid events go live.

**Actors:** EO `900000010` (or A)  
**What must be true**
- [ ] Ops queue shows pending (live poll OK)
- [ ] Approve makes the event visible in Browse
- [ ] Reject with reason is visible to the host
- [ ] Force cancel / suspend organizer stops live events when used

#### Story G03 — Guest RSVP and tickets
**As a** guest, **I want to** RSVP and keep a ticket code, **so that** I can attend.

**Actors:** C2  
**What must be true**
- [ ] Approved upcoming events appear in Browse (filters work as designed)
- [ ] Pending events are hidden from Browse
- [ ] RSVP issues a ticket code on Tickets
- [ ] Cancel RSVP (while reserved) frees capacity when designed

#### Story G04 — Host check-in
**As a** host, **I want to** check guests in, **so that** attendance is tracked at the door.

**Actors:** C1  
**What must be true**
- [ ] Attendees list shows reserved tickets
- [ ] Check-in by ticket code or one-tap marks checked-in
- [ ] Door/check-in code is available to the host (not required on public browse)

---

## 10. Group H — Cross-app & release gate

#### Story H01 — One sign-in for all modules
**As a** customer, **I want** one sign-in for Ride, Food, Market, and Events.

**Actors:** C1  
**What must be true**
- [ ] After one OTP, switching modules never asks for a new code until sign-out

#### Story H02 — Final ready checklist
**As** the person signing off, **I want** one gate list aligned with the runbook §10.

**What must be true**
- [ ] A01–A04 pass (sign-in, Home, roles, Staff)
- [ ] Full Ride cash trip passes (Groups B–C) — runbook §4
- [ ] Full Food COD + OTP delivery passes (Groups D–E) — runbook §5
- [ ] Market post → approve → browse → contact passes (Group F) — runbook §6
- [ ] Events create → approve → RSVP → check-in passes (Group G) — runbook §7
- [ ] Merchant isolation (E03) passes
- [ ] No critical open defects below

---

## 11. How serious is the problem?

| Level | Meaning | Examples |
|-------|---------|----------|
| **Critical** | Must fix before launch | Sign-in without valid OTP; two trips from one Request; Food delivered without OTP (non-ops); pending Market/Event shown as public |
| **Major** | Should fix before calling this bar done | Wrong fare at complete; chat not sending; cancel allowed after preparing; role works without re-OTP after grant |
| **Minor** | Soon after | Copy, spacing, empty-state polish |
| **Later** | Out of this bar | Push/FCM, mobile money, QR tickets, surge, scheduled rides |

---

## 12. Story ↔ runbook map

| Stories | Runbook section |
|---------|-----------------|
| A01–A04 | §2–§3, §8 |
| B01–B07, C01–C03 | §4 |
| D01–D05, E01–E05 | §5 |
| F01–F06 | §6 |
| G01–G04 | §7 |
| H01–H02 | §10 |

---

## 13. Document history

| Version | Date | Notes |
|---------|------|-------|
| 0.1–0.4 | 2026-11-15 | Original first-release stories (Ride/Food/Market) |
| **1.0** | **2026-11-23** | Rewritten to match step-by-step runbook; phones/roles; Events group; live app URL |
