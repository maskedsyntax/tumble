import React from 'react';
import {AbsoluteFill, interpolate, random, staticFile, useCurrentFrame} from 'remotion';
import {Scene} from '../components/Scene';
import {Headline, Kicker} from '../components/Type';
import {Print} from '../components/Print';
import {palette, sans} from '../theme';

/// The ritual nobody else has. The print starts blank, the phone shakes, and
/// the image rises - shown at the real pace, because the whole pitch is that
/// you have to wait for it.
const SHAKE_FROM = 26;
const SHAKE_TO = 118;

export const Develop: React.FC = () => {
	const frame = useCurrentFrame();

	const shaking = frame >= SHAKE_FROM && frame <= SHAKE_TO;
	const intensity = interpolate(
		frame,
		[SHAKE_FROM, SHAKE_FROM + 12, SHAKE_TO - 24, SHAKE_TO],
		[0, 1, 1, 0],
		{extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
	);

	// Hand-held wobble: two out-of-phase sines plus a little jitter, so it
	// never reads as a clean loop.
	const wobble = Math.sin(frame * 0.9) * 26 * intensity;
	const wobbleY = Math.sin(frame * 1.37 + 1.2) * 12 * intensity;
	const tilt = Math.sin(frame * 0.72 + 0.4) * 4.2 * intensity;
	const jitter = (random(`shake-${frame}`) - 0.5) * 6 * intensity;

	const develop = interpolate(frame, [SHAKE_FROM + 10, SHAKE_TO], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});

	const hint = interpolate(frame, [SHAKE_TO + 6, SHAKE_TO + 20], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});

	return (
		<Scene glowX={0.5} glowY={0.42} seed={11}>
			<div style={{display: 'flex', flexDirection: 'column', height: '100%'}}>
				<Kicker delay={2}>THE PART YOU WAIT FOR</Kicker>
				<div style={{height: 18}} />
				<Headline delay={4} size={104}>
					{'Shake it.\nWatch it come up.'}
				</Headline>

				<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', top: 120}}>
					<div
						style={{
							transform: `translate(${wobble + jitter}px, ${wobbleY}px) rotate(${tilt}deg)`,
						}}
					>
						<Print
							src={staticFile('looks/hero-fadedInstant.jpg')}
							width={620}
							develop={develop}
							caption={develop > 0.9 ? 'first light' : undefined}
							shadow={0.5}
						/>
					</div>

					{/* Motion lines, drawn only while it is actually moving. */}
					{shaking ? (
						<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
							{[-1, 1].map((side) => (
								<div
									key={side}
									style={{
										position: 'absolute',
										left: `calc(50% + ${side * 380}px)`,
										width: 90,
										height: 5,
										borderRadius: 4,
										background: `linear-gradient(${side > 0 ? 90 : 270}deg, ${palette.amber}, rgba(223,171,104,0))`,
										opacity: 0.5 * intensity,
										transform: `translateX(${-wobble * 0.4}px)`,
									}}
								/>
							))}
						</AbsoluteFill>
					) : null}
				</AbsoluteFill>

				<div
					style={{
						position: 'absolute',
						left: 0,
						right: 0,
						bottom: 90,
						textAlign: 'center',
						opacity: hint,
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 27,
						letterSpacing: 0.6,
						color: 'rgba(246,239,226,0.66)',
					}}
				>
					Reduce Motion on? Press and hold instead.
				</div>
			</div>
		</Scene>
	);
};
