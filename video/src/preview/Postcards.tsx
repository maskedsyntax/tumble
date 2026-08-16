import React from 'react';
import {AbsoluteFill, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {Headline, Kicker} from '../components/Type';
import {ClassicFrame, DeckledFrame, FilmFrame, VintageFrame} from '../components/Frames';
import {palette, sans} from '../theme';

/// The keepsake beat: the same print mounted four ways, each snapping in like
/// it was dealt onto the table. Frame names match the app's picker exactly.
const FRAMES = [
	{name: 'Classic', Comp: ClassicFrame},
	{name: 'Vintage', Comp: VintageFrame},
	{name: 'Film', Comp: FilmFrame},
	{name: 'Deckled', Comp: DeckledFrame},
];

const HOLD = 30;

export const Postcards: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const index = Math.min(Math.floor(frame / HOLD), FRAMES.length - 1);
	const {name, Comp} = FRAMES[index];

	// Each swap lands with a spring, so the change is felt rather than cut.
	const deal = spring({frame: frame - index * HOLD, fps, config: {damping: 13, mass: 0.7}});

	return (
		<Scene glowX={0.42} glowY={0.4} seed={5}>
			<div style={{display: 'flex', flexDirection: 'column', height: '100%'}}>
				<Kicker delay={2}>POSTCARD FRAMES</Kicker>
				<div style={{height: 18}} />
				<Headline delay={4} size={100}>
					{'Made to be sent.'}
				</Headline>

				<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', top: 90}}>
					<div
						key={name}
						style={{
							transform: `scale(${0.9 + deal * 0.1}) rotate(${(1 - deal) * -4}deg)`,
							opacity: deal,
						}}
					>
						{/* The frame components resolve their own static paths. */}
						<Comp
							src="looks/trail.jpg"
							width={640}
							note="the long way home"
						/>
					</div>
				</AbsoluteFill>

				{/* The picker, ticking along with the frame on screen. */}
				<div
					style={{
						position: 'absolute',
						left: 0,
						right: 0,
						bottom: 0,
						display: 'flex',
						justifyContent: 'center',
						gap: 14,
					}}
				>
					{FRAMES.map((f, i) => (
						<div
							key={f.name}
							style={{
								fontFamily: sans,
								fontWeight: 700,
								fontSize: 25,
								letterSpacing: 0.8,
								padding: '13px 26px',
								borderRadius: 999,
								color: i === index ? palette.ink : 'rgba(246,239,226,0.7)',
								backgroundColor: i === index ? palette.amber : 'rgba(246,239,226,0.09)',
							}}
						>
							{f.name}
						</div>
					))}
				</div>
			</div>
		</Scene>
	);
};
