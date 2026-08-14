# Film pack products — pricing and App Store Connect setup

Decided 2026-08-14. Prices live in three places and must stay in step:
`app/Tumble.storekit` (local testing), App Store Connect (real purchases),
and `web/src/components/FilmPacks.tsx` (the site).

## The lineup

| Product | Reference name | Price (USD) | Product ID |
|---|---|---|---|
| Ninety-Six | Ninety-Six Film Pack | $1.99 | `com.tumble.pack.nineties` |
| Darkroom | Darkroom Film Pack | $1.99 | `com.tumble.pack.darkroom` |
| Long Summer | Long Summer Film Pack | $1.99 | `com.tumble.pack.summer` |
| All packs | All Film Packs | $4.99 | `com.tumble.pack.all` |

All four are **non-consumable**, one-time, non-family-shareable — the same
stance as the Roll tiers. No subscriptions, ever.

## Why $1.99

- **Impulse, not deliberation.** The paywall appears seconds after a shooter
  watched a print develop and saw locked looks. $1.99 is the price people tap
  without doing arithmetic.
- **It stays under Plus.** Three packs at $1.99 total $5.97, just below the
  $5.99 Plus tier, so looks and shot-count never compete for the same wallet
  moment. At $2.99 each the packs total $8.97 and start crowding Unlimited
  ($11.99) — which would make content feel like the main product instead of
  the roll.
- **$0.99 undersells it.** Five hand-graded stocks per pack, and Apple's cut
  leaves ~$0.69. With low install volume, per-sale value matters.

## Why the bundle exists

Most people who buy one pack would have bought all three. $4.99 saves them a
dollar and nearly triples the average sale. `PurchaseManager.ownsPack` treats
the bundle as an unlock path for every paid pack, so buying it also covers
packs added later — a deliberate promise, and the reason it is sold as "all
film packs" rather than "these three".

## App Store Connect checklist

1. **Monetization → In-App Purchases → +**, type **Non-Consumable**, for each
   of the four product IDs above. The IDs must match exactly — the app asks
   StoreKit for these strings by name.
2. Price: **$1.99** (packs) / **$4.99** (bundle) as the US base. Leave Apple's
   automatic territory conversion on; do not hand-set per-country prices.
3. Display name and description: copy the `localizations` blocks from
   `app/Tumble.storekit` so the store and the app agree word for word.
4. Each product needs a **review screenshot** — a capture of `PackPaywallView`
   showing that pack. Apple rejects IAPs without one.
5. Set **Availability** to all territories.
6. Submit the products **with the build**, not before. Products submitted alone
   sit in "Waiting for Review" against nothing.

## Before shipping

- [ ] Buy each pack in the simulator against `Tumble.storekit`; confirm the
      looks unlock and survive a relaunch.
- [ ] Buy the bundle; confirm all three packs unlock and the bundle offer
      disappears from the paywall.
- [ ] Delete and reinstall, then **Restore purchases**; confirm packs come back.
