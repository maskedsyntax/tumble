import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {Body, Closer, Headline, Kicker} from '../components/Type';
import {palette, sans} from '../theme';

// Each of these is a real property of the shipped app, not a positioning line.
const ABSENT = ['No account', 'No photo cloud', 'No feed', 'No ads', 'No ad tracking'];

/// Scene 7 — the objection handler. Every camera app asks for something; this
/// one is a list of things it never asks for, struck through one by one.
export const Private: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	return (
		<Scene glowX={50} glowY={16} seed={29}>
			<Kicker>Private by Design</Kicker>
			<div style={{height: 22}} />
			<Headline delay={4} size={100} maxWidth={900}>
				Nothing leaves your phone.
			</Headline>
			<div style={{height: 34}} />
			<Body delay={18} maxWidth={820}>
				Photos are stored on device. There is no sign-in, and nothing to sync.
			</Body>

			<div
				style={{
					position: 'absolute',
					inset: 0,
					display: 'flex',
					flexDirection: 'column',
					alignItems: 'center',
					justifyContent: 'center',
					gap: 26,
					marginTop: 70,
				}}
			>
				{ABSENT.map((label, i) => {
					const p = spring({
						frame: frame - 26 - i * 11,
						fps,
						config: {damping: 200, mass: 0.7},
						durationInFrames: 26,
					});
					const strike = interpolate(frame - 34 - i * 11, [0, 14], [0, 1], {
						extrapolateLeft: 'clamp',
						extrapolateRight: 'clamp',
					});
					return (
						<div
							key={label}
							style={{
								position: 'relative',
								opacity: p,
								transform: `translateY(${(1 - p) * 22}px)`,
								fontFamily: sans,
								fontWeight: 500,
								fontSize: 62,
								color: palette.cream,
								padding: '0 12px',
							}}
						>
							{label}
							<div
								style={{
									position: 'absolute',
									left: 0,
									right: 0,
									top: '54%',
									height: 5,
									borderRadius: 3,
									backgroundColor: palette.amber,
									transform: `scaleX(${strike})`,
									transformOrigin: 'left center',
								}}
							/>
						</div>
					);
				})}
			</div>

			<div style={{position: 'absolute', left: 88, right: 88, bottom: 120}}>
				<Closer delay={96}>A camera, and nothing else attached to it.</Closer>
			</div>
		</Scene>
	);
};
