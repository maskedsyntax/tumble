import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {display, palette, sans, script} from '../theme';

/// The ask. The roll appears first because the constraint is the idea people
/// repeat to their friends, then the price - one line, because "pay once" is
/// the whole offer.
export const Close: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const mark = spring({frame: frame + 2, fps, config: {damping: 200}});
	const line = (delay: number) =>
		spring({frame: frame - delay, fps, config: {damping: 200}});

	return (
		<Scene glowX={0.5} glowY={0.46} seed={17} fadeOut={20}>
			<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', gap: 0, padding: '0 88px'}}>
				<div style={{opacity: mark, transform: `scale(${interpolate(mark, [0, 1], [0.9, 1])})`}}>
					<Img src={staticFile('logo.png')} style={{width: 150, borderRadius: 34}} />
				</div>

				{/* Twelve a day, five gone. */}
				<div
					style={{
						display: 'grid',
						gridTemplateColumns: 'repeat(6, 1fr)',
						gap: 12,
						width: 560,
						marginTop: 48,
						opacity: line(4),
					}}
				>
					{Array.from({length: 12}).map((_, i) => (
						<div
							key={i}
							style={{
								height: 16,
								borderRadius: 8,
								backgroundColor: i < 5 ? palette.amber : 'rgba(246,239,226,0.16)',
								transform: `scaleX(${spring({frame: frame - 6 - i * 1.5, fps, config: {damping: 200}})})`,
							}}
						/>
					))}
				</div>

				<div
					style={{
						marginTop: 40,
						fontFamily: display,
						fontWeight: 600,
						fontSize: 92,
						lineHeight: 1.04,
						letterSpacing: -1.8,
						textAlign: 'center',
						color: palette.cream,
						opacity: line(12),
					}}
				>
					Twelve shots a day.
				</div>

				<div
					style={{
						marginTop: 26,
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 32,
						letterSpacing: 0.4,
						textAlign: 'center',
						color: 'rgba(246,239,226,0.74)',
						opacity: line(24),
					}}
				>
					Pay once. No subscription, no account, no cloud.
				</div>

				<div
					style={{
						marginTop: 54,
						fontFamily: script,
						fontSize: 66,
						color: palette.amber,
						opacity: line(42),
					}}
				>
					wait for it.
				</div>
			</AbsoluteFill>
		</Scene>
	);
};
