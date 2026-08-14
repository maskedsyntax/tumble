import React from 'react';
import {random, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {Print} from '../components/Print';
import {Body, Closer, Headline, Kicker} from '../components/Type';

const PHOTOS = [
	'archive/01-autumn-trail.jpg',
	'archive/10-himalayan-road.jpg',
	'archive/05-coastal-cliff.jpg',
	'archive/03-vintage-bicycle.jpg',
	'archive/04-city-sunset.jpg',
	'archive/02-forest-path.jpg',
	'archive/07-coffee-books.jpg',
	'archive/09-misty-steps.jpg',
	'archive/11-mountain-road.jpg',
];

/// Scene 4 — the Drawer: one print in the middle with the rest scattered
/// around it, never a grid, exactly how `DrawerPile` arranges them. Older
/// prints carry more age, so the pile visibly has a past.
export const Drawer: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	return (
		<Scene glowX={50} glowY={78} seed={11}>
			<Kicker>The Drawer</Kicker>
			<div style={{height: 22}} />
			<Headline delay={4} size={100} maxWidth={900}>
				A pile, not a grid.
			</Headline>
			<div style={{height: 34}} />
			<Body delay={18} maxWidth={820}>
				Your home screen is a scatter of prints. They age where they lie — grain,
				vignette, a little patina.
			</Body>

			<div style={{position: 'absolute', inset: 0, marginTop: 240}}>
				{PHOTOS.map((src, i) => {
					// One print centred, the rest around it on a loose ring.
					const centre = i === 0;
					const angle = ((i - 1) / (PHOTOS.length - 1)) * Math.PI * 2 - 0.6;
					const radius = 300 + random(`r${i}`) * 70;
					const x = centre ? 0 : Math.cos(angle) * radius * 1.05;
					const y = centre ? 0 : Math.sin(angle) * radius * 0.95;

					const p = spring({
						frame: frame - 20 - i * 4,
						fps,
						config: {damping: 18, mass: 0.9, stiffness: 80},
						durationInFrames: 46,
					});

					// Idle drift, each print on its own phase.
					const drift = Math.sin(frame / 40 + i) * 5;
					const rot = (random(`rot${i}`) - 0.5) * 16 + drift * 0.2;

					return (
						<div
							key={src}
							style={{
								position: 'absolute',
								left: '50%',
								top: '46%',
								transform: `translate(-50%, -50%) translate(${x * p}px, ${
									y * p + (1 - p) * 60 + drift
								}px) scale(${0.9 + p * 0.1})`,
								opacity: p,
								zIndex: centre ? 20 : 10 - i,
							}}
						>
							<Print
								width={centre ? 380 : 300}
								src={staticFile(src)}
								rotation={rot}
								age={i / (PHOTOS.length + 2)}
								shadow={0.42}
							/>
						</div>
					);
				})}
			</div>

			<div style={{position: 'absolute', left: 88, right: 88, bottom: 120}}>
				<Closer delay={96}>Nothing to scroll. Just a pile to go through.</Closer>
			</div>
		</Scene>
	);
};
