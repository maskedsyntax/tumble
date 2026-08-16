import React from 'react';
import {AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Grain} from '../components/Grain';
import {display, palette, sans} from '../theme';

/// The cold open: the same photograph, ungraded, with the film grade sweeping
/// across it. One frame has to answer "why would I install this" - so it is the
/// product's actual output, not a promise about it.
export const Open: React.FC = () => {
	const frame = useCurrentFrame();

	// A slow push in, so the still never reads as a static image.
	const scale = interpolate(frame, [0, 120], [1.04, 1.12]);

	// The sweep: a hard edge travelling left to right, carrying the grade.
	const sweep = interpolate(frame, [16, 62], [0, 100], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
		easing: (t) => 1 - Math.pow(1 - t, 3),
	});

	const label = interpolate(frame, [22, 34], [0, 1], {extrapolateRight: 'clamp'});
	const headline = interpolate(frame, [58, 74], [0, 1], {extrapolateRight: 'clamp'});
	const lift = interpolate(frame, [58, 78], [40, 0], {extrapolateRight: 'clamp'});

	return (
		<AbsoluteFill style={{backgroundColor: palette.ink}}>
			<AbsoluteFill style={{transform: `scale(${scale})`}}>
				<Img
					src={staticFile('looks/hero-original.jpg')}
					style={{width: '100%', height: '100%', objectFit: 'cover'}}
				/>
				<AbsoluteFill style={{clipPath: `inset(0 ${100 - sweep}% 0 0)`}}>
					<Img
						src={staticFile('looks/hero-warmArchive.jpg')}
						style={{width: '100%', height: '100%', objectFit: 'cover'}}
					/>
				</AbsoluteFill>

				{/* The leading edge of the sweep, lit like a light leak. */}
				{sweep > 0 && sweep < 100 ? (
					<AbsoluteFill
						style={{
							left: `${sweep}%`,
							width: 8,
							background: `linear-gradient(90deg, ${palette.amber}, rgba(223,171,104,0))`,
							filter: 'blur(2px)',
						}}
					/>
				) : null}
			</AbsoluteFill>

			{/* Grain only on the graded half, so the texture reads as the point.
			    Grain alone, never Backdrop - the backdrop paints an opaque
			    graincore field and would cover the photograph entirely. */}
			<AbsoluteFill style={{clipPath: `inset(0 ${100 - sweep}% 0 0)`}}>
				<Grain opacity={0.3} seed={3} />
			</AbsoluteFill>

			<AbsoluteFill
				style={{
					background:
						'linear-gradient(180deg, rgba(20,31,40,0.55) 0%, rgba(20,31,40,0) 34%, rgba(20,31,40,0.15) 55%, rgba(20,31,40,0.92) 100%)',
				}}
			/>

			{/* Bottom padding is deep on purpose: a preview plays inside a player
			    whose controls sit along the lower edge, and type that close to
			    the edge reads as falling out of frame. */}
			<AbsoluteFill style={{padding: '120px 88px 300px', justifyContent: 'space-between'}}>
				<div style={{display: 'flex', gap: 22, opacity: label}}>
					<Tag>YOUR CAMERA</Tag>
					<Tag gold>TUMBLE</Tag>
				</div>

				<div style={{opacity: headline, transform: `translateY(${lift}px)`}}>
					<div
						style={{
							fontFamily: display,
							fontWeight: 600,
							fontSize: 118,
							lineHeight: 1.02,
							letterSpacing: -2.4,
							color: palette.cream,
						}}
					>
						Not a filter.
						<br />
						A film stock.
					</div>
				</div>
			</AbsoluteFill>
		</AbsoluteFill>
	);
};

const Tag: React.FC<{children: string; gold?: boolean}> = ({children, gold}) => (
	<div
		style={{
			fontFamily: sans,
			fontWeight: 700,
			fontSize: 24,
			letterSpacing: 3,
			color: gold ? palette.ink : palette.cream,
			backgroundColor: gold ? palette.amber : 'rgba(0,0,0,0.42)',
			padding: '12px 24px',
			borderRadius: 999,
		}}
	>
		{children}
	</div>
);
