# Agrilumina — Product Brief (MVP)

**Status:** Draft · Jul 2026  
**Brand:** Agrilumina (app/package/UI). Official logo/icon live under `assets/branding/`.  
**Design focus:** Usable anywhere; built for rural farmers with poor or intermittent phone networks (low bandwidth, phone-first). MVP seed data uses Bugobe and nearby rural markets (DRC) as sample context.

---

## Problem

Small agricultural sellers and buyers nearby each other have no simple, trustworthy way to discover each other. Trade still relies on word of mouth; funding and formal markets feel distant. Existing marketplace apps assume reliable data, rich profiles, and in-app chat — often a poor fit for this context.

## Who it’s for (MVP)

| Role | Primary user | Job to be done |
|------|----------------|----------------|
| **Seller (beachhead)** | Smallholder or trader with crop to sell | “Find a nearby buyer for my crop this week and get a way to contact them.” |
| Buyer (secondary) | Local trader / aggregator | “See what’s available nearby and signal interest.” |

**Out of scope for MVP:** lenders as users, full funding marketplace, multi-country expansion, in-app chat.

## One-sentence product

Agrilumina helps a seller discover nearby crop buyers, spend credits to unlock contact details, and request an intro — offline-friendly and phone-first.

## Core loop (MVP)

1. Choose role: **Seller** or **Buyer**.
2. See **nearby counterparts** within a radius (start with mock/seed data for Bugobe; later GPS).
3. Open a listing/profile: crop, quantity hint, distance, last active.
4. **Spend 1 credit** to unlock phone / WhatsApp intent (or “request intro”).
5. Balance updates everywhere; optional “buy credits” stub (no real payments yet).

## Must-have (MVP)

- Role selection that changes home + discover lists
- Nearby list from shared data (mock JSON → later API)
- Shared credits balance across screens
- Unlock-contact action that decrements credits
- Profile stub: name, role, location, crop interest
- Simple navigation shell (Home · Discover · Credits · Profile)

## Explicitly later

- Real payments / credit purchase
- Find Funding (cut or park until matching works)
- Maps, live GPS, messaging
- Ratings, verified badges at scale, admin tools
- Multi-language polish (plan for it; ship English + clear labels first)

## Success metrics (early)

- Seller can complete unlock-contact flow without confusion in under 2 minutes
- Credits balance stays consistent across screens
- At least 10 seed listings feel local and believable for Bugobe

## Brand decision (locked)

Ship as **Agrilumina**. Use `assets/branding/agrilumina_logo.png` (wordmark + emblem) and `assets/branding/agrilumina_icon.png` (emblem) for UI and launcher icons.

## Non-goals this quarter

- Building every named screen from the prototype
- Perfect design system before a working match slice
- Backend complexity beyond auth + listings CRUD

## Next build

**Vertical slice:** Seller → Discover nearby buyers (mock) → Unlock contact for 1 credit → Shared balance updates.
