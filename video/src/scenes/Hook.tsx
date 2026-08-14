import React from 'react';
import {
	interpolate,
	spring,
	staticFile,
	useCurrentFrame,
	useVideoConfig,
} from 'remotion';
import {Scene} from '../components/Scene';
import {Print} from '../components/Print';
import {Headline, Kicker} from '../components/Type';
import {script, palette} from '../theme';

/// Scene 1 — the pattern interrupt. A blank, undeveloped print falls onto the
/// frame and just sits there. Nothing resolves. The unanswered question is the
/// hook, and the headline names the promise straight away.
export const Hook: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const drop = spring({
		frame: frame - 2,
		fps,
		config: {damping: 14, mass: 1.1, stiffness: 90},
		durationInFrames: 50,
	});

	// It lands, then breathes — the same idle drift the Drawer prints have.
	const settle = Math.sin((frame - 30) / 26) * (frame > 30 ? 0.7 : 0);

	// No fade-in, and the type carries negative delays: frame 0 is the cover
	// frame on every social platform, so it has to already say what this is.
	return (
		<Scene glowX={70} glowY={26} fadeIn={0}>
			<Kicker delay={-20}>Tumble · Slow Camera</Kicker>
			<div style={{height: 26}} />
			<Headline delay={-34} size={104} maxWidth={860}>
				A camera that makes you wait.
			</Headline>

			<div
				style={{
					position: 'absolute',
					inset: 0,
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					marginTop: 180,
				}}
			>
				<div
					style={{
						transform: `translateY(${(1 - drop) * -1500}px) rotate(${
							-4 + (1 - drop) * -9 + settle
						}deg)`,
					}}
				>
					<Print width={520} develop={0} shadow={0.55} />
				</div>
			</div>

			<div
				style={{
					position: 'absolute',
					left: 0,
					right: 0,
					bottom: 190,
					textAlign: 'center',
					fontFamily: script,
					fontSize: 52,
					color: palette.creamDim,
					opacity: interpolate(frame, [58, 76], [0, 0.9], {
						extrapolateLeft: 'clamp',
						extrapolateRight: 'clamp',
					}),
				}}
			>
				wait for it
			</div>
		</Scene>
	);
};

export const heroPhoto = staticFile('photos/img1.JPG');
