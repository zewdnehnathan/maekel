# Events — production MVP bar (as of 23 Nov 2026)

Phones / roles: [qa-test-phones-and-roles.md](./qa-test-phones-and-roles.md).

---

## Status

| Module | Product-MVP bar |
|--------|-----------------|
| Events | **Yes** (same bar as Market/Food/Ride for the cut) |

---

## Events production bar

| Capability | Implementation |
|------------|----------------|
| Browse | Category + subcity + search; approved upcoming only |
| Detail | Venue, time, price, capacity, organizer |
| RSVP / tickets | Free or pay-at-door; ticket code; cancel reserved |
| Host | Create/edit → pending moderation; my events |
| Check-in | Organizer attendees list + ticket code / one-tap |
| Live host board | Polls my events / attendees every **3s** |
| Live ops | Events ops polls queue every **4s** |
| Thin ops | Approve / reject / force cancel / suspend organizer |
| Roles | `events_attendee`, `events_organizer` (default); `events_ops` (staff) |

**Setup:** Host creates event → Events ops approves → guests RSVP.

### Still post-MVP
- Push / FCM (polling used)
- Online paid tickets + refunds
- QR check-in, seat maps, recurring series
- “Get a Ride there” deep-link

---

## Deploy note

Requires Postgres database **`maekel_events`** (see `backend/scripts/create-neon-dbs.sql`).  
Flutter + `events-service` ship together; redeploy API then web/APK.
