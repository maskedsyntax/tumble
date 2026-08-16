import React from 'react';
import {AbsoluteFill, Img, interpolate, random, staticFile, useCurrentFrame} from 'remotion';
import {Grain} from '../components/Grain';
import {display, palette, sans} from '../theme';

/// The hook. A camera roll scrolling past too fast to see, slowing to a stop -
/// then the question. Nothing here is a slideshow: the wall is one moving
/// object the camera is looking at, and the type arrives on top of it.
const FILES = [
	'01-autumn-trail.jpg', '02-forest-path.jpg', '03-vintage-bicycle.jpg',
	'04-city-sunset.jpg', '05-coastal-cliff.jpg', '06-ocean-overlook.jpg',
	'07-coffee-books.jpg', '08-desert-road.jpg', '09-misty-steps.jpg',
	'10-himalayan-road.jpg', '11-mountain-road.jpg', '12-ocean-foam.jpg',
	'13-vintage-camera.jpg', '14-quiet-lake.jpg', '15-rainy-night.jpg',
	'16-rainy-park.jpg', '17-river-stones.jpg', '18-snowy-hills.jpg',
];

const COLS = 5;
const TILE = 232;
const GAP = 8;
const ROWS = 16;

/// The one photograph the ad follows all the way through. It sits at a known
/// spot in the wall so the next beat can lift it out of exactly that place.
export const HERO_ROW = 8;
export const HERO_COL = 2;
export const HERO_FILE = '04-city-sunset.jpg';

const tileAt = (row: number, col: number) => {
	if (row === HERO_ROW && col === HERO_COL) return HERO_FILE;
	const n = Math.floor(random(`tile-${row}-${col}`) * FILES.length);
	return FILES[n];
};

/// Where the hero tile sits on screen at a given scroll offset, so the pull-out
/// can start from the exact pixel the wall left it on.
export const heroPosition = (scroll: number) => ({
	x: (1080 - (COLS * TILE + (COLS - 1) * GAP)) / 2 + HERO_COL * (TILE + GAP),
	y: 1920 * 0.5 - scroll + HERO_ROW * (TILE + GAP),
	size: TILE,
});

export const wallScroll = (frame: number) =>
	interpolate(frame, [0, 74], [0, 2180], {
		extrapolateRight: 'clamp',
		easing: (t) => 1 - Math.pow(1 - t, 2.6),
	});

export const Buried: React.FC = () => {
	const frame = useCurrentFrame();
	const scroll = wallScroll(frame);

	// The wall drains of colour as it stops - what a gallery feels like to
	// scroll, rather than what any single photo looks like.
	const drain = interpolate(frame, [58, 92], [1, 0.25], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});
	const dim = interpolate(frame, [58, 96], [0, 0.72], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});

	// Speed reads as blur early on, the way a fast flick does on a phone.
	const speed = Math.max(0, 1 - frame / 74);
	const blur = speed * 11;

	const line1 = interpolate(frame, [66, 82], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
	const line2 = interpolate(frame, [96, 112], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
	const lift = interpolate(frame, [96, 116], [26, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

	return (
		<AbsoluteFill style={{backgroundColor: '#0E151C'}}>
			<AbsoluteFill
				style={{
					filter: `blur(${blur}px) saturate(${drain})`,
					transform: `translateY(${-scroll}px) scale(1.06)`,
				}}
			>
				{Array.from({length: ROWS}).map((_, row) => (
					<div
						key={row}
						style={{
							position: 'absolute',
							top: 1920 * 0.5 + row * (TILE + GAP),
							left: (1080 - (COLS * TILE + (COLS - 1) * GAP)) / 2,
							display: 'flex',
							gap: GAP,
						}}
					>
						{Array.from({length: COLS}).map((__, col) => (
							<Img
								key={col}
								src={staticFile(`roll/${tileAt(row, col)}`)}
								style={{width: TILE, height: TILE, objectFit: 'cover', display: 'block'}}
							/>
						))}
					</div>
				))}
			</AbsoluteFill>

			<AbsoluteFill style={{backgroundColor: '#0E151C', opacity: dim}} />
			<Grain opacity={0.18} seed={2} />

			<AbsoluteFill style={{padding: '0 96px', justifyContent: 'center'}}>
				<div
					style={{
						opacity: line1,
						fontFamily: sans,
						fontWeight: 700,
						fontSize: 34,
						letterSpacing: 3.4,
						color: palette.amber,
						textTransform: 'uppercase',
					}}
				>
					14,000 photos this year
				</div>
				<div
					style={{
						marginTop: 26,
						opacity: line2,
						transform: `translateY(${lift}px)`,
						fontFamily: display,
						fontWeight: 600,
						fontSize: 96,
						lineHeight: 1.06,
						letterSpacing: -2,
						color: palette.cream,
					}}
				>
					When did you
					<br />
					last look at one?
				</div>
			</AbsoluteFill>
		</AbsoluteFill>
	);
};
