import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import {Backdrop} from './Grain';

/// Every scene sits on the graincore backdrop and cross-dissolves at its
/// edges, so the film never hard-cuts — the app has no hard cuts either.
export const Scene: React.FC<{
	children: React.ReactNode;
	glowX?: number;
	glowY?: number;
	seed?: number;
	fadeIn?: number;
	fadeOut?: number;
}> = ({children, glowX, glowY, seed = 0, fadeIn = 12, fadeOut = 12}) => {
	const frame = useCurrentFrame();
	const {durationInFrames} = useVideoConfig();

	const opacity = Math.min(
		fadeIn === 0
			? 1
			: interpolate(frame, [0, fadeIn], [0, 1], {extrapolateRight: 'clamp'}),
		interpolate(frame, [durationInFrames - fadeOut, durationInFrames], [1, 0], {
			extrapolateLeft: 'clamp',
		}),
	);

	return (
		<AbsoluteFill style={{opacity}}>
			<Backdrop glowX={glowX} glowY={glowY} seed={seed}>
				<AbsoluteFill style={{padding: '150px 88px 120px'}}>{children}</AbsoluteFill>
			</Backdrop>
		</AbsoluteFill>
	);
};
