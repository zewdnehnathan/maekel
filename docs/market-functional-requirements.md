# Maekel Market Module — Functional Requirements

**Product reference:** [Jiji Ethiopia](https://jiji.com.et/) (classifieds buy & sell marketplace)  
**Super app:** Maekel (Flutter) — this document defines the **Market** module as a first-class vertical inside Maekel.  
**Version:** 0.1 (draft)  
**Status:** Ready for product / engineering review  
**Currency / locale defaults:** ETB, +251, Ethiopia / Addis Ababa first, English + Amharic-ready  
**Related docs:** [Ride FRD](./ride-functional-requirements.md) · [Food / Delivery FRD](./food-delivery-functional-requirements.md)

---

## 1. Purpose

Define what Maekel’s classifieds / marketplace vertical must do for buyers and sellers — inspired by Jiji’s model (free ads, category browse, search/filters, photo listings, in-app chat + call, meet-and-pay-after-inspect, seller ratings, moderation, premium boost/TOP promotion) — while remaining a **module inside the Maekel super app**, not a standalone brand fork.

Maekel already owns (or will own):

- Shared phone/OTP auth and session
- Home hub navigation into Ride / Market / Food / Games
- Shared theme, i18n, and (later) chat, payments, notifications

This FRD specifies **Market module** behavior on top of that shell. The Maekel v1 shell plans **buy/sell listing stubs** (`/market`, `/market/sell`); this document is the product target those stubs grow into.

**Important product stance (Jiji-like):** Market is primarily a **classifieds** platform — sellers post ads; buyers discover and negotiate; fulfillment is peer-to-peer (meetup / optional delivery arranged with seller). Maekel does **not** take custody of goods in MVP. Platform monetization is via **premium listing promotion**, not marketplace checkout commission (unless later product decides otherwise).

---

## 2. Product summary

| Item | Requirement |
|------|-------------|
| What | Buy & sell almost anything via classified ads (goods, property, vehicles, services, jobs, etc.) |
| Who | Buyers, sellers (individuals + small businesses), moderators/ops |
| Where | Ethiopia-wide browse with strong Addis Ababa / city + subcity location filters |
| Model | Free to post (subject to fair-use limits); paid **Premium** for visibility |
| Discovery | Categories, keyword search, location, price/condition/attribute filters, trending |
| Contact | In-app chat and/or phone call; negotiate price & meetup/delivery |
| Fulfillment | Meet in public / arrange delivery; **pay after inspecting** (safety default) |
| Trust | Moderation before/after go-live, report flows, seller ratings, tenure badges, optional verified ID |
| Monetization | TOP placement, Boost packages, optional Pro Sales (CPC) — paid with mobile money / card / balance |

---

## 3. Actors & personas

| Actor | Goal |
|-------|------|
| **Buyer** | Find items locally, filter well, chat/call sellers, meet safely, leave feedback |
| **Seller** | Post ads with photos, get inquiries, manage listings, promote ads, close sales |
| **Business seller** | Higher volume listings, boost packages, faster response tools |
| **Moderator / Ops** | Review ads, remove spam/scams/prohibited items, handle reports, manage premiums |
| **Maekel shell** | Single login; hub entry; shared profile/phone; optional deep-link from Food/Ride later |

---

## 4. Scope boundaries

### 4.1 In scope (Market module product)

- Category taxonomy + browse
- Search, filters, sort, saved searches/favorites
- Post / edit / delete / renew ads (photos, title, description, price, attributes, location)
- Ad moderation workflow
- Seller public profile + ratings/feedback
- Buyer–seller messaging (chat) and call CTA
- Safety tips, report ad/user
- Premium services (TOP, Boost; Pro Sales later)
- My ads / My balance (promotion wallet)
- Jobs + services listing types (same classified engine with different attributes)
- Super-app integration routes and auth

### 4.2 Out of scope for this document

- Escrow / in-app checkout for goods (optional future; not Jiji core MVP)
- Maekel Food merchant catalog (different commerce model)
- Ride matching
- Games
- Full warehousing / Maekel-owned logistics for every listing (optional: “deliver with Maekel Food/parcel” deep-link later)

### 4.3 Phasing suggestion

| Phase | Focus |
|-------|--------|
| **MVP** | Browse categories + search/filters; listing detail; post ad with photos; moderation queue; chat; call; favorites; my ads; report; safety tips; shared Maekel auth |
| **V1.1** | Seller ratings/feedback, saved searches + new-match alerts, price suggestions, verified ID badge, image watermarking |
| **V1.2** | Premium TOP + Boost, seller balance/top-up, auto-renew, tenure badges, duplicate-ad detection |
| **V2** | Pro Sales CPC, bulk pricing / service period prices, Jobs/CV polish, “request delivery via Maekel” handoff |

---

## 5. Super-app integration requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| SA-01 | Market is reachable from Maekel Home hub as a primary module entry | Must |
| SA-02 | Authenticated Maekel session reused; phone-verified identity for posting & chat | Must |
| SA-03 | Routes: `/market`, `/market/c/:category`, `/market/ads/:id`, `/market/sell`, `/market/my-ads`, `/market/messages`, `/market/favorites` | Must |
| SA-04 | Prominent **Sell** entry (hub and/or Market bottom nav), matching Jiji’s Sell CTA | Must |
| SA-05 | Profile name/photo/phone from Maekel; Market extends with seller bio, location, ratings | Must |
| SA-06 | Push for new chat messages, ad approved/rejected, saved-search matches | Must |
| SA-07 | Locale (en/am) and ETB formatting follow Maekel shell | Must |
| SA-08 | Optional later: from an ad, offer “Book Maekel Ride to meetup” or “Request parcel delivery” | Could |
| SA-09 | Leaving Market keeps drafts and unread message badges intact | Must |

---

## 6. Category & discovery requirements

### 6.1 Categories (Jiji Ethiopia–aligned starter set)

Configurable taxonomy; launch set should cover at least:

| Category |
|----------|
| Vehicles |
| Property |
| Phones & Tablets |
| Electronics |
| Home, Furniture & Appliances |
| Fashion |
| Beauty & Personal Care |
| Services |
| Repair & Construction |
| Commercial Equipment & Tools |
| Leisure & Activities |
| Babies & Kids |
| Food, Agriculture & Farming |
| Animals & Pets |
| Jobs |
| Seeking Work — CVs |
| Business & Industry |

| ID | Requirement | Priority |
|----|-------------|----------|
| D-01 | Hierarchical categories with subcategories | Must |
| D-02 | Home shows category grid/list + trending ads | Must |
| D-03 | Keyword search across titles/descriptions (and key attributes) | Must |
| D-04 | Location filter: All Ethiopia → Region/City → Subcity/area (e.g. Addis Ababa, Bole) | Must |
| D-05 | Filters: price min/max, condition (new/used), category-specific attributes (brand, storage, transmission, etc.) | Must |
| D-06 | Sort: newest, price low/high, relevance; promoted ads may pin TOP slots | Must |
| D-07 | Listing cards show: primary photo, price (ETB), title, short snippet, location, condition, optional seller tenure/verified badge | Must |
| D-08 | Empty states when no results; suggest broader location/category | Must |
| D-09 | Trending / featured rail on home | Should |
| D-10 | Suggested categories mid-results when query is broad (Jiji pattern) | Could |

---

## 7. Buyer functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| B-01 | Open listing detail: gallery, price, title, description, attributes, location, posted time, seller card | Must |
| B-02 | Contact seller via **Chat** | Must |
| B-03 | Contact seller via **Call** (reveal or dial phone per privacy settings) | Must |
| B-04 | Save/favorite ads; view Favorites list; sort favorites | Must |
| B-05 | Save a search (query + filters); get notified when new matching ads appear; show new-count badge | Should |
| B-06 | See seller profile: active ads, rating, feedback, years on platform, verified badge | Must |
| B-07 | Leave feedback after a deal (prompted from chat / “Mark as dealt”) | Should |
| B-08 | Report ad or seller with reason codes (scam, duplicate, prohibited, wrong category, etc.) | Must |
| B-09 | Safety tips surfaced before first contact / call (no advance pay, public meetup, inspect before pay) | Must |
| B-10 | Share listing link externally | Should |
| B-11 | Make offer / negotiate in chat (free-text; structured offer optional) | Should |

---

## 8. Seller functional requirements

### 8.1 Posting ads

| ID | Requirement | Priority |
|----|-------------|----------|
| S-01 | Sell flow: choose category → photos → title/description → price → attributes → location → submit | Must |
| S-02 | Multi-photo upload from camera/gallery; reorder; set cover photo | Must |
| S-03 | Price in ETB; support negotiable flag; support bulk / per-period / service pricing fields where category needs them | Should |
| S-04 | Category attributes are dynamic (e.g. phone: brand, storage, condition; car: year, transmission, fuel) | Must |
| S-05 | Optional auto-generated title preview from attributes (Jiji pattern) | Should |
| S-06 | Price suggestion hint based on similar listings | Should |
| S-07 | Submit sends ad to **moderation**; seller notified on approve/reject with reason | Must |
| S-08 | Draft save if user exits mid-flow | Should |
| S-09 | Free posting with fair-use limits (max active ads / daily posts) configurable | Must |
| S-10 | Watermark uploaded images (anti-theft / provenance) | Should |

### 8.2 Managing ads

| ID | Requirement | Priority |
|----|-------------|----------|
| S-20 | My Ads: Active, Pending review, Declined, Expired, Sold/Closed | Must |
| S-21 | Edit ad (may re-enter moderation if material fields change) | Must |
| S-22 | Mark as sold / close / delete | Must |
| S-23 | Renew / refresh listing (manual or premium auto-renew) | Should |
| S-24 | View performance basics: views, chats started, calls (if tracked) | Should |
| S-25 | Reply to chats quickly; unread badges; optional SMS/push for new messages | Must |

### 8.3 Premium promotion

| ID | Requirement | Priority |
|----|-------------|----------|
| S-30 | **TOP**: pin ad near top of search/category results for fixed duration (e.g. 7 or 30 days) | Should |
| S-31 | **Boost** packages (e.g. 1/3/6/12 months): higher rotation in results + similar-ads placements; auto-renew interval (e.g. every 48h) | Should |
| S-32 | **Pro Sales** (later): CPC promotion with bid per click group; charge only on clicks | Could |
| S-33 | Seller wallet/balance: top-up via mobile money/card; transaction history | Should |
| S-34 | Clear pricing and what each package does before purchase | Must |
| S-35 | Promoted ads visually distinct but not deceptive | Must |

---

## 9. Chat & communication

| ID | Requirement | Priority |
|----|-------------|----------|
| M-01 | Threaded chat per buyer–seller–ad context | Must |
| M-02 | Text messages; image attach; optional quick replies (“Still available?”, “Lowest price?”) | Must |
| M-03 | Inbox lists conversations with unread counts | Must |
| M-04 | Block user; report conversation | Must |
| M-05 | Phone number reveal policy: always visible, or unlock after chat start, or seller-controlled — product must pick one (recommend seller-controlled + rate limits) | Must |
| M-06 | Safety banner in chat: don’t pay in advance | Must |
| M-07 | Optional “Deal done” → rate seller | Should |

---

## 10. Trust, safety & moderation

| ID | Requirement | Priority |
|----|-------------|----------|
| T-01 | Ads enter Pending → Approved / Rejected by moderators (SLA target: hours, Jiji cites ~couple of hours) | Must |
| T-02 | Prohibited items policy (weapons, illegal goods, etc.) enforced; reject + notify | Must |
| T-03 | Duplicate / spam listing detection (same photos/text across accounts) | Should |
| T-04 | Report queue with priority for scam patterns | Must |
| T-05 | Suspend users; unpublish all their ads | Must |
| T-06 | Verified ID badge after KYC/document check | Should |
| T-07 | Seller tenure badge (e.g. “3+ years on Maekel”) | Should |
| T-08 | Buyer education: public meetup, inspect before pay, no advance payment even for delivery | Must |
| T-09 | Copyright / IP takedown process for reported stolen images/listings | Should |

---

## 11. Jobs & services (classified specializations)

| ID | Requirement | Priority |
|----|-------------|----------|
| J-01 | Jobs category supports employer fields (role, salary range, location, type) | Should |
| J-02 | Seeking Work / CV listings with skills and contact preferences | Should |
| J-03 | Services support price-per-period or starting-at price | Should |
| J-04 | Same chat/call/report/moderation engine as goods | Must |

---

## 12. Notifications

| ID | Requirement | Priority |
|----|-------------|----------|
| N-01 | Ad approved / rejected | Must |
| N-02 | New chat message | Must |
| N-03 | Saved search: N new matching ads | Should |
| N-04 | Premium expiry / low balance | Should |
| N-05 | Feedback received | Could |

---

## 13. Admin / ops console (high level)

| ID | Requirement | Priority |
|----|-------------|----------|
| A-01 | Moderation queue: approve/reject/edit category; bulk actions | Must |
| A-02 | User admin: verify ID, suspend, warn | Must |
| A-03 | Report handling workflow | Must |
| A-04 | Category & attribute schema configuration | Must |
| A-05 | Premium product catalog & pricing | Should |
| A-06 | Analytics: posts, approvals, chats, GMV proxy (optional), scam rate | Should |
| A-07 | Content: trending rules, banners, safety tips CMS | Should |

---

## 14. Key user flows (acceptance-oriented)

### 14.1 Buy

1. Open Maekel → Market.  
2. Search or open category; set location/filters.  
3. Open ad → review photos/details/seller.  
4. Chat or call → negotiate → meet/inspect → pay seller offline.  
5. Leave feedback.

### 14.2 Sell

1. Tap Sell → pick category → upload photos → fill details/price/location.  
2. Submit → Pending review.  
3. Approved → appears in search.  
4. Answer chats/calls → mark sold.  
5. (Later) Buy TOP/Boost from wallet.

### 14.3 Moderation

1. Seller submits.  
2. Moderator reviews photos/text/category/policy.  
3. Approve → live + notify; or Reject with reason → seller can edit/resubmit.

---

## 15. Data entities (logical)

- User (Maekel identity), SellerProfile, VerificationStatus  
- Category, CategoryAttributeDefinition  
- Ad, AdPhoto, AdAttributeValue, AdStatus, AdStats  
- Favorite, SavedSearch  
- Conversation, Message  
- Feedback/Review  
- Report, ModerationDecision  
- PremiumProduct, Promotion entlement, SellerWallet, WalletTransaction  
- BlockList entry  

---

## 16. Non-functional requirements (product-relevant)

| ID | Requirement | Priority |
|----|-------------|----------|
| NF-01 | Fast listing grid scroll with image thumbnails on mid-range Android | Must |
| NF-02 | Image upload resilient on flaky networks (retry, compression) | Must |
| NF-03 | Search results return in interactive time for common queries | Must |
| NF-04 | Chat delivery near-real-time while app open; reliable push when backgrounded | Must |
| NF-05 | Moderation actions audited | Must |
| NF-06 | PII protected; phone numbers not scraped easily; rate-limit contact actions | Must |
| NF-07 | Amharic text supported in titles, descriptions, chat | Must |

---

## 17. Success metrics (product)

| Metric | Target direction |
|--------|------------------|
| Ads posted / approved | Increase quality supply |
| Time-to-first-response on chats | Decrease |
| Chat → reported deal / feedback | Increase |
| Search → ad open rate | Increase |
| Scam reports per 1k ads | Decrease |
| Premium attach rate (among active sellers) | Healthy monetization |
| Duplicate/spam rejection rate | Controlled |

---

## 18. Assumptions & open questions

**Assumptions**

- Market is **Jiji-class classifieds**, not an Amazon-style cart checkout in MVP.  
- Payments for **goods** stay peer-to-peer; Maekel charges for **promotion**.  
- Phone OTP identity from Maekel is enough to post; email/social optional later.  
- Jobs/services reuse the same ad engine.

**Open questions for stakeholders**

1. Brand label in hub: **Market**, **Buy & Sell**, or other?  
2. Soft launch categories only (Phones, Electronics, Vehicles, Property) vs full Jiji set?  
3. Is phone number visible on every ad or chat-gated?  
4. Do we require ID verification before selling high-risk categories (phones, cars)?  
5. Escrow / “Pay with Maekel” for goods in roadmap?  
6. Deep-link meetup via Ride and delivery via Food/parcel — yes/no for V2?  
7. Free-ad caps for individuals vs businesses?

---

## 19. Traceability to Jiji public product behaviors

Mapped from [jiji.com.et](https://jiji.com.et/), About/FAQ, and app store listings:

| Jiji behavior | Maekel FR IDs |
|---------------|---------------|
| Free classifieds; sell anything to real people | §2, S-01–S-09 |
| Register; photos; SELL; category; moderation then live | S-01, S-07, T-01 |
| Search + filters; million-ad scale ambition | D-03–D-06 |
| Chat or call seller; negotiate | B-02–B-03, M-01–M-05 |
| Meet publicly; pay after inspecting; delivery arranged with seller | B-09, T-08 |
| Leave feedback on seller | B-07, B-06 |
| Safety tips + report seller | B-08–B-09, T-04 |
| Premium TOP & Boost; Pro Sales CPC | S-30–S-35 |
| ~16 category groups (vehicles → jobs/CVs) | §6.1 |
| Saved ads, seller ratings, verified ID, tenure, saved searches | B-04–B-06, T-06–T-07 |
| Price suggestions / clearer service & bulk price fields | S-03, S-06 |
| Ethiopia location + ETB pricing | D-04, S-03 |

---

## 20. Document history

| Version | Date | Notes |
|---------|------|-------|
| 0.1 | 2026-11-15 | Initial FR draft from Jiji Ethiopia public product + Maekel Market shell plan |
