# Maekel Food / Delivery Module — Functional Requirements

**Product reference:** [beU Delivery](https://beudelivery.com/) (Addis Ababa on-demand delivery)  
**Super app:** Maekel (Flutter) — this document defines the **Food** module (and related multi-category delivery) as a first-class vertical inside Maekel.  
**Version:** 0.1 (draft)  
**Status:** Ready for product / engineering review  
**Currency / locale defaults:** ETB, +251, Addis Ababa, English + Amharic-ready

---

## 1. Purpose

Define what Maekel’s delivery vertical must do for customers, merchants, riders, business accounts, and operations — inspired by beU’s model (food, grocery, pharmacy, parcel, multi-category retail) — while remaining a **module inside the Maekel super app**, not a standalone brand fork.

Maekel already owns:

- Shared phone/OTP auth and session
- Home hub navigation into Ride / Market / Food / Games
- Shared theme, i18n, and (later) payments / notifications infrastructure

This FRD specifies **Food module** behavior on top of that shell.

---

## 2. Product summary

| Item | Requirement |
|------|-------------|
| What | On-demand ordering and courier from local partners to a delivery address in Addis Ababa |
| Who | Consumers, partner merchants, delivery riders, B2B/corporate clients, platform ops |
| Where | Addis Ababa — target **23+ districts**, merchants within ~**20 km** of delivery pin |
| When | Platform hours roughly **07:30–00:00** daily (incl. weekends/holidays); merchant hours may differ |
| Speed goal | Typical fulfillment **~30–60 minutes** (marketing target ~59 min average) |
| Categories | Food & restaurants, bakery, drinks, groceries/mart, pharmacy/health, beauty, alcohol (age-gated), gifts, books/stationery, pet care, children’s, other/specials, **parcel/courier** |
| Payments | Cash on delivery, mobile money (e.g. Telebirr / M-PESA Ethiopia), bank transfer / digital wallet, cards where available |
| Tracking | Status pipeline (not necessarily live GPS map in v1): Confirmed → Preparing → Picked up → On the way → Delivered; **OTP handover** |

---

## 3. Actors & personas

| Actor | Goal |
|-------|------|
| **Customer** | Browse nearby partners, order items or send a parcel, pay, track status, receive securely |
| **Merchant** | Receive orders, manage menu/catalog & availability, prepare orders, get weekly payouts |
| **Rider** | Accept/dispatch jobs, navigate pickup → dropoff, collect COD if needed, confirm with OTP, earn per delivery |
| **Business / Corporate** | Scheduled office meals, document/parcel runs, e-commerce last-mile, pharmacy distribution, postpaid invoicing |
| **Ops / Admin / Dispatch** | Onboard partners & riders, assign/monitor orders, support, pricing, SLAs, payouts |
| **Maekel shell** | Single login; deep-link into Food from hub; share profile, addresses, payment methods across modules where designed |

---

## 4. Scope boundaries

### 4.1 In scope (Food module product)

- Consumer ordering across merchant categories + parcel send
- Cart, checkout, address, fees, payment method selection
- Order lifecycle + OTP delivery confirmation
- Merchant dashboard/app capabilities for catalog and order handling
- Rider app capabilities for job lifecycle
- Business delivery request flows (or intake + ops-managed) for corporate use cases
- Ratings/reviews, deals/promos, support entry points
- Coverage checks by delivery location
- Age / restricted-item rules (alcohol, selected pharmacy flows)

### 4.2 Out of scope for this document

- Ride hailing (Maekel **Ride** module)
- Classifieds buy/sell (Maekel **Market** module)
- Games
- Full live rider map tracking (optional later; beU FAQ notes status stages without live driver location today)
- Building a separate consumer brand app outside Maekel (integration is in-super-app)

### 4.3 Phasing suggestion

| Phase | Focus |
|-------|--------|
| **MVP** | Customer food/grocery browse → cart → checkout (COD + one digital payment) → status + OTP; basic merchant accept/prepare; basic rider pickup/deliver; shared Maekel auth/addresses |
| **V1.1** | Pharmacy, alcohol age-gate, deals, scheduled delivery, more wallets, cancellation/refund rules UX |
| **V1.2** | Parcel courier, B2B SLAs/postpaid, richer merchant analytics, demand/weather pricing |
| **V2** | Live map tracking, multi-cart/multi-merchant (if required), advanced dispatch algorithms |

---

## 5. Super-app integration requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| SA-01 | Food is reachable from Maekel Home hub as a primary module entry | Must |
| SA-02 | Authenticated Maekel session is reused; no second login inside Food | Must |
| SA-03 | User profile (name, phone) is shared; Food may extend with delivery-specific prefs | Must |
| SA-04 | Saved delivery addresses are usable across Food (and ideally Ride later) | Must |
| SA-05 | Deep links / routes: e.g. `/food`, `/food/merchant/:id`, `/food/orders/:id`, `/food/parcel` | Must |
| SA-06 | Push notifications for order events use Maekel notification channel when available | Should |
| SA-07 | Payment methods registered in Maekel wallet layer are selectable at Food checkout when available | Should |
| SA-08 | Locale (en/am) and ETB formatting follow Maekel shell conventions | Must |
| SA-09 | Role switch: same person may be Customer and Rider (and later Merchant staff) via clear role entry points — similar to Ride consumer/driver pattern | Should |
| SA-10 | Leaving Food returns to Home hub without losing session | Must |

---

## 6. Customer (consumer) functional requirements

### 6.1 Discovery & browsing

| ID | Requirement | Priority |
|----|-------------|----------|
| C-01 | User sets or confirms **delivery location** (pin / saved address / search) before or at start of browse | Must |
| C-02 | System shows only merchants/services **serviceable** for that location (coverage + radius rules) | Must |
| C-03 | Home of Food shows category shortcuts (Food, Grocery, Pharmacy, Parcel, etc.) | Must |
| C-04 | User can search merchants and items by name/keyword | Must |
| C-05 | User can filter/sort (e.g. open now, rating, distance/ETA, deals) | Should |
| C-06 | Merchant list shows name, category, rating, ETA/fee hint, open/closed state, promo badges | Must |
| C-07 | Merchant detail shows hours, min order (if any), delivery fee estimate, photos, ratings | Must |
| C-08 | Menu/catalog supports categories, item photos, descriptions, prices (ETB), variants/modifiers, availability | Must |
| C-09 | Out-of-stock / unavailable items cannot be added (or are clearly blocked) | Must |
| C-10 | User can view ratings and written reviews for merchants (and optionally items) | Should |
| C-11 | Deals / featured collections are visible when configured | Should |

### 6.2 Cart & checkout

| ID | Requirement | Priority |
|----|-------------|----------|
| C-20 | User can add items with quantity and modifiers to cart | Must |
| C-21 | Cart shows line items, subtotal, delivery fee, discounts, taxes/service fees (if any), **grand total** | Must |
| C-22 | Delivery fee is calculated from distance/order rules and shown **before** confirm (no surprise fees) | Must |
| C-23 | Merchant minimum order is enforced with clear messaging | Must |
| C-24 | User selects/confirm delivery address and optional delivery notes (gate code, landmark) | Must |
| C-25 | User selects payment method: COD, mobile money, bank/wallet, card (as enabled) | Must |
| C-26 | User can place **ASAP** order within platform + merchant open hours | Must |
| C-27 | User can **schedule** delivery for a future slot when merchant supports it | Should |
| C-28 | Order confirmation screen returns order ID and initial status | Must |
| C-29 | Single-merchant cart in MVP; multi-merchant cart is optional later | Must (MVP single) |

### 6.3 Payments

| ID | Requirement | Priority |
|----|-------------|----------|
| C-30 | COD: order places without prepayment; rider collects amount due | Must |
| C-31 | Digital payment: order places only after successful payment confirmation (or explicit pending-with-timeout policy) | Must |
| C-32 | Support M-PESA Ethiopia / Telebirr-class wallets as product priorities for Ethiopia | Should |
| C-33 | Failed payment leaves cart intact and shows recoverable error | Must |
| C-34 | Receipt / payment summary available in order detail | Must |

### 6.4 Order tracking & handover

| ID | Requirement | Priority |
|----|-------------|----------|
| C-40 | Customer sees status stages: **Confirmed → Being prepared → Picked up → On the way → Delivered** (and Cancelled/Failed) | Must |
| C-41 | Customer receives a **delivery OTP** and must share it with rider at handover | Must |
| C-42 | Order is marked Delivered only after OTP verification (or approved ops override) | Must |
| C-43 | Customer can view order history and reopen past orders | Must |
| C-44 | Customer can contact support from order detail / Help | Must |
| C-45 | Live map of rider is optional (Should later); status updates are sufficient for MVP | Could |

### 6.5 Cancellation, issues, ratings

| ID | Requirement | Priority |
|----|-------------|----------|
| C-50 | Customer can cancel only **before merchant starts preparing** (configurable cutoff) | Must |
| C-51 | After prep starts, cancel requires support / policy-based refund path | Must |
| C-52 | Customer can report wrong/missing/damaged items via Help with order context | Must |
| C-53 | After delivery, customer can rate merchant (and optionally rider) | Should |
| C-54 | Item substitution: if out of stock mid-fulfillment, merchant/rider flow should notify customer before swap (grocery especially) | Should |

### 6.6 Parcel / courier (consumer)

| ID | Requirement | Priority |
|----|-------------|----------|
| C-60 | User can create a parcel job: pickup address, dropoff address, package size/weight (e.g. up to 5 kg), notes | Must (phase) |
| C-61 | Parcel pricing shown before confirm (guide: from ~100 ETB class fees; exact app quote wins) | Must |
| C-62 | Prohibited items policy is shown; user must acknowledge | Must |
| C-63 | OTP (or dual confirmation) used at dropoff | Must |

### 6.7 Restricted categories

| ID | Requirement | Priority |
|----|-------------|----------|
| C-70 | Alcohol category requires age confirmation / blocked under-age accounts | Must |
| C-71 | Pharmacy: support discreet presentation; prescription-required items follow configured rules (upload or merchant verification) | Should |

---

## 7. Merchant functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| M-01 | Partner can apply with business details, category, license, phone, menu/product readiness | Must |
| M-02 | Ops reviews application (target 2–3 business days) and onboards menu + dashboard training | Must |
| M-03 | Merchant can manage catalog: items, prices, photos, modifiers, availability, hours | Must |
| M-04 | Merchant receives new order alerts (push/sound) and can **Accept** or **Reject** with reason | Must |
| M-05 | Merchant marks order **Preparing** / **Ready for pickup** | Must |
| M-06 | Merchant sees today’s orders, history, and basic sales insights (e.g. top items) | Should |
| M-07 | Commission and fees are transparent; exact rate set at onboarding by category | Must |
| M-08 | Payouts are weekly (schedule configurable); merchant sees payout statements | Must |
| M-09 | Merchant does **not** need own delivery fleet; Maekel/beU-style riders handle logistics | Must |
| M-10 | Merchant can pause store (busy / closed) | Must |
| M-11 | Stock-outs can be marked quickly; optional “suggest substitute” for grocery | Should |

---

## 8. Rider functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| R-01 | Rider onboarding: valid National ID, smartphone, Maps literacy, own bicycle (or approved vehicle), training before go-live | Must |
| R-02 | Rider can go Online/Offline and receive assigned or offer-based jobs | Must |
| R-03 | Job card shows pickup merchant, dropoff customer zone/address, ETA, payout, COD amount if any | Must |
| R-04 | Rider updates: Arrived pickup → Picked up → Arrived dropoff → Complete (OTP) | Must |
| R-05 | Rider navigates with external/embedded maps | Must |
| R-06 | Rider collects COD and confirms amount in app when applicable | Must |
| R-07 | Rider verifies customer OTP to complete delivery | Must |
| R-08 | Rider earnings: per-delivery pay, weekly payout visibility | Must |
| R-09 | Rider can report issues (customer unreachable, wrong address, merchant delay) | Must |
| R-10 | Dispatch/support can reassign jobs | Must |

---

## 9. Business / corporate functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| B-01 | Business can request: document/parcel courier, e-commerce last-mile, pharmacy distribution, corporate meals | Should |
| B-02 | Support scheduled / recurring corporate meal orders | Should |
| B-03 | Postpaid invoicing and SLA reporting for contracted accounts | Could |
| B-04 | Dedicated account manager workflow on ops side (CRM note / assignment) | Could |
| B-05 | Business portal or ops-assisted onboarding is acceptable for early phases | Should |

---

## 10. Pricing & fees

| ID | Requirement | Priority |
|----|-------------|----------|
| P-01 | Standard delivery fee is distance/order-based; UI always shows exact fee pre-confirm | Must |
| P-02 | Reference bands (configurable, not hard-coded forever): standard from ~**47 ETB**; extended (~7 km+) from ~**160 ETB**; parcel from ~**100 ETB** | Should |
| P-03 | Fees may vary with demand, weather, order size — changes must still be visible before confirm | Should |
| P-04 | Merchant commission is separate from customer delivery fee | Must |
| P-05 | Promo codes / free-delivery campaigns can reduce customer-facing fee | Should |

---

## 11. Coverage & availability

| ID | Requirement | Priority |
|----|-------------|----------|
| V-01 | Service limited to configured Addis Ababa districts / geofence | Must |
| V-02 | Merchants shown only if within configured radius of delivery location (~20 km default) | Must |
| V-03 | Outside coverage: clear empty state + option to save address for later | Must |
| V-04 | Platform operating window enforced; after-hours browsing may be allowed with next-available messaging | Should |
| V-05 | Per-merchant hours gate ordering | Must |

---

## 12. Notifications

| ID | Requirement | Priority |
|----|-------------|----------|
| N-01 | Notify customer on: confirmed, preparing, picked up, on the way, delivered, cancelled | Must |
| N-02 | Notify merchant on: new order, cancellation, rider assigned/arrived | Must |
| N-03 | Notify rider on: new job, changes, support messages | Must |
| N-04 | Channels: in-app + push; SMS optional for critical OTP/payment | Should |

---

## 13. Support & trust/safety

| ID | Requirement | Priority |
|----|-------------|----------|
| S-01 | In-app Help with FAQ + contact (phone hotline pattern e.g. short code, email) | Must |
| S-02 | Order-linked support tickets | Must |
| S-03 | Riders are vetted; ops can suspend accounts | Must |
| S-04 | Prohibited items list for parcels; blocklisted SKUs configurable | Must |
| S-05 | Privacy Policy / Terms accessible from Food and Maekel settings | Must |
| S-06 | Personal data minimization; never log full payment secrets or OTPs in plain analytics | Must |

---

## 14. Admin / ops console (high level)

| ID | Requirement | Priority |
|----|-------------|----------|
| A-01 | Manage merchants, menus (override), commissions, payouts | Must |
| A-02 | Manage riders, training status, suspensions | Must |
| A-03 | Live order board + manual assign/reassign | Must |
| A-04 | Configure zones, fees, surge, categories, platform hours | Must |
| A-05 | Customer support tools: cancel, refund, resend OTP, compensate | Must |
| A-06 | Content: banners, deals, featured merchants | Should |
| A-07 | Reporting: orders, GMV, delivery times, cancellation reasons | Should |

---

## 15. Key user flows (acceptance-oriented)

### 15.1 Happy path — food order

1. User opens Maekel → Food.  
2. Confirms Addis delivery address in coverage.  
3. Browses category → merchant → adds items.  
4. Reviews cart (items + delivery fee + total).  
5. Selects payment (e.g. COD or wallet).  
6. Places order → sees **Confirmed** + OTP.  
7. Status advances through preparing / picked up / on the way.  
8. Rider arrives; user shares OTP → **Delivered**.  
9. Optional rating.

### 15.2 Merchant fulfill

1. Merchant receives alert → Accept.  
2. Prepares → marks Ready.  
3. Rider picks up.  
4. Order leaves merchant responsibility for delivery quality handoff (except packing errors handled via support).

### 15.3 Rider complete

1. Rider accepts/receives job → navigates to merchant → confirms pickup.  
2. Navigates to customer → requests OTP → completes.  
3. If COD, records collection.

### 15.4 Cancel before prep

1. Customer cancels while status is Confirmed only.  
2. Merchant/rider notified; payment authorized amounts released/refunded per method rules.

---

## 16. Data entities (logical)

- User (Maekel identity), Address, PaymentMethod  
- Merchant, MerchantHours, CatalogCategory, CatalogItem, Modifier  
- Cart, CartLine, Order, OrderLine, OrderStatusEvent, DeliveryFeeQuote  
- DeliveryJob, Rider, DispatchAssignment  
- PaymentTransaction, Payout, CommissionRule  
- Promo, Review, SupportTicket  
- ParcelShipment (pickup/dropoff/package meta)  
- BusinessAccount, Invoice (later)

---

## 17. Non-functional requirements (product-relevant)

| ID | Requirement | Priority |
|----|-------------|----------|
| NF-01 | Critical path (browse → place order) usable on mid-range Android in Addis network conditions | Must |
| NF-02 | Order status updates feel near-real-time (push or short polling ≤ 15–30s while active) | Must |
| NF-03 | Prices and stock consistent between list, detail, and checkout at confirm time | Must |
| NF-04 | Offline-tolerant draft cart; hard fail only at payment/place with clear retry | Should |
| NF-05 | Accessibility: readable type sizes, sufficient contrast, screen-reader labels on primary actions | Should |
| NF-06 | Security: HTTPS APIs, tokenized session, OTP rate limits, role-based access for merchant/rider/admin | Must |
| NF-07 | Audit trail for order status changes and payout calculations | Must |

---

## 18. Success metrics (product)

| Metric | Target direction (tune later) |
|--------|-------------------------------|
| Order placement conversion (browse → paid/placed) | Increase |
| Average delivery time | Approach ~59 min city-wide target |
| Cancellation rate after accept | Decrease |
| OTP completion rate | High |
| Merchant acceptance time | Decrease |
| Customer support contacts per order | Decrease |
| Weekly active orderers in Addis | Increase |

---

## 19. Assumptions & open questions

**Assumptions**

- Maekel Food is a **beU-class** multi-category delivery vertical, not food-only forever.  
- Riders are platform-managed (gig), not merchant-employed, for standard orders.  
- MVP can ship without live GPS tracking.  
- Shared Maekel auth is source of truth for customer identity.

**Open questions for stakeholders**

1. Is the consumer brand name inside the hub **“Food”**, **“Delivery”**, or a Maekel sub-brand?  
2. Single vs multi-merchant cart for V1?  
3. Which wallets are day-one mandatory (Telebirr, M-PESA, CBE Birr, etc.)?  
4. Who owns merchant acquisition ops — in-house like beU partner flow?  
5. Parcel and pharmacy in MVP or immediately after food/grocery?  
6. Do we need a separate merchant/rider app vs role modes inside Maekel?

---

## 20. Traceability to beU public product behaviors

Mapped from public beU materials ([beudelivery.com](https://beudelivery.com/)):

| beU behavior | Maekel FR IDs |
|--------------|---------------|
| Multi-category delivery in Addis | §2, C-03 |
| ~59 min / city-wide / 20 km / 23+ districts | §2, V-01–V-02 |
| Browse → pay → status → OTP handover | C-20–C-45 |
| COD + digital wallets / bank | C-25, C-30–C-32 |
| Cancel before preparation | C-50 |
| Merchant partner growth, weekly payouts, platform riders | M-01–M-09 |
| Rider training + own bike + smartphone | R-01 |
| Parcel from ~100 ETB, OTP | C-60–C-63, P-02 |
| Business courier / last-mile / corporate meals / SLA | B-01–B-03 |
| Hours ~07:30–midnight | §2, V-04 |

---

## 21. Document history

| Version | Date | Notes |
|---------|------|-------|
| 0.1 | 2026-11-15 | Initial FR draft from beU public product + Maekel super-app shell plan |
