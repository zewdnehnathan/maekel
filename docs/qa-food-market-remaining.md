# Food & Market — production MVP bar (as of 23 Nov 2026)

Against [mvp-cut-ride-food-market.md](./mvp-cut-ride-food-market.md) and [mvp-qa-guide.md](./mvp-qa-guide.md) Groups D–F.

Phones / roles: [qa-test-phones-and-roles.md](./qa-test-phones-and-roles.md).

---

## Status

| Module | QA stories | Product-MVP bar |
|--------|------------|-----------------|
| Food D + E | **7 / 7** | **Yes** (same bar as Ride/Market for the cut) |
| Market F | **6 / 6** | **Yes** |

---

## Food production bar (this ship)

| Capability | Implementation |
|------------|----------------|
| Coverage browse | Pin/subcity filter; restaurants + groceries |
| Cart / COD | Single-shop cart; fee + total before place; COD |
| OTP handover | Rider complete with OTP; ops can force-deliver |
| Cancel | Blocked after preparing |
| Merchant console | Accept/reject/prepare/ready; pause; menu + photos |
| **Live kitchen** | Merchant console polls orders/menu every **3s** |
| **Live rider** | Rider board polls available/active every **3s** |
| **Live ops** | Food ops board polls every **4s** |
| **Modifiers** | Merchant add/edit dish **options** (name + ETB); customer picker already works |
| Thin ops | Onboard merchant, assign owner, reassign rider, support cancel |

**Setup (not a code gap):** create merchant → assign owner → menu → grant `food_rider`.

### Still post-MVP for Food
- Push / FCM (polling used, same pattern as Ride)
- Distance-band delivery fees (flat merchant fee OK for cut)
- Live rider map, ratings polish, digital wallet

---

## Market (unchanged — already on bar)

Browse → sell → moderate → chat/call → favorites / My ads → ops. Soft only: offline retry, push, chat ACL hardening.

---

## Deploy note

Food production-bar changes are **Flutter-side** (poll + modifiers UI). Redeploy web/APK when ready; food-service already accepts `modifiers` on menu create/patch.
