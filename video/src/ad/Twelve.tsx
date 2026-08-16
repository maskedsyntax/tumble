import React from 'react';
import {AbsoluteFill, interpolate, random, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Backdrop} from '../components/Grain';
import {Print} from '../components/Print';
import {display, palette, sans} from '../theme';

/// The offer, stated as a question the viewer answers for themselves: what if
/// there were only twelve? The roll counts down, then one of them develops in
/// your hand.
export const Twelve: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const question = spring({frame: frame - 2, fps, config: {damping: 200}});

	// Twelve slots, filling one by one - the constraint made visible before it
	// is explained.
	const filled = Math.min(12, Math.max(0, Math.floor((frame - 20) / 3)));

	const shakeFrom = 74;
	const shakeTo = 150;
	const intensity = interpolate(
		frame,
		[shakeFrom, shakeFrom + 10, shakeTo - 18, shakeTo],
		[0, 1, 1, 0],
		{extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
	);
	const wobble = Math.sin(frame * 0.95) * 24 * intensity;
	const wobbleY = Math.sin(frame * 1.4 + 1) * 11 * intensity;
	const tilt = Math.sin(frame * 0.75) * 3.8 * intensity;
	const jitter = (random(`ad-shake-${frame}`) - 0.5) * 5 * intensity;

	const develop = interpolate(frame, [shakeFrom + 8, shakeTo], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});

	const payoff = interpolate(frame, [shakeTo - 6, shakeTo + 12], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});

	return (
		<Backdrop glowX={0.5} glowY={0.36} seed={9}>
			<AbsoluteFill style={{padding: '150px 96px 150px'}}>
				<div
					style={{
						opacity: question,
						fontFamily: display,
						fontWeight: 600,
						fontSize: 92,
						lineHeight: 1.06,
						letterSpacing: -1.8,
						color: palette.cream,
					}}
				>
					What if you only
					<br />
					got twelve a day?
				</div>

				<div style={{display: 'flex', gap: 10, marginTop: 38}}>
					{Array.from({length: 12}).map((_, i) => (
						<div
							key={i}
							style={{
								flex: 1,
								height: 14,
								borderRadius: 7,
								backgroundColor: i < filled ? palette.amber : 'rgba(246,239,226,0.15)',
							}}
						/>
					))}
				</div>

				<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', top: 150}}>
					<div
						style={{
							transform: `translate(${wobble + jitter}px, ${wobbleY}px) rotate(${tilt}deg)`,
						}}
					>
						<Print
							src={staticFile('looks/hero-fadedInstant.jpg')}
							width={600}
							develop={develop}
							caption={develop > 0.92 ? 'the evening it went gold' : undefined}
						/>
					</div>
				</AbsoluteFill>

				<div
					style={{
						position: 'absolute',
						left: 96,
						right: 96,
						bottom: 150,
						textAlign: 'center',
						opacity: payoff,
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 36,
						color: palette.amber,
					}}
				>
					You would remember every one of them.
				</div>
			</AbsoluteFill>
		</Backdrop>
	);
};
