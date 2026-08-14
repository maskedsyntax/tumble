import React from 'react';
import {spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {Body, Closer, Headline, Kicker} from '../components/Type';
import {
	ClassicFrame,
	DeckledFrame,
	FilmFrame,
	VintageFrame,
} from '../components/Frames';
import {palette, sans} from '../theme';

const W = 340;

const FRAMES = [
	{
		label: 'Classic',
		node: (
			<ClassicFrame src="photos/img1.JPG" width={W} note="keep this one." />
		),
	},
	{
		label: 'Vintage',
		node: (
			<VintageFrame src="photos/img4.jpeg" width={W} note="Wish you were here." />
		),
	},
	{
		label: 'Film',
		node: <FilmFrame src="photos/img5.JPG" width={W} note="after the rain" />,
	},
	{
		label: 'Deckled',
		node: (
			<DeckledFrame src="photos/img6.JPG" width={W} note="a quiet afternoon" />
		),
	},
];

/// Scene 6 — the keepsake. A print you can frame, sign and hand to someone is
/// the reason to keep shooting, so the four finishes get shown as objects.
export const FramesScene: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	return (
		<Scene glowX={72} glowY={68} seed={23}>
			<Kicker>Postcard Frames</Kicker>
			<div style={{height: 22}} />
			<Headline delay={4} size={92} maxWidth={904}>
				Frame it. Sign it. Send it.
			</Headline>
			<div style={{height: 30}} />
			<Body delay={18} maxWidth={820}>
				Add a note, pick a finish, and the moment saves as a postcard.
			</Body>

			<div
				style={{
					position: 'absolute',
					inset: 0,
					marginTop: 620,
					marginBottom: 190,
					display: 'grid',
					gridTemplateColumns: '1fr 1fr',
					justifyItems: 'center',
					alignContent: 'center',
					rowGap: 44,
					padding: '0 70px',
				}}
			>
				{FRAMES.map((f, i) => {
					const p = spring({
						frame: frame - 22 - i * 9,
						fps,
						config: {damping: 200, mass: 0.85},
						durationInFrames: 34,
					});
					const tilt = [-3, 2.5, -2, 3][i];
					return (
						<div
							key={f.label}
							style={{
								opacity: p,
								transform: `translateY(${(1 - p) * 70}px) rotate(${tilt * p}deg)`,
								display: 'flex',
								flexDirection: 'column',
								alignItems: 'center',
								gap: 20,
							}}
						>
							{f.node}
							<div
								style={{
									fontFamily: sans,
									fontWeight: 600,
									fontSize: 22,
									letterSpacing: 2.4,
									textTransform: 'uppercase',
									color: palette.amber,
								}}
							>
								{f.label}
							</div>
						</div>
					);
				})}
			</div>

			<div style={{position: 'absolute', left: 88, right: 88, bottom: 110}}>
				<Closer delay={92}>Every frame is previewed before it is saved.</Closer>
			</div>
		</Scene>
	);
};
