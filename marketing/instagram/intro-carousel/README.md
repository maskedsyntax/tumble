# Tumble Instagram intro carousel

Six portrait slides at **1080 × 1350 px (4:5)**, ready for an Instagram feed carousel.

## Slide order

1. Meet Tumble — “A slower camera you can own.”
2. The daily roll — 12 free shots each day.
3. The ritual — shake to develop.
4. The film — 21 looks across four packs.
5. The Drawer — private, on-device keeping.
6. Download — App Store call to action.

## Recommended Instagram bio

```text
A slower camera you can own.
12 shots a day · shake to develop
Private on iPhone · no subscriptions
↓ Start your first roll
```

The website field should be `https://gettumbleapp.com` rather than spending bio characters on the URL.

## Suggested first-post caption

```text
Meet Tumble — a private film camera for iPhone.

Twelve shots a day. Shake to develop. Pick the film stock, then keep the print in a Drawer that feels more like a pile of memories than another camera-roll grid.

No account. No cloud. No feed. No subscription.

Tumble is out now on the App Store. Your first roll is waiting.

#shotontumble #iphonephotography #filmcamera #filmphotography #digitalcamera #photodump
```

## Rendering

From the repository root:

```sh
chmod +x marketing/instagram/intro-carousel/render.sh
./marketing/instagram/intro-carousel/render.sh
```

Final files are written to `marketing/instagram/intro-carousel/output/`.

## Asset provenance

- The navy archival-paper texture was generated with the built-in OpenAI image-generation tool for this carousel.
- Lifestyle photographs are campaign source images passed through Tumble's real film renderer; the selected graded outputs live under `marketing/ads/nostalgia-memory/graded/`.
- Brand colors, typography hierarchy, product claims, and logo come from the Tumble project.
