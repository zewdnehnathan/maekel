# Maekel Ride Module — Functional Requirements

**Product reference:** [Feres](https://feres.co/) / [feres.et](https://feres.et/) (Ethiopia ride-hailing)  
**Super app:** Maekel (Flutter) — this document defines the **Ride** module as a first-class vertical inside Maekel.  
**Version:** 0.1 (draft)  
**Status:** Ready for product / engineering review  
**Currency / locale defaults:** ETB, +251, Addis Ababa first, English + Amharic-ready  
**Related docs:** [Food / Delivery FRD](./food-delivery-functional-requirements.md)

---

## 1. Purpose

Define what Maekel’s ride-hailing vertical must do for passengers, drivers, dispatch/ops, and (later) loyalty — inspired by Feres’ model (on-demand + scheduled trips, multi vehicle class, upfront fare, live tracking, cash/mobile money/card/rewards, driver app, call-center fallback) — while remaining a **module inside the Maekel super app**, not a standalone brand fork.

Maekel already owns (or will own):

- Shared phone/OTP auth and session
- Home hub navigation into Ride / Market / Food / Games
- Shared theme, i18n, addresses, and (later) payments / notifications / loyalty wallet

This FRD specifies **Ride module** behavior on top of that shell. The Maekel v1 shell already plans **consumer + driver role stubs** under Ride; this document is the product target those stubs grow into.

---

## 2. Product summary

| Item | Requirement |
|------|-------------|
| What | On-demand and scheduled passenger transport matching riders with vetted drivers/vehicles |
| Who | Passengers, drivers, dispatch/call-center agents, platform ops |
| Where | **Addis Ababa first**; expandable to other Ethiopian cities later (Feres markets “everywhere in Ethiopia”) |
| When | **24/7** platform availability (driver supply varies by time/area) |
| Core loop | Set pickup → choose destination → pick vehicle type → see price → request → match → track → ride → pay → rate |
| Vehicle classes | Private car / sedan, taxi, larger cars (up to ~6 seats), minivan, minibus (configurable catalog) |
| Payments | Cash, mobile money (e.g. E-Birr / Telebirr / M-PESA class), credit/debit card where available, ride rewards / miles |
| Tracking | Live driver GPS on map toward pickup and during trip; share driver + vehicle identity before meet |
| Loyalty (Feres Miles–class) | Cashback/points on spend; redeem for trips, airtime, transfer, cash-out, donate (phased) |
| Alternate booking | In-app primary; optional **call-center / shortcode** booking for users without app fluency (Feres: 6090) |

---

## 3. Actors & personas

| Actor | Goal |
|-------|------|
| **Passenger (consumer)** | Get a nearby affordable ride quickly, know the fare upfront, track the car, pay flexibly, feel safe |
| **Driver** | Go online, receive trip offers, navigate, complete trips, earn with flexible hours, track earnings |
| **Dispatch / call center** | Book rides for callers, assist stuck matches, handle safety/support escalations |
| **Ops / Admin** | Onboard/vet drivers & vehicles, configure fares/zones/surge, monitor live trips, payouts, suspensions |
| **Maekel shell** | Single login; hub entry to Ride; consumer ↔ driver role switch; shared profile, payment methods, (later) loyalty balance |

---

## 4. Scope boundaries

### 4.1 In scope (Ride module product)

- Passenger request: map pickup/dropoff, vehicle class, fare quote, request, cancel rules
- Matching / dispatch to nearby eligible drivers
- Live trip tracking and trip status lifecycle
- In-trip communication (masked call / in-app chat as designed)
- Payments: cash + at least one digital method in MVP; rewards later
- Driver online mode, trip accept/reject/arrive/start/complete, earnings
- Safety: SOS/share trip, driver/vehicle verification display, ratings
- Scheduled rides
- Multi-seat / van / minibus class selection
- Admin + dispatch tooling (high level)
- Super-app integration (auth, routes, role switch)

### 4.2 Out of scope for this document

- Food / courier delivery logistics (Maekel **Food** module — may share drivers later, not assumed here)
- Market classifieds, Games
- Intercity bus booking / mass transit ticketing (Feres roadmap mentions bus/courier/super-app expansion — park as future Maekel adjacent)
- Building a separate consumer brand app outside Maekel

### 4.3 Phasing suggestion

| Phase | Focus |
|-------|--------|
| **MVP** | Passenger map request (pickup + dropoff), one+ vehicle classes, upfront fare, match, live track to pickup, cash pay, start/complete trip, rate; driver online/accept/navigate/complete; shared Maekel auth; consumer/driver role entry |
| **V1.1** | Scheduled rides, more vehicle classes (van/minibus), mobile money, cancel fees, in-trip share, SOS, English-speaker / preference flags |
| **V1.2** | Loyalty miles (earn/redeem/transfer), call-center booking integration, surge/demand pricing UX, driver earnings analytics |
| **V2** | Multi-stop trips, corporate accounts, airport queues, intercity, pooled/shared rides (only if product wants them) |

---

## 5. Super-app integration requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| SA-01 | Ride is reachable from Maekel Home hub as a primary module entry | Must |
| SA-02 | Authenticated Maekel session is reused; no second login inside Ride | Must |
| SA-03 | Clear **Passenger** vs **Driver** mode (role switcher), matching existing shell stub intent (`/ride`, `/ride/driver`) | Must |
| SA-04 | Deep links: `/ride`, `/ride/request`, `/ride/trips/:id`, `/ride/driver`, `/ride/driver/earnings` | Must |
| SA-05 | Saved places (Home, Work, recent) shared with Food addresses where practical | Should |
| SA-06 | Payment methods from Maekel wallet layer selectable for Ride when available | Should |
| SA-07 | Push notifications for match, driver arriving, trip events use Maekel channel | Must |
| SA-08 | Locale (en/am) and ETB formatting follow Maekel shell | Must |
| SA-09 | Leaving Ride returns to Home hub without losing session or active-trip state | Must |
| SA-10 | Active trip must remain reachable from hub (badge / “Trip in progress”) | Must |
| SA-11 | Future: Maekel loyalty ledger can power Ride miles without a separate login | Could |

---

## 6. Passenger functional requirements

### 6.1 Location & map

| ID | Requirement | Priority |
|----|-------------|----------|
| P-01 | App requests location permission; explains why (pickup accuracy) | Must |
| P-02 | Default pickup is current GPS pin; user can drag pin or search address/landmark | Must |
| P-03 | User sets dropoff via search, map pin, or saved place | Must |
| P-04 | Map shows suggested route / distance / ETA estimate before request | Should |
| P-05 | Outside service area: clear message; cannot request | Must |
| P-06 | Works with poor GPS via manual address/landmark entry | Should |

### 6.2 Vehicle class & fare quote

| ID | Requirement | Priority |
|----|-------------|----------|
| P-10 | User sees available service types near pickup (e.g. Economy sedan, Taxi, XL/6-seat, Minivan, Minibus) | Must |
| P-11 | Each class shows ETA of nearest vehicle (when supply exists) and capacity hint | Must |
| P-12 | **Upfront fare** (or clear fare range) shown **before** request — price preview is non-negotiable product rule | Must |
| P-13 | Fare quote includes base components visibility (e.g. flag-down + distance) or at least total + any surge badge | Should |
| P-14 | Quoted fare is binding within a short validity window unless user changes route/class or surge updates with explicit reconfirm | Must |
| P-15 | No silent fare increase after accept without user consent / documented exception policy (tolls, stops, long wait) | Must |
| P-16 | Optional trip preferences: e.g. English-speaking driver, quiet ride, accessibility notes (configurable) | Could |

### 6.3 Request, match, meet

| ID | Requirement | Priority |
|----|-------------|----------|
| P-20 | User taps Request → system searches nearby eligible drivers | Must |
| P-21 | Searching state shows progress; timeout with retry / try another class | Must |
| P-22 | On match: show driver name, photo, rating, vehicle make/model/color, plate number, ETA | Must |
| P-23 | Live map tracking of driver approaching pickup | Must |
| P-24 | Passenger can contact driver via **masked phone** and/or in-app chat | Must |
| P-25 | Passenger can share trip status link with a trusted contact | Should |
| P-26 | Passenger can cancel before driver arrives per cancel policy (free window then fee) | Must |
| P-27 | “Driver arrived” / “waiting” states are visible; wait-time fee rules disclosed if used | Should |

### 6.4 During & after trip

| ID | Requirement | Priority |
|----|-------------|----------|
| P-30 | Trip statuses: Requested → Matching → Driver assigned → Arriving → Arrived → In progress → Completed / Cancelled | Must |
| P-31 | During trip, map shows route to destination and live progress | Must |
| P-32 | Passenger can add a stop only if product enables it (V2); otherwise blocked with message | Could |
| P-33 | On complete: show final fare, payment method, receipt | Must |
| P-34 | Passenger rates driver (1–5) and optional comment / tags | Must |
| P-35 | Trip history lists past rides with receipts | Must |
| P-36 | SOS / emergency button contacts local emergency + notifies support with trip/location context | Should |

### 6.5 Payments (passenger)

| ID | Requirement | Priority |
|----|-------------|----------|
| P-40 | Cash payment supported | Must |
| P-41 | Mobile money payment supported (Ethiopia wallets — Telebirr / E-Birr / M-PESA class as available) | Should (MVP+1) |
| P-42 | Card payment where acquiring is available | Could |
| P-43 | Pay with rewards/miles balance (partial or full) when loyalty ships | Should (phased) |
| P-44 | Default payment method remembered; changeable before request | Must |
| P-45 | Failed digital payment falls back to clear retry or cash confirmation flow — never silent double-charge | Must |

### 6.6 Scheduled rides

| ID | Requirement | Priority |
|----|-------------|----------|
| P-50 | Passenger can schedule pickup for a future date/time | Should |
| P-51 | System confirms schedule, reminds before pickup, then matches in a pre-window | Should |
| P-52 | Passenger can edit/cancel scheduled ride within policy windows | Should |

### 6.7 Loyalty (Feres Miles–class)

| ID | Requirement | Priority |
|----|-------------|----------|
| P-60 | Earn points/cashback on completed paid trips (e.g. % of ETB spent — rate configurable; Feres markets ~5%) | Should |
| P-61 | View miles balance and history | Should |
| P-62 | Redeem for ride discount / free trip credit | Should |
| P-63 | Redeem for mobile airtime | Could |
| P-64 | Transfer miles to another user | Could |
| P-65 | Cash out miles (subject to KYC/limits) | Could |
| P-66 | Donate miles to configured charities | Could |
| P-67 | Membership tiers / unlocks optional later | Could |

---

## 7. Driver functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| D-01 | Driver registers with personal ID, phone, photo, license, vehicle docs, plate; ops approval required before online | Must |
| D-02 | Separate Driver mode/app entry inside Maekel (`/ride/driver`) with online toggle | Must |
| D-03 | When Online, driver receives trip offers with pickup distance, dropoff area/direction, fare estimate, class | Must |
| D-04 | Driver can Accept or Ignore/Reject within a timer; missed offers affect availability scoring optionally | Must |
| D-05 | After accept: navigate to pickup; mark Arrived; start trip (passenger onboard); navigate to dropoff; Complete | Must |
| D-06 | Driver sees passenger first name, rating, pickup pin, contact via masked channel | Must |
| D-07 | Driver cannot arbitrarily change fare outside allowed adjustments (wait, stops, tolls) with audit | Must |
| D-08 | Cash collection UX: show amount due; confirm received | Must |
| D-09 | Earnings dashboard: today / week / trip list; payout schedule visibility | Must |
| D-10 | Driver sets schedule implicitly by going online/offline (“be your own boss”) | Must |
| D-11 | Vehicle must meet platform standards (Feres emphasizes quality / newer fleet — Maekel configures eligibility rules) | Must |
| D-12 | Background check / training status gated by ops before first online | Must |
| D-13 | GPS must be on while online and in-trip; spoofing detection hooks later | Must |
| D-14 | Driver rates passenger after trip | Should |
| D-15 | Issue reporting: no-show, wrong pin, unsafe passenger, vehicle problem | Must |
| D-16 | Commission rate transparent to driver (Feres public comps cite low single-digit % — Maekel sets own rate) | Should |

---

## 8. Dispatch / call-center requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| C-01 | Agent can create a ride on behalf of a phone customer (pickup, dropoff, class, phone number) | Should |
| C-02 | Shortcode / hotline number documented in app Help (Feres pattern: 6090) | Should |
| C-03 | Agent can view live trip, reassign driver, cancel with reason | Must (ops) |
| C-04 | Agent tools link to support tickets and safety incidents | Should |

---

## 9. Pricing & zones

| ID | Requirement | Priority |
|----|-------------|----------|
| Z-01 | Fare engine supports flag-down + per-km + per-minute + booking fee + surge multipliers (configurable) | Must |
| Z-02 | Service geofences / city zones configurable (Addis first) | Must |
| Z-03 | Surge / demand pricing shown clearly before request when active | Should |
| Z-04 | Airport or special zone fees configurable and disclosed | Should |
| Z-05 | Cancellation fee rules configurable (passenger cancel after driver en route; driver cancel penalties) | Must |
| Z-06 | Reference market comps (not Maekel defaults): public Feres-oriented figures have cited ~100 ETB flag + ~16 ETB/km — **Maekel must set its own approved tariff** | Info |

---

## 10. Safety & trust

| ID | Requirement | Priority |
|----|-------------|----------|
| S-01 | Show verified driver + vehicle identity before passenger enters car | Must |
| S-02 | Trip GPS trail stored for support/safety review retention policy | Must |
| S-03 | SOS / emergency flow for passenger (and optionally driver) | Should |
| S-04 | Share-my-trip with ETA and live link | Should |
| S-05 | Ops can suspend drivers/passengers for policy violations | Must |
| S-06 | Rating thresholds can auto-flag accounts for review | Should |
| S-07 | Prohibit fare negotiation / forced ride-sharing outside product features; provide in-app report path | Must |
| S-08 | Privacy: minimize data; encrypt in transit; never log full payment secrets | Must |

---

## 11. Notifications

| ID | Requirement | Priority |
|----|-------------|----------|
| N-01 | Passenger: driver found, arriving, arrived, trip started, completed, cancelled, payment issues | Must |
| N-02 | Driver: new offer, passenger cancel, payout updates, document expiry | Must |
| N-03 | Scheduled ride reminders | Should |
| N-04 | Channels: push + in-app; SMS for critical match/OTP-like confirmations optional | Should |

---

## 12. Admin / ops console (high level)

| ID | Requirement | Priority |
|----|-------------|----------|
| A-01 | Approve/reject driver & vehicle documents; force logout/suspend | Must |
| A-02 | Live map of open requests, active trips, online drivers | Must |
| A-03 | Manual assign / reassign / cancel with reason codes | Must |
| A-04 | Configure vehicle classes, fares, zones, surge, cancel fees, platform messages | Must |
| A-05 | Support tools: refunds, fare adjustments, trip reconstruction | Must |
| A-06 | Payouts & commission reports | Must |
| A-07 | Loyalty catalog configuration when miles ship | Should |
| A-08 | Analytics: request→match rate, ETA accuracy, cancel reasons, GMV, supply heatmap | Should |

---

## 13. Key user flows (acceptance-oriented)

### 13.1 Happy path — passenger on-demand

1. Open Maekel → Ride (Passenger).  
2. Confirm pickup pin; enter dropoff.  
3. Select vehicle class; review **upfront fare**.  
4. Choose payment method → Request.  
5. System matches driver; passenger sees car details + live map.  
6. Driver arrives; trip starts; passenger tracked to destination.  
7. Trip completes; pay (cash/digital); rate driver.

### 13.2 Driver complete

1. Switch to Driver mode → go Online.  
2. Receive offer → Accept → navigate to pickup → Arrived.  
3. Start trip → navigate to dropoff → Complete → confirm cash if needed → see earnings update.

### 13.3 Cancel before arrival

1. Passenger cancels while driver en route.  
2. Fee applied only if outside free window.  
3. Driver notified; offer capacity freed.

### 13.4 Scheduled

1. Passenger sets future pickup time + locations + class.  
2. Reminder fires; matching starts in pre-window.  
3. Continues as on-demand once assigned.

---

## 14. Data entities (logical)

- User (Maekel identity), RoleBinding (passenger/driver)  
- SavedPlace, PaymentMethod  
- DriverProfile, DriverDocument, Vehicle, VehicleClass  
- RideRequest, FareQuote, SurgeContext  
- Trip, TripStatusEvent, TripLocationPoint  
- DispatchOffer, Assignment  
- PaymentTransaction, DriverEarning, Payout, CommissionRule  
- Rating, SupportTicket, SafetyIncident  
- LoyaltyAccount, MilesLedgerEntry, Redemption (phased)  
- CallCenterBooking (phased)

---

## 15. Non-functional requirements (product-relevant)

| ID | Requirement | Priority |
|----|-------------|----------|
| NF-01 | Matching + location updates reliable on mid-range Android under Addis network conditions | Must |
| NF-02 | Driver location updates frequent enough for usable live map (e.g. few-second interval while assigned/in-trip) | Must |
| NF-03 | Request placement must be **idempotent** — UI errors must not create duplicate trips (known pain in market apps) | Must |
| NF-04 | Session stability: unexpected logout during request/trip is a P0 defect class | Must |
| NF-05 | Fare shown at request and fare at complete must reconcile per policy with an explainable diff | Must |
| NF-06 | Security: HTTPS, auth tokens, masked calls, role-based access, rate-limited offers | Must |
| NF-07 | Audit trail for fare overrides, cancels, and payouts | Must |
| NF-08 | Accessibility: large map controls, readable fare, screen-reader labels on Request/Cancel | Should |

---

## 16. Success metrics (product)

| Metric | Target direction |
|--------|------------------|
| Request → successful match rate | Increase |
| Time to match / pickup ETA accuracy | Improve |
| Passenger cancel after assign | Decrease |
| Trip completion rate | Increase |
| Fare dispute / support tickets per trip | Decrease |
| Driver online hours & acceptance rate | Healthy supply |
| Passenger ratings distribution | Maintain high |
| Repeat weekly riders | Increase |

---

## 17. Assumptions & open questions

**Assumptions**

- Maekel Ride is a **Feres-class** ride-hail vertical: map booking, upfront price, GPS tracking, driver marketplace, 24/7.  
- Passenger and driver share one Maekel account with role modes (separate native driver binary optional later).  
- Addis Ababa is the launch city.  
- Loyalty miles are important for parity with Feres but not required for MVP matching/payments.  
- Food-module delivery riders and Ride drivers are **separate supply pools** unless product later unifies them.

**Open questions for stakeholders**

1. Exact launch vehicle classes (sedan only vs taxi + XL + minibus day one)?  
2. Which wallets are mandatory at MVP vs V1.1?  
3. Do we operate a Maekel call-center shortcode at launch?  
4. Fixed upfront fare vs estimate + final meter — product stance (recommend **binding upfront** to avoid Feres-like fare disputes)?  
5. Driver commission % and payout cadence?  
6. Is “English speaker” a filter at V1.1?  
7. Corporate / airport queue features needed in year one?  
8. Branding inside hub: **Ride** vs a Maekel sub-name?

---

## 18. Traceability to Feres public product behaviors

Mapped from [feres.co](https://feres.co/), [feres.et](https://feres.et/), and public app store listings:

| Feres behavior | Maekel FR IDs |
|----------------|---------------|
| Fast, affordable on-demand trips | §2, P-20–P-23 |
| Choose car type; set pickup | P-02, P-10 |
| Meet driver; track on the way; car + driver details | P-22–P-23 |
| Pay cash, mobile money, card, or rewards | P-40–P-43 |
| Rate driver | P-34 |
| See price before order | P-12–P-15 |
| On-demand + schedule ahead | P-20, P-50–P-52 |
| Private cars, taxis, up to 6 seats, minivan/minibus | P-10 |
| 24/7 | §2 |
| Driver: own schedule, register in driver app, earnings | D-01–D-10 |
| GPS tracking / safety positioning | P-23, S-01–S-02 |
| Call center booking (6090) | C-01–C-02 |
| Feres Miles cashback, redeem, transfer, cash-out, donate, airtime | P-60–P-66 |
| Platform ambition toward broader on-demand / super-app | Aligns with Maekel shell; bus/courier not in Ride MVP |

---

## 19. Document history

| Version | Date | Notes |
|---------|------|-------|
| 0.1 | 2026-11-15 | Initial FR draft from Feres public product + Maekel Ride shell plan |
