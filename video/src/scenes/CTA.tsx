import React from 'react';
import {Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {display, palette, sans, script} from '../theme';

// Straight from `TumbleKit/Model/Entitlement.swift` — one-time prices, no tiers
// invented for the film.
const PLANS = [
	{size: '12', name: 'Free', price: 'Free', note: 'shots a day'},
	{size: '72', name: 'Plus', price: '$5.99 once', note: 'shots a day'},
	{size: '∞', name: 'Unlimited', price: '$11.99 once', note: 'no daily limit'},
];

/// Scene 8 — the ask. Price objection cleared first (free to use, one-time if
/// you want more), then a single instruction.
export const CTA: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const logo = spring({
		frame: frame - 4,
		fps,
		config: {damping: 200, mass: 0.8},
		durationInFrames: 30,
	});

	const wordmark = spring({
		frame: frame - 14,
		fps,
		config: {damping: 200, mass: 0.8},
		durationInFrames: 30,
	});

	return (
		<Scene glowX={50} glowY={40} seed={31} fadeOut={26}>
			<div
				style={{
					position: 'absolute',
					inset: 0,
					display: 'flex',
					flexDirection: 'column',
					alignItems: 'center',
					justifyContent: 'center',
					padding: '0 80px',
				}}
			>
				<Img
					src={staticFile('logo.png')}
					style={{
						width: 190,
						height: 190,
						borderRadius: 44,
						opacity: logo,
						transform: `scale(${0.86 + logo * 0.14})`,
						boxShadow: '0 24px 60px rgba(0,0,0,0.42)',
					}}
				/>

				<div
					style={{
						fontFamily: display,
						fontWeight: 600,
						fontSize: 118,
						letterSpacing: -2,
						color: palette.cream,
						marginTop: 44,
						opacity: wordmark,
						transform: `translateY(${(1 - wordmark) * 18}px)`,
					}}
				>
					Tumble
				</div>

				<div
					style={{
						fontFamily: sans,
						fontSize: 38,
						color: 'rgba(246,239,226,0.72)',
						marginTop: 14,
						opacity: interpolate(frame, [24, 42], [0, 1], {
							extrapolateLeft: 'clamp',
							extrapolateRight: 'clamp',
						}),
					}}
				>
					A slower camera you can own.
				</div>

				<div style={{display: 'flex', gap: 26, marginTop: 78}}>
					{PLANS.map((plan, i) => {
						const p = spring({
							frame: frame - 44 - i * 8,
							fps,
							config: {damping: 200, mass: 0.8},
							durationInFrames: 30,
						});
						const featured = i === 0;
						return (
							<div
								key={plan.name}
								style={{
									width: 268,
									padding: '34px 24px 30px',
									borderRadius: 30,
									textAlign: 'center',
									backgroundColor: featured
										? 'rgba(223,171,104,0.14)'
										: 'rgba(32,45,57,0.5)',
									border: `1px solid ${
										featured ? 'rgba(223,171,104,0.5)' : 'rgba(246,239,226,0.1)'
									}`,
									opacity: p,
									transform: `translateY(${(1 - p) * 34}px)`,
								}}
							>
								<div
									style={{
										fontFamily: display,
										fontWeight: 600,
										fontSize: 66,
										lineHeight: 1,
										color: featured ? palette.amber : palette.cream,
									}}
								>
									{plan.size}
								</div>
								<div
									style={{
										fontFamily: sans,
										fontSize: 22,
										color: 'rgba(246,239,226,0.55)',
										marginTop: 10,
									}}
								>
									{plan.note}
								</div>
								<div
									style={{
										fontFamily: sans,
										fontWeight: 600,
										fontSize: 28,
										color: palette.cream,
										marginTop: 20,
									}}
								>
									{plan.price}
								</div>
							</div>
						);
					})}
				</div>

				<div
					style={{
						fontFamily: sans,
						fontSize: 27,
						letterSpacing: 1,
						color: 'rgba(246,239,226,0.5)',
						marginTop: 30,
						opacity: interpolate(frame, [76, 94], [0, 1], {
							extrapolateLeft: 'clamp',
							extrapolateRight: 'clamp',
						}),
					}}
				>
					One-time unlocks. No subscription.
				</div>

				<StoreLine frame={frame} />

				<div
					style={{
						fontFamily: script,
						fontSize: 58,
						color: palette.creamDim,
						marginTop: 46,
						opacity: interpolate(frame, [124, 146], [0, 0.92], {
							extrapolateLeft: 'clamp',
							extrapolateRight: 'clamp',
						}),
					}}
				>
					Wait for it.
				</div>
			</div>
		</Scene>
	);
};

const StoreLine: React.FC<{frame: number}> = ({frame}) => {
	const {fps} = useVideoConfig();
	const p = spring({
		frame: frame - 92,
		fps,
		config: {damping: 200, mass: 0.8},
		durationInFrames: 28,
	});
	// A gentle pulse: the last thing moving on screen is the thing to tap.
	const pulse = 1 + Math.sin(Math.max(0, frame - 120) / 9) * 0.012;

	return (
		<div
			style={{
				marginTop: 56,
				padding: '28px 66px',
				borderRadius: 999,
				backgroundColor: palette.amber,
				fontFamily: sans,
				fontWeight: 700,
				fontSize: 34,
				letterSpacing: 0.6,
				color: palette.blueDeep,
				boxShadow: '0 20px 50px rgba(0,0,0,0.38)',
				opacity: p,
				transform: `translateY(${(1 - p) * 26}px) scale(${p * pulse})`,
			}}
		>
			Tumble — Instant Camera, on the App Store
		</div>
	);
};
