# In-app purchase review screenshots

One screenshot per film-pack product, for the **Review Information → Screenshot**
field on each in-app purchase in App Store Connect. Apple rejects an IAP that
has no screenshot showing where the purchase is offered.

Each file is named for the product it belongs to, so there is nothing to match
up by hand:

| File | Attach to |
|---|---|
| `com.tumble.pack.nineties.png` | Ninety-Six Film Pack |
| `com.tumble.pack.darkroom2.png` | Darkroom Pack |
| `com.tumble.pack.summer.png` | Long Summer Film Pack |
| `com.tumble.pack.all.png` | All Film Packs |

All four show `PackPaywallView` — the store card a shooter reaches by tapping a
locked look — with that pack's five stocks rendered over one shared sample
scene. The bundle is sold from the same card, under the single-pack button, so
its screenshot is the same card with the "take every pack" offer visible.

## Regenerating

```sh
./scripts/capture-iap-screenshots.sh
```

Rebuilds, installs to a booted simulator, and drives the app straight to each
pack's card using the `-packPaywall <packID>` debug launch argument
(`app/Tumble/App/DebugLaunch.swift`). Re-run this after any paywall change —
Apple compares the screenshot against what the app actually shows.

Prices in these captures come from a DEBUG-only placeholder, because the
`.storekit` configuration is attached to the Xcode run scheme and is not loaded
by a command-line launch. They match the real prices ($1.99 / $4.99); the
shipping app always shows StoreKit's own localised price.
