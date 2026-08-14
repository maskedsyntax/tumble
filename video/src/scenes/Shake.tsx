import React from 'react';
import {interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Scene} from '../components/Scene';
import {Print} from '../components/Print';
import {Body, Headline, Kicker} from '../components/Type';
import {palette, sans} from '../theme';

/// Scene 3 — the moment the whole app is built around, and the one that earns
/// the download. The print is shaken and the image climbs out of the wash in
/// real time, using the exact develop grading the app applies.
export const Shake: React.FC = () => {
	const frame = useCurrentFrame();

	// Two bursts of shaking with a pause between them: the pause is where the
	// "stop halfway, it remembers" promise gets demonstrated rather than said.
	const burstA = frame >= 24 && frame < 78;
	const burstB = frame >= 108 && frame < 168;
	const shaking = burstA || burstB;

	const develop = interpolate(
		frame,
		[24, 78, 108, 168],
		[0.02, 0.42, 0.42, 1],
		{extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
	);

	const wobble = shaking ? Math.sin(frame * 1.55) : 0;
	const wobbleY = shaking ? Math.sin(frame * 2.3) : 0;

	return (
		<Scene glowX={26} glowY={30} seed={7}>
			<Kicker>Shake to Develop</Kicker>
			<div style={{height: 22}} />
			<Headline delay={4} size={100} maxWidth={900}>
				Then you shake it.
			</Headline>
			<div style={{height: 34}} />
			<Body delay={18} maxWidth={820}>
				The image climbs out of the wash as you go. Stop halfway and it holds your
				progress until you come back.
			</Body>

			<div
				style={{
					position: 'absolute',
					inset: 0,
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					marginTop: 130,
				}}
			>
				<MotionMarks visible={shaking} />
				<div
					style={{
						transform: `translate(${wobble * 26}px, ${wobbleY * 9}px) rotate(${
							wobble * 2.6 - 2
						}deg)`,
					}}
				>
					<Print
						width={600}
						src={staticFile('photos/img1.JPG')}
						develop={develop}
						caption="coming into focus"
					/>
				</div>
			</div>

			<div
				style={{
					position: 'absolute',
					left: 88,
					right: 88,
					bottom: 210,
					display: 'flex',
					justifyContent: 'center',
				}}
			>
				<ProgressPill develop={develop} paused={!shaking && frame > 78} />
			</div>

			<div
				style={{
					position: 'absolute',
					left: 88,
					right: 88,
					bottom: 130,
					textAlign: 'center',
					fontFamily: sans,
					fontSize: 27,
					color: 'rgba(246,239,226,0.5)',
					opacity: interpolate(frame, [150, 168], [0, 1], {
						extrapolateLeft: 'clamp',
						extrapolateRight: 'clamp',
					}),
				}}
			>
				Reduce Motion on? Press and hold instead.
			</div>
		</Scene>
	);
};

/// The amber motion ticks either side of the print, as drawn in the App Store
/// screenshot set.
const MotionMarks: React.FC<{visible: boolean}> = ({visible}) => {
	const frame = useCurrentFrame();
	const o = visible ? 0.55 + Math.abs(Math.sin(frame * 0.9)) * 0.45 : 0;
	const mark = (rot: number, x: number, y: number) => (
		<div
			key={`${x}-${y}`}
			style={{
				position: 'absolute',
				left: x,
				top: y,
				width: 96,
				height: 9,
				borderRadius: 6,
				backgroundColor: palette.amber,
				transform: `rotate(${rot}deg)`,
			}}
		/>
	);
	return (
		<div
			style={{
				position: 'absolute',
				inset: 0,
				opacity: o,
				transition: 'opacity 0.1s',
			}}
		>
			{mark(-28, 80, 780)}
			{mark(-8, 66, 900)}
			{mark(16, 80, 1020)}
			{mark(28, 906, 780)}
			{mark(8, 920, 900)}
			{mark(-16, 906, 1020)}
		</div>
	);
};

const ProgressPill: React.FC<{develop: number; paused: boolean}> = ({
	develop,
	paused,
}) => {
	const pct = Math.round(develop * 100);
	const done = pct >= 99;
	return (
		<div
			style={{
				padding: '22px 54px',
				borderRadius: 999,
				backgroundColor: palette.amber,
				fontFamily: sans,
				fontWeight: 700,
				fontSize: 30,
				letterSpacing: 1.6,
				color: palette.blueDeep,
				boxShadow: '0 16px 40px rgba(0,0,0,0.3)',
			}}
		>
			{done
				? 'DEVELOPED'
				: paused
				? `${pct}% DEVELOPED · PROGRESS SAVED`
				: `${pct}% DEVELOPED`}
		</div>
	);
};
