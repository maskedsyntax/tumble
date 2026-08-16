import React from 'react';
import {AbsoluteFill, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {Headline, Kicker} from '../components/Type';
import {Print} from '../components/Print';
import {sans} from '../theme';

/// Prints tossed onto a pile, not laid out in a grid. They arrive from off the
/// bottom of the frame the way they land in the app - the Drawer is a heap.
const PILE = [
	{file: 'snow.jpg', x: -230, y: -170, rot: -11, w: 330, delay: 0, age: 0.6},
	{file: 'foam.jpg', x: 210, y: -210, rot: 8, w: 350, delay: 5, age: 0.45},
	{file: 'road.jpg', x: -40, y: 30, rot: 3, w: 400, delay: 10, age: 0.3},
	{file: 'cliff.jpg', x: -250, y: 250, rot: 7, w: 340, delay: 15, age: 0.2},
	{file: 'lake.jpg', x: 235, y: 245, rot: -8, w: 355, delay: 20, age: 0.12},
	{file: 'steps.jpg', x: 20, y: 430, rot: 12, w: 320, delay: 25, age: 0},
];

export const Drawer: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	return (
		<Scene glowX={0.5} glowY={0.5} seed={13}>
			<div style={{display: 'flex', flexDirection: 'column', height: '100%'}}>
				<Kicker delay={2}>YOUR DRAWER</Kicker>
				<div style={{height: 18}} />
				<Headline delay={4} size={100}>
					{'A pile of prints.'}
				</Headline>

				<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', top: 170}}>
					{PILE.map((p) => {
						const toss = spring({
							frame: frame - 8 - p.delay,
							fps,
							config: {damping: 15, mass: 0.9},
						});
						return (
							<div
								key={p.file}
								style={{
									position: 'absolute',
									transform: `translate(${p.x}px, ${interpolate(toss, [0, 1], [700, p.y])}px) rotate(${interpolate(toss, [0, 1], [p.rot - 18, p.rot])}deg)`,
									opacity: Math.min(1, toss * 2.4),
								}}
							>
								<Print src={staticFile(`looks/${p.file}`)} width={p.w} age={p.age} shadow={0.45} />
							</div>
						);
					})}
				</AbsoluteFill>

				<div
					style={{
						position: 'absolute',
						left: 0,
						right: 0,
						bottom: 0,
						textAlign: 'center',
						opacity: interpolate(frame, [64, 80], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}),
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 27,
						color: 'rgba(246,239,226,0.68)',
					}}
				>
					They age as they sit — grain, vignette, a little patina.
				</div>
			</div>
		</Scene>
	);
};
