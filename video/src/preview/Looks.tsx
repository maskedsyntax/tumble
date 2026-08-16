import React from 'react';
import {
	AbsoluteFill,
	Img,
	interpolate,
	spring,
	staticFile,
	useCurrentFrame,
	useVideoConfig,
} from 'remotion';
import {Scene} from '../components/Scene';
import {Headline, Kicker} from '../components/Type';
import {palette, sans} from '../theme';

/// The reason to buy: one photograph, every film. The cycle is fast enough to
/// feel like scrubbing a real picker and slow enough to read each name - the
/// stocks are the product, so this beat gets the most screen time.
const CYCLE = [
	'fadedInstant',
	'disposable',
	'silver',
	'goldenHour',
	'crossProcess',
	'flashNight',
	'sepiaPrint',
	'lightLeak',
	'camcorder',
	'charcoal',
	'sunbleached',
	'fogged',
];

const NAMES: Record<string, string> = {
	fadedInstant: 'Faded Instant',
	disposable: 'Disposable',
	silver: 'Silver',
	goldenHour: 'Golden Hour',
	crossProcess: 'Cross Process',
	flashNight: 'Flash Night',
	sepiaPrint: 'Sepia Print',
	lightLeak: 'Light Leak',
	camcorder: 'Camcorder',
	charcoal: 'Charcoal',
	sunbleached: 'Sunbleached',
	fogged: 'Fogged',
	overcast: 'Overcast',
	hazy: 'Hazy',
	platinum: 'Platinum',
};

const GRID = [
	'disposable',
	'silver',
	'goldenHour',
	'crossProcess',
	'lightLeak',
	'sepiaPrint',
	'flashNight',
	'camcorder',
	'charcoal',
];

const HOLD = 7; // frames per stock
const GRID_AT = 108;

export const Looks: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const index = Math.min(Math.floor(frame / HOLD), CYCLE.length - 1);
	const stock = CYCLE[index];

	// The single print shrinks away as the grid takes over.
	const toGrid = spring({frame: frame - GRID_AT, fps, config: {damping: 200}});
	const heroScale = interpolate(toGrid, [0, 1], [1, 0.42]);
	const heroOpacity = interpolate(toGrid, [0, 0.55], [1, 0], {extrapolateRight: 'clamp'});

	return (
		<Scene glowX={0.5} glowY={0.32} seed={7}>
			<div style={{display: 'flex', flexDirection: 'column', height: '100%'}}>
				<Kicker delay={2}>TWENTY-ONE FILM STOCKS</Kicker>
				<div style={{height: 18}} />
				<Headline delay={4} size={104}>
					{'One shot.\nEvery film.'}
				</Headline>

				<div style={{flex: 1, position: 'relative', marginTop: 40}}>
					{/* The cycling print. */}
					<AbsoluteFill
						style={{
							alignItems: 'center',
							justifyContent: 'flex-start',
							opacity: heroOpacity,
							transform: `scale(${heroScale})`,
						}}
					>
						<div
							style={{
								width: 640,
								padding: 26,
								paddingBottom: 96,
								backgroundColor: palette.printStock,
								borderRadius: 14,
								boxShadow: '0 40px 90px rgba(0,0,0,0.45)',
							}}
						>
							<Img
								key={stock}
								src={staticFile(`looks/hero-${stock}.jpg`)}
								style={{width: '100%', aspectRatio: '1 / 1', objectFit: 'cover', display: 'block'}}
							/>
							<div
								style={{
									marginTop: 22,
									textAlign: 'center',
									fontFamily: sans,
									fontWeight: 700,
									fontSize: 30,
									letterSpacing: 1.2,
									color: '#3B3730',
								}}
							>
								{NAMES[stock] ?? stock}
							</div>
						</div>
					</AbsoluteFill>

					{/* The shelf it came from. */}
					<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
						<div
							style={{
								display: 'grid',
								gridTemplateColumns: 'repeat(3, 1fr)',
								gap: 18,
								width: 780,
							}}
						>
							{GRID.map((id, i) => {
								const pop = spring({
									frame: frame - GRID_AT - 6 - i * 3,
									fps,
									config: {damping: 14, mass: 0.6},
								});
								return (
									<div
										key={id}
										style={{
											opacity: pop,
											transform: `scale(${interpolate(pop, [0, 1], [0.82, 1])})`,
										}}
									>
										<Img
											src={staticFile(`looks/hero-${id}.jpg`)}
											style={{
												width: '100%',
												aspectRatio: '1 / 1',
												objectFit: 'cover',
												borderRadius: 10,
												display: 'block',
												boxShadow: '0 10px 24px rgba(0,0,0,0.35)',
											}}
										/>
										<div
											style={{
												marginTop: 10,
												textAlign: 'center',
												fontFamily: sans,
												fontWeight: 600,
												fontSize: 21,
												color: 'rgba(246,239,226,0.72)',
											}}
										>
											{NAMES[id] ?? id}
										</div>
									</div>
								);
							})}
						</div>

						<div
							style={{
								marginTop: 34,
								opacity: spring({frame: frame - GRID_AT - 40, fps, config: {damping: 200}}),
								fontFamily: sans,
								fontWeight: 600,
								fontSize: 26,
								letterSpacing: 1,
								color: palette.amber,
							}}
						>
							Free everyday stocks · packs from $1.99
						</div>
					</AbsoluteFill>
				</div>
			</div>
		</Scene>
	);
};
