import React from 'react';
import {AbsoluteFill, random} from 'remotion';

/// Film grain — the primary background texture. Mirrors the fractal-noise SVG
/// the site paints in `body::after` and `TumbleKit/Theme/Grain.swift`
/// (tiled monochrome noise, overlay blend, opacity ~0.22).
export const Grain: React.FC<{
	opacity?: number;
	seed?: number;
}> = ({opacity = 0.22, seed = 0}) => {
	// Re-seeding per frame would strobe; a few stepped seeds keep it alive
	// without flicker, the way real film gate weave does.
	const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="180" height="180"><filter id="n"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" seed="${Math.floor(
		random(seed) * 100,
	)}"/><feColorMatrix type="saturate" values="0"/></filter><rect width="180" height="180" filter="url(#n)"/></svg>`;

	return (
		<AbsoluteFill
			style={{
				backgroundImage: `url("data:image/svg+xml;utf8,${encodeURIComponent(svg)}")`,
				backgroundRepeat: 'repeat',
				backgroundSize: '180px 180px',
				mixBlendMode: 'overlay',
				opacity,
				pointerEvents: 'none',
			}}
		/>
	);
};

/// Slate-blue graincore backdrop: deep base, a warm gold glow off one corner,
/// a vignette, and grain on top. Never blur — texture comes from grain.
export const Backdrop: React.FC<{
	children?: React.ReactNode;
	glowX?: number;
	glowY?: number;
	seed?: number;
}> = ({children, glowX = 78, glowY = 22, seed = 0}) => {
	return (
		<AbsoluteFill style={{backgroundColor: '#223140'}}>
			<AbsoluteFill
				style={{
					background: `radial-gradient(120% 90% at 50% 30%, #35506690 0%, #22314000 70%)`,
				}}
			/>
			<AbsoluteFill
				style={{
					background: `radial-gradient(45% 30% at ${glowX}% ${glowY}%, #DFAB6826 0%, #DFAB6800 70%)`,
				}}
			/>
			<AbsoluteFill
				style={{
					background: `linear-gradient(180deg, #1B2733 0%, #2E405200 22%, #2E405200 74%, #18222D 100%)`,
				}}
			/>
			<Grain seed={seed} />
			{children}
		</AbsoluteFill>
	);
};
