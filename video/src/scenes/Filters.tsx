import React from 'react';
import {spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {Print} from '../components/Print';
import {Body, Closer, Headline, Kicker} from '../components/Type';
import {palette, sans} from '../theme';

// The real filter outputs from `test-output/`, not a CSS approximation of them.
const LOOKS = [
	{label: 'Original', src: 'photos/img1.JPG'},
	{label: 'Faded Instant', src: 'filters/img1-faded-instant.jpg'},
	{label: 'Warm Archive', src: 'filters/img1-warm-archive.jpg'},
];

/// Scene 5 — memory filters. Same frame, three moods, shown side by side so
/// the difference is the argument.
export const Filters: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	return (
		<Scene glowX={20} glowY={70} seed={17}>
			<Kicker>Memory Filters</Kicker>
			<div style={{height: 22}} />
			<Headline delay={4} size={98} maxWidth={900}>
				Three ways to remember it.
			</Headline>
			<div style={{height: 34}} />
			<Body delay={18} maxWidth={820}>
				Original, Faded Instant, Warm Archive — applied to the print, then saved
				as a photo or a framed postcard.
			</Body>

			<div
				style={{
					position: 'absolute',
					inset: 0,
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					gap: 34,
					marginTop: 120,
				}}
			>
				{LOOKS.map((look, i) => {
					const p = spring({
						frame: frame - 24 - i * 10,
						fps,
						config: {damping: 200, mass: 0.8},
						durationInFrames: 32,
					});
					return (
						<div
							key={look.label}
							style={{
								opacity: p,
								transform: `translateY(${(1 - p) * 60}px)`,
								display: 'flex',
								flexDirection: 'column',
								alignItems: 'center',
								gap: 22,
							}}
						>
							<Print
								width={296}
								src={staticFile(look.src)}
								rotation={(i - 1) * 3}
								shadow={0.4}
							/>
							<div
								style={{
									fontFamily: sans,
									fontWeight: 600,
									fontSize: 22,
									letterSpacing: 2,
									textTransform: 'uppercase',
									color: i === 0 ? 'rgba(246,239,226,0.55)' : palette.amber,
								}}
							>
								{look.label}
							</div>
						</div>
					);
				})}
			</div>

			<div style={{position: 'absolute', left: 88, right: 88, bottom: 150}}>
				<Closer delay={72}>The same shot, remembered three ways.</Closer>
			</div>
		</Scene>
	);
};
