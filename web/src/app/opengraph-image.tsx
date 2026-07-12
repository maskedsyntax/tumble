import { ImageResponse } from "next/og";

// Branded link-sharing card (used by Open Graph + Twitter).
export const alt = "Tumble · A slower camera you can own";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "80px",
          color: "#f6efe2",
          backgroundColor: "#2e4052",
          backgroundImage:
            "linear-gradient(135deg, #2b3c4c 0%, #263646 46%, #21303f 100%)",
        }}
      >
        {/* warm amber glow, built from the brand gold */}
        <div
          style={{
            position: "absolute",
            top: "-160px",
            right: "-120px",
            width: "560px",
            height: "560px",
            borderRadius: "9999px",
            background:
              "radial-gradient(circle, rgba(223,171,104,0.42) 0%, rgba(223,171,104,0) 70%)",
          }}
        />

        {/* wordmark row */}
        <div style={{ display: "flex", alignItems: "center", gap: "24px" }}>
          <div
            style={{
              display: "flex",
              width: "76px",
              height: "76px",
              borderRadius: "18px",
              background: "linear-gradient(180deg, #2e4052 0%, #dfab68 100%)",
              alignItems: "center",
              justifyContent: "center",
              transform: "rotate(-10deg)",
            }}
          >
            <div
              style={{
                display: "flex",
                width: "40px",
                height: "46px",
                borderRadius: "6px",
                background: "#f6efe2",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <div
                style={{
                  width: "26px",
                  height: "22px",
                  borderRadius: "4px",
                  background: "#dfab68",
                }}
              />
            </div>
          </div>
          <div
            style={{
              fontSize: "40px",
              fontWeight: 600,
              letterSpacing: "0.24em",
              textTransform: "uppercase",
              color: "rgba(246,239,226,0.85)",
            }}
          >
            Tumble
          </div>
        </div>

        {/* headline */}
        <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              fontSize: "86px",
              fontWeight: 700,
              lineHeight: 1.05,
              letterSpacing: "-0.02em",
              maxWidth: "900px",
            }}
          >
            <div style={{ display: "flex" }}>A slower camera</div>
            <div style={{ display: "flex", color: "#dfab68" }}>you can own.</div>
          </div>
          <div
            style={{
              fontSize: "34px",
              lineHeight: 1.35,
              color: "rgba(246,239,226,0.8)",
              maxWidth: "860px",
            }}
          >
            Pull it down, shoot a daily roll, then shake to develop.
          </div>
        </div>

        {/* footer badge */}
        <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
          <div
            style={{
              width: "12px",
              height: "12px",
              borderRadius: "9999px",
              background: "#dfab68",
            }}
          />
          <div
            style={{
              fontSize: "28px",
              letterSpacing: "0.08em",
              color: "rgba(246,239,226,0.85)",
            }}
          >
            iPhone · App Store soon · gettumbleapp.com
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}
