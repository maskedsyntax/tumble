import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Backdrop} from '../components/Grain';
import {display, palette, sans, script} from '../theme';

/// The ask, phrased as the thing they lose by closing the video: today's roll
/// is already running.
export const Ask: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const mark = spring({frame, fps, config: {damping: 200}});
	const line = (delay: number) => spring({frame: frame - delay, fps, config: {damping: 200}});

	// A roll filling up behind the button - the constraint as an image rather
	// than a countdown. It deliberately does not claim the viewer has shots
	// left: they have not installed anything, and a fake counter is a lie the
	// first launch would immediately expose.
	const filled = Math.min(12, Math.max(0, Math.floor((frame - 20) / 2.5)));

	return (
		<Backdrop glowX={0.5} glowY={0.44} seed={21}>
			<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', padding: '0 96px'}}>
				<div style={{opacity: mark, transform: `scale(${interpolate(mark, [0, 1], [0.92, 1])})`}}>
					<Img src={staticFile('logo.png')} style={{width: 150, borderRadius: 34}} />
				</div>

				<div
					style={{
						marginTop: 44,
						fontFamily: display,
						fontWeight: 600,
						fontSize: 100,
						lineHeight: 1.02,
						letterSpacing: -2,
						textAlign: 'center',
						color: palette.cream,
						opacity: line(6),
					}}
				>
					Tumble
				</div>

				<div
					style={{
						marginTop: 20,
						fontFamily: sans,
						fontWeight: 700,
						fontSize: 38,
						letterSpacing: 0.4,
						textAlign: 'center',
						color: palette.amber,
						opacity: line(14),
					}}
				>
					A camera that makes you wait.
				</div>

				<div
					style={{
						marginTop: 46,
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 33,
						textAlign: 'center',
						lineHeight: 1.5,
						color: 'rgba(246,239,226,0.72)',
						opacity: line(26),
					}}
				>
					Free to start · Pay once, never again
					<br />
					No account. No cloud. No feed.
				</div>

				<div style={{display: 'flex', gap: 8, marginTop: 50, width: 470, opacity: line(32)}}>
					{Array.from({length: 12}).map((_, i) => (
						<div
							key={i}
							style={{
								flex: 1,
								height: 12,
								borderRadius: 6,
								backgroundColor: i < filled ? palette.amber : 'rgba(246,239,226,0.16)',
							}}
						/>
					))}
				</div>

				<div
					style={{
						marginTop: 34,
						fontFamily: sans,
						fontWeight: 700,
						fontSize: 31,
						letterSpacing: 2,
						color: palette.ink,
						backgroundColor: palette.amber,
						padding: '21px 46px',
						borderRadius: 999,
						opacity: line(40),
					}}
				>
					START TODAY&rsquo;S ROLL
				</div>

				<div
					style={{
						marginTop: 40,
						fontFamily: script,
						fontSize: 64,
						color: 'rgba(246,239,226,0.8)',
						opacity: line(54),
					}}
				>
					wait for it.
				</div>
			</AbsoluteFill>
		</Backdrop>
	);
};
