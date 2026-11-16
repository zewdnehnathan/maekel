# Maekel First-Release Testing Guide & Checklist

**What Maekel is:** One mobile app with three main parts — Ride (like a taxi call), Food (order food or groceries), and Market (buy and sell used or new items).  
**Version:** 0.4  
**Where it launches:** Addis Ababa  
**Money:** Ethiopian Birr  
**Phone numbers:** Ethiopia numbers starting with +251  
**PDF copy:** [`mvp-qa-guide.pdf`](./mvp-qa-guide.pdf)

**How to use this checklist**  
1. Read each short story (what the user wants).  
2. Tick every box under **What must be true**.  
3. A story is finished only when every box is ticked.  
4. If something critical is broken (see “How serious is the problem?” at the end), do not call the first release ready.

---

## 1. What “first release ready” means

When we say the first release is ready, a person with one phone number can:

| Step | Part of the app | What they can do |
|------|-----------------|------------------|
| 1 | Sign-in and Home | Enter phone number, get a verification code, open Home, then open Ride, Food, and Market without signing in again |
| 2 | Ride | Request a car, see the driver on the map, pay with cash, and leave a rating. The same phone can also be used as a driver after approval |
| 3 | Food | Order from a restaurant or grocery, pay with cash on delivery, and confirm handover with a delivery verification code |
| 4 | Market | Post an item for sale, wait for approval, then buyers can find it, chat, and call |

**Not required for the first release** (do not fail the release if these are missing): playable games, reward points, paid “boost” ads, pharmacy or parcel delivery, booking a ride for later, live map of the food delivery person, ordering from two shops in one cart.

---

## 2. Suggested test people (phone accounts)

Use different phones or accounts so you can play each role.

| Label | Who they act as | Notes |
|-------|-----------------|-------|
| Person 1 | Everyday customer | Passenger, food customer, and Market buyer/seller |
| Person 2 | Ride driver | Must be approved before they can go online; can also try passenger mode on the same phone |
| Person 3 | Restaurant or shop | Accepts and prepares food orders |
| Person 4 | Food delivery person | Collects the order and finishes delivery with the customer’s verification code |
| Person 5 | Reviewer / admin | Approves Market ads and can suspend a bad user |

**Important rule:** One phone number = one Maekel account. The same person can be a passenger and a driver, or a buyer and a seller, without creating a second account.

---

## 3. Pictures (also in the PDF)

1. How the app connects to the system  
2. One phone, many roles  
3. Ride trip steps  
4. Food order steps and delivery verification code  
5. Market: post → review → show to buyers → chat  
6. Drivers, food delivery people, and Market sellers are separate groups  
7. Final “ready to release” gate  

---

## 4. User stories and checklists

Mark each empty box when you have checked it yourself.

---

### Group A — Sign-in and Home

#### Story A01 — Sign in with phone and verification code
**As a** new customer, **I want to** sign in with my Ethiopian phone number and a verification code, **so that** I can use Maekel with one account.

**What must be true**
- [ ] I can enter a valid Ethiopian mobile number (country code +251)
- [ ] After I enter the correct verification code, I reach the Home screen
- [ ] If the code is wrong, I see a clear error and I am not signed in
- [ ] After I sign in once, opening Ride, Food, or Market does not ask me to sign in again
- [ ] When I sign out, I return to the sign-in screen and my session is cleared

#### Story A02 — Home screen shortcuts
**As a** signed-in customer, **I want** clear buttons for Ride, Food, and Market, **so that** I can open each part quickly.

**What must be true**
- [ ] Home shows the Maekel name and entries for Ride, Food, and Market
- [ ] Tapping each entry opens that part without the app crashing
- [ ] Games can be a simple placeholder and must not block the first release
- [ ] Leaving a part and returning to Home keeps me signed in

#### Story A03 — Same phone, different roles
**As a** customer, **I want** one phone number to work as passenger and driver, and as buyer and seller (and food roles when allowed), **so that** I do not need two accounts.

**What must be true**
- [ ] The same account can use Ride as a passenger and, after approval, as a driver
- [ ] The same account can browse Market and also sell / manage my ads
- [ ] Switching role does not require registering a second phone number
- [ ] Special roles (driver, shop, food delivery person, reviewer) stay blocked until someone approves them

#### Story A04 — Saved addresses
**As a** customer, **I want to** save places I use often, **so that** ordering food (and setting a pickup) is faster.

**What must be true**
- [ ] I can save at least one place with a name (for example Home or Work)
- [ ] Food checkout can use a saved place
- [ ] If a place is outside the delivery area, I see a clear message

---

### Group B — Ride (passenger)

#### Story B01 — Choose pickup and drop-off
**As a** passenger, **I want to** set where I am picked up and where I go, **so that** I can request a trip in Addis Ababa.

**What must be true**
- [ ] Pickup can use my phone location, or I can move the pin / search for a place
- [ ] I can set drop-off by search or by moving the pin
- [ ] Outside the service area, I cannot request a trip, and the message is easy to understand

#### Story B02 — See the price before I request
**As a** passenger, **I want to** see the trip price in Ethiopian Birr before I request, **so that** I am not surprised later.

**What must be true**
- [ ] After I set pickup and drop-off, the price is shown in Ethiopian Birr
- [ ] The first release shows one car type only (for example a normal sedan)
- [ ] I cannot tap Request until I have seen the price
- [ ] On a normal successful trip, the price at the end matches the price I saw before Request

#### Story B03 — Request and get a driver
**As a** passenger, **I want to** request a ride and be matched with a driver, **so that** someone comes to pick me up.

**What must be true**
- [ ] After Request, I see a “looking for driver” (or similar) state
- [ ] When matched, I see the driver’s name, photo or placeholder, rating, car, plate number, and how soon they arrive
- [ ] If I tap Request twice by mistake, only one trip is created
- [ ] If no driver is found, I see a clear message and I can try again

#### Story B04 — Follow the trip on the map
**As a** passenger, **I want to** see the driver on the map, **so that** I know when they are coming and where we are going.

**What must be true**
- [ ] After a driver is assigned, the map shows them moving toward pickup
- [ ] Status moves through: assigned → arriving → arrived → trip in progress → finished or cancelled
- [ ] During the trip, the map shows progress toward drop-off
- [ ] If I go back to Home during a trip, I can open the active trip again (for example a badge or “trip in progress”)

#### Story B05 — Contact the driver
**As a** passenger, **I want to** contact my driver, **so that** we can coordinate pickup.

**What must be true**
- [ ] After matching, I can call (masked number is fine) **or** use in-app chat — at least one of these must work

#### Story B06 — Cancel before the trip starts
**As a** passenger, **I want to** cancel before the trip starts, **so that** I am not forced to ride.

**What must be true**
- [ ] Cancel is available before the trip is in progress
- [ ] After cancel, the trip shows as cancelled and the driver is freed for other trips

#### Story B07 — Pay cash, rate, and see past trips
**As a** passenger, **I want to** pay with cash, rate the driver, and see my past trips, **so that** the trip feels complete.

**What must be true**
- [ ] At the end, both passenger and driver see the cash amount clearly
- [ ] I can leave a rating from 1 to 5 after the trip
- [ ] The trip appears in my history with price, time, and driver summary

---

### Group C — Ride (driver)

#### Story C01 — Go online and receive trip offers
**As an** approved driver, **I want to** go online and receive trip offers, **so that** I can earn money.

**What must be true**
- [ ] A driver who is not approved cannot go online
- [ ] Online / offline switch works; offline means no new offers
- [ ] An offer shows roughly where pickup is, the price estimate, and a time limit to accept

#### Story C02 — Finish the driver steps for a trip
**As a** driver, **I want to** accept → mark arrived → start → complete, **so that** the trip steps are correct.

**What must be true**
- [ ] Accept links me to the passenger’s trip
- [ ] I can mark Arrived, Start, and Complete in that order
- [ ] When paying by cash, I can confirm I collected the money
- [ ] Today’s earnings list updates after I complete a trip
- [ ] Reporting a problem (passenger no-show, wrong pin) does not crash the app

---

### Group D — Food (customer)

#### Story D01 — See shops that can deliver to me
**As a** customer, **I want to** see restaurants and grocery shops that deliver to my pin, **so that** I only browse what I can order.

**What must be true**
- [ ] I set or confirm a delivery place before or when I start browsing
- [ ] Only shops that can deliver to that place are shown
- [ ] First release includes restaurants/food and groceries
- [ ] Each shop shows name, open or closed, and a hint about fee or delivery time
- [ ] Outside the delivery area, I see a clear empty or blocked message

#### Story D02 — Build a cart from one shop
**As a** customer, **I want to** add items with amounts and options from one shop, **so that** I can check out a single order.

**What must be true**
- [ ] Each item shows price in Ethiopian Birr and whether it is available
- [ ] Unavailable items cannot be added (or are clearly blocked)
- [ ] The cart shows items, subtotal, delivery fee, and total
- [ ] In the first release, one cart is for one shop only

#### Story D03 — Place an order and pay with cash on delivery
**As a** customer, **I want to** confirm my address and place an order paid with cash when it arrives, **so that** the shop can prepare my food.

**What must be true**
- [ ] Before I place the order, I see the exact delivery fee
- [ ] Paying with cash on delivery is available
- [ ] After I place the order, I get an order number and status “confirmed” (or clear equivalent)
- [ ] If a shop has a minimum order amount, it is enforced

#### Story D04 — Follow the order and confirm with a delivery code
**As a** customer, **I want to** follow my order status and confirm handover with a delivery verification code, **so that** delivery is safer.

**What must be true**
- [ ] Status moves: confirmed → preparing → picked up → on the way → delivered or cancelled
- [ ] I receive a delivery verification code
- [ ] The order cannot show as delivered unless the delivery person enters the correct code (unless an admin specially overrides)
- [ ] The order appears in my order history

#### Story D05 — Cancel only before the shop starts preparing
**As a** customer, **I want to** cancel only before the shop starts preparing, **so that** shops do not waste food and time.

**What must be true**
- [ ] I can cancel while the order is still only confirmed
- [ ] After preparing has started, cancel is blocked and the message is clear

---

### Group E — Food (shop and delivery person)

#### Story E01 — Shop accepts and prepares the order
**As a** shop, **I want to** accept and prepare orders, **so that** a delivery person can pick them up.

**What must be true**
- [ ] A new order is visible (and ideally notifies me)
- [ ] I can accept or reject
- [ ] I can mark preparing and ready for pickup
- [ ] I can pause my shop so new orders stop

#### Story E02 — Delivery person finishes with the verification code
**As a** food delivery person, **I want to** pick up the order and finish delivery with the customer’s verification code, **so that** cash-on-delivery handovers are checked.

**What must be true**
- [ ] I see where to pick up and where to drop off
- [ ] I can mark picked up and on the way
- [ ] Finishing the delivery requires the customer’s verification code
- [ ] When paying by cash, the amount to collect is shown
- [ ] Food delivery people are a separate group from Ride drivers (the app does not mix the two job lists)

---

### Group F — Market (buy and sell)

#### Story F01 — Browse and search listings
**As a** buyer, **I want to** browse categories and search or filter listings, **so that** I find items near me.

**What must be true**
- [ ] At least four to six main categories are available
- [ ] Keyword search works
- [ ] I can filter by place, price, and condition (new/used) as designed
- [ ] Each card shows a photo, price in Ethiopian Birr, title, and place
- [ ] Only **approved** listings appear in public browse and search

#### Story F02 — Open a listing and contact the seller
**As a** buyer, **I want to** open a listing and chat or call the seller, **so that** we can agree on a meetup.

**What must be true**
- [ ] Detail page shows photos, description, key details, and seller info
- [ ] Safety tips appear before the first contact (or an equally clear warning)
- [ ] In-app chat sends and receives text messages
- [ ] Call button works according to the seller’s phone visibility setting
- [ ] Chat shows a safety reminder (for example: do not pay before you see the item)

#### Story F03 — Save favorite listings
**As a** buyer, **I want to** save favorites, **so that** I can find them again later.

**What must be true**
- [ ] I can add and remove a favorite from the list or detail page
- [ ] My favorites list shows what I saved

#### Story F04 — Post something for sale
**As a** seller, **I want to** post a listing with photos and details, **so that** buyers can find it after it is approved.

**What must be true**
- [ ] Sell flow covers: category → photos → title and description → price → key details → place → submit
- [ ] I can upload more than one photo
- [ ] After submit, the listing is **waiting for review** and is **not** shown to the public yet
- [ ] If there is a maximum number of active free listings, it is enforced

#### Story F05 — Review listings before they go public
**As a** reviewer, **I want to** approve or reject listings, **so that** only safe ads go live.

**What must be true**
- [ ] I can see a list of listings waiting for review
- [ ] Approve makes the listing public and notifies the seller
- [ ] Reject keeps it off public search and shows the seller a reason
- [ ] A report from a buyer is visible to the review team

#### Story F06 — Manage my listings
**As a** seller, **I want to** manage my listings, **so that** I can edit them, close them, or mark them sold.

**What must be true**
- [ ] “My ads” shows active, waiting, rejected, and sold (or clear equivalent names)
- [ ] Edit works (big changes may need review again)
- [ ] Mark sold or delete closes the listing in a clear way

---

### Group G — Across the whole app / ready to release

#### Story G01 — One sign-in for the whole app
**As a** customer, **I want** one sign-in for Ride, Food, and Market, **so that** Maekel feels like one product.

**What must be true**
- [ ] After I sign in once, moving between Ride, Food, and Market never asks for a new verification code

#### Story G02 — Stop a bad user
**As an** admin, **I want to** suspend a user, **so that** we can stop abuse.

**What must be true**
- [ ] A suspended user cannot request rides, place food orders, or post Market ads (as designed)
- [ ] Their public Market ads can be taken down when needed

#### Story G03 — Final ready-to-release checklist
**As** the person signing off the first release, **I want** one final list, **so that** we know we can launch.

**What must be true**
- [ ] Stories A01–A03 pass
- [ ] A full Ride cash trip passes (Groups B and C)
- [ ] A full Food cash-on-delivery trip with verification code passes (Groups D and E)
- [ ] Market post → review → browse → chat passes (Group F)
- [ ] No critical open problems: two trips from one request, delivered without verification code, waiting listing shown to public, or signing in without a valid code
- [ ] Outside-area / empty messages checked for Ride and Food

---

## 5. How serious is the problem?

| Level | Meaning | Examples |
|-------|---------|----------|
| Critical | Must fix before launch | Sign-in without a valid code; two trips from one request; order marked delivered without verification code; listing still waiting for review but already public |
| Major | Should fix before first release if it is in this checklist | Wrong price at the end of a trip; chat not sending; cancel allowed after the shop started preparing |
| Minor | Can fix soon after launch | Wording, layout, small empty-state polish |
| Later | Not part of first release | Missing reward points, paid ad boost, pharmacy, etc. |

---

## 6. Document history

| Version | Date | Notes |
|---------|------|-------|
| 0.1 | 2026-11-15 | First testing guide and pictures |
| 0.2 | 2026-11-15 | Added user stories and checklists |
| 0.3 | 2026-11-15 | Plain language; no short forms |
| 0.4 | 2026-11-15 | Removed unnecessary audience callouts |
