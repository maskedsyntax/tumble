import React from 'react';
import {AbsoluteFill, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Backdrop} from '../components/Grain';
import {Print} from '../components/Print';
import {ClassicFrame} from '../components/Frames';
import {display, palette, sans} from '../theme';

/// What you gain, made physical: prints that pile up, age, and carry your
/// handwriting. The camera drifts across the pile rather than cutting between
/// pictures of it.
const PILE = [
	{file: 'snow.jpg', x: -300, y: -120, rot: -13, w: 320, delay: 0, age: 0.75},
	{file: 'foam.jpg', x: 250, y: -240, rot: 9, w: 340, delay: 4, age: 0.6},
	{file: 'cliff.jpg', x: -260, y: 240, rot: 6, w: 330, delay: 8, age: 0.4},
	{file: 'lake.jpg', x: 285, y: 210, rot: -9, w: 335, delay: 12, age: 0.25},
	{file: 'road.jpg', x: -20, y: 400, rot: 4, w: 330, delay: 16, age: 0.1},
];

export const Keepsake: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	// One slow drift for the whole scene: the camera moving, not the pictures.
	const drift = interpolate(frame, [0, 150], [0, -70]);
	const push = interpolate(frame, [0, 150], [1.0, 1.09]);

	const centre = spring({frame: frame - 26, fps, config: {damping: 16, mass: 1}});
	const line = interpolate(frame, [96, 116], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

	return (
		<Backdrop glowX={0.46} glowY={0.5} seed={15}>
			<AbsoluteFill style={{padding: '150px 96px'}}>
				<div
					style={{
						fontFamily: display,
						fontWeight: 600,
						fontSize: 88,
						lineHeight: 1.06,
						letterSpacing: -1.6,
						color: palette.cream,
						opacity: spring({frame, fps, config: {damping: 200}}),
					}}
				>
					A drawer you will
					<br />
					open in ten years.
				</div>

				<AbsoluteFill
					style={{
						alignItems: 'center',
						justifyContent: 'center',
						top: 130,
						transform: `translateY(${drift}px) scale(${push})`,
					}}
				>
					{PILE.map((p) => {
						const toss = spring({frame: frame - 4 - p.delay, fps, config: {damping: 15, mass: 0.9}});
						return (
							<div
								key={p.file}
								style={{
									position: 'absolute',
									transform: `translate(${p.x}px, ${interpolate(toss, [0, 1], [640, p.y])}px) rotate(${interpolate(toss, [0, 1], [p.rot - 14, p.rot])}deg)`,
									opacity: Math.min(1, toss * 2.2),
								}}
							>
								<Print src={staticFile(`looks/${p.file}`)} width={p.w} age={p.age} shadow={0.45} />
							</div>
						);
					})}

					{/* The one with handwriting on it, landing last and on top. */}
					<div
						style={{
							position: 'absolute',
							transform: `translateY(${interpolate(centre, [0, 1], [520, 40])}px) rotate(${interpolate(centre, [0, 1], [8, -2])}deg) scale(${interpolate(centre, [0, 1], [0.9, 1])})`,
							opacity: Math.min(1, centre * 2),
						}}
					>
						<ClassicFrame src="looks/trail.jpg" width={470} note="the long way home" />
					</div>
				</AbsoluteFill>

				<div
					style={{
						position: 'absolute',
						left: 96,
						right: 96,
						bottom: 150,
						textAlign: 'center',
						opacity: line,
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 34,
						color: 'rgba(246,239,226,0.78)',
					}}
				>
					Twenty-one film looks. Your handwriting. On your phone, nowhere else.
				</div>
			</AbsoluteFill>
		</Backdrop>
	);
};
