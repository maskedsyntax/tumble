import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Grain} from '../components/Grain';
import {HERO_FILE, heroPosition, wallScroll} from './Buried';
import {display, palette, sans} from '../theme';

/// The turn: one photograph is lifted out of the wall it was buried in and
/// becomes a print. Same element, one continuous move - the wall stays put
/// underneath so the cut reads as a camera push rather than a new scene.
export const Lift: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	// Where the tile was left at the end of the previous beat.
	const start = heroPosition(wallScroll(999));

	const rise = spring({frame: frame - 6, fps, config: {damping: 18, mass: 1.1}});

	const size = interpolate(rise, [0, 1], [start.size, 660]);
	const x = interpolate(rise, [0, 1], [start.x, (1080 - 660) / 2]);
	// 0.235 rather than 0.30: at 0.30 the print's bottom edge landed 13px inside
	// the headline's cap height, so the type read as stuck to the picture.
	const y = interpolate(rise, [0, 1], [start.y, 1920 * 0.235]);
	const tilt = interpolate(rise, [0, 1], [0, -3.5]);

	// The stock grows under the photo as it lands, so it turns into a print
	// rather than just getting bigger.
	const mount = interpolate(rise, [0.45, 1], [0, 1], {extrapolateLeft: 'clamp'});
	const pad = 34 * mount;

	const question = interpolate(frame, [46, 64], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
	const answer = interpolate(frame, [78, 96], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

	return (
		<AbsoluteFill style={{backgroundColor: '#0E151C'}}>
			{/* The abandoned wall, far out of focus now. */}
			<AbsoluteFill style={{opacity: 0.18, filter: 'blur(26px) saturate(0.3)'}}>
				<Img
					src={staticFile('roll/06-ocean-overlook.jpg')}
					style={{width: '100%', height: '100%', objectFit: 'cover'}}
				/>
			</AbsoluteFill>
			<Grain opacity={0.2} seed={4} />

			<div
				style={{
					position: 'absolute',
					left: x - pad,
					top: y - pad,
					width: size + pad * 2,
					padding: pad,
					paddingBottom: pad + size * 0.16 * mount,
					backgroundColor: `rgba(244,236,218,${mount})`,
					borderRadius: 14 * mount,
					boxShadow: `0 ${40 * mount}px ${90 * mount}px rgba(0,0,0,${0.5 * mount})`,
					transform: `rotate(${tilt}deg)`,
				}}
			>
				<Img
					src={staticFile(`roll/${HERO_FILE}`)}
					style={{width: size, height: size, objectFit: 'cover', display: 'block'}}
				/>
			</div>

			<AbsoluteFill style={{padding: '0 96px', justifyContent: 'flex-end', paddingBottom: 260}}>
				<div
					style={{
						opacity: question,
						fontFamily: display,
						fontWeight: 600,
						fontSize: 86,
						lineHeight: 1.08,
						letterSpacing: -1.6,
						color: palette.cream,
					}}
				>
					Somewhere in there
					<br />
					is a photo you loved.
				</div>
				<div
					style={{
						marginTop: 28,
						opacity: answer,
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 36,
						color: palette.amber,
					}}
				>
					You will never scroll far enough to find it.
				</div>
			</AbsoluteFill>
		</AbsoluteFill>
	);
};
