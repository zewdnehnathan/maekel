# Ride — production MVP bar (as of 23 Nov 2026)

Against [mvp-cut-ride-food-market.md](./mvp-cut-ride-food-market.md) §3 and [mvp-qa-guide.md](./mvp-qa-guide.md) Groups B–C.

Phones / roles: [qa-test-phones-and-roles.md](./qa-test-phones-and-roles.md).

---

## Production bar (this ship)

| Capability | Implementation |
|------------|----------------|
| **Fare** | `max(minFare, base + perKm × haversine_km)` — defaults 100 + 16×km, min 120 ETB. Ops-configurable. |
| **Quote** | Binding ETB total + distance + ETA before Request; locked on trip |
| **Pins / search** | Map pin lat/lng required for quote; place search (Bole, Piassa, …); geofenced to Addis |
| **Match** | Online **approved** drivers within offer radius (default 8 km); 45s accept TTL; no seed auto-assign |
| **Live GPS** | Driver posts location every ~5s while online; passenger map prefers live driver point |
| **Contact** | Call driver (`tel:`) |
| **Cash + rate + history** | Unchanged happy path; history shows time + driver |
| **Driver earnings / report** | Today’s earnings; no-show / wrong-pin report |
| **Ride ops** | Approve/suspend drivers, force-cancel trips, edit fare params (`ride_ops` / platform admin) |

Bootstrap admin (`+251999999999`) gets `ride_ops` and is auto-approved as a driver.

Regular Drive accounts start **unapproved** until Ride ops approves them.

---

## Still post-MVP (not required to deploy this bar)

- Mobile money / card  
- Surge / multi class / scheduled rides  
- Masked/relay calling  
- Turn-by-turn navigation  
- Push notifications (polling is used)  
- Real road-network routing (haversine distance, not OSRM)  
- SOS / share-trip  

---

## QA flow before deploy

1. Admin OTP → **Ride ops** → set fare if needed  
2. Test driver OTP → open Drive (pending) → admin **Approve** → driver goes **Online** (GPS on)  
3. Passenger: search/pin pickup+dropoff → quote shows km + ETB → Request  
4. Driver: accept within countdown → advance → confirm cash  
5. Passenger: call, rate, check Trips history  

**Do not deploy until** this build is committed and you are ready to redeploy `identity-service` + `ride-service` (gateway demo stack) and the Flutter web/APK.
