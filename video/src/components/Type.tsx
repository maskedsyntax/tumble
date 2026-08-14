import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {display, displayItalic, palette, sans} from '../theme';

/// Words rise into place one at a time. Reads as typeset rather than animated,
/// which is what the app's stillness calls for.
export const Headline: React.FC<{
	children: string;
	delay?: number;
	size?: number;
	color?: string;
	align?: 'left' | 'center';
	maxWidth?: number;
}> = ({
	children,
	delay = 0,
	size = 96,
	color = palette.cream,
	align = 'left',
	maxWidth,
}) => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	return (
		<div
			style={{
				fontFamily: display,
				fontWeight: 600,
				fontSize: size,
				lineHeight: 1.06,
				letterSpacing: -size * 0.018,
				color,
				textAlign: align,
				maxWidth,
				display: 'flex',
				flexWrap: 'wrap',
				gap: `0 ${size * 0.26}px`,
				justifyContent: align === 'center' ? 'center' : 'flex-start',
			}}
		>
			{children.split(' ').map((word, i) => {
				const p = spring({
					frame: frame - delay - i * 3,
					fps,
					config: {damping: 200, mass: 0.6},
					durationInFrames: 26,
				});
				return (
					<span
						key={`${word}-${i}`}
						style={{
							display: 'inline-block',
							opacity: p,
							transform: `translateY(${(1 - p) * size * 0.28}px)`,
						}}
					>
						{word}
					</span>
				);
			})}
		</div>
	);
};

/// Small caps kicker used above section headings, on the site and in the app.
export const Kicker: React.FC<{
	children: React.ReactNode;
	delay?: number;
	color?: string;
	size?: number;
}> = ({children, delay = 0, color = palette.amber, size = 26}) => {
	const frame = useCurrentFrame();
	const o = interpolate(frame - delay, [0, 14], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});
	return (
		<div
			style={{
				fontFamily: sans,
				fontWeight: 600,
				fontSize: size,
				letterSpacing: size * 0.16,
				textTransform: 'uppercase',
				color,
				opacity: o,
			}}
		>
			{children}
		</div>
	);
};

export const Body: React.FC<{
	children: React.ReactNode;
	delay?: number;
	size?: number;
	color?: string;
	maxWidth?: number;
	align?: 'left' | 'center';
	weight?: number;
}> = ({
	children,
	delay = 0,
	size = 34,
	color = 'rgba(246,239,226,0.78)',
	maxWidth,
	align = 'left',
	weight = 400,
}) => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const p = spring({
		frame: frame - delay,
		fps,
		config: {damping: 200, mass: 0.7},
		durationInFrames: 24,
	});
	return (
		<div
			style={{
				fontFamily: sans,
				fontWeight: weight,
				fontSize: size,
				lineHeight: 1.45,
				color,
				maxWidth,
				textAlign: align,
				opacity: p,
				transform: `translateY(${(1 - p) * 16}px)`,
			}}
		>
			{children}
		</div>
	);
};

/// The italic serif line that closes each App Store screenshot.
export const Closer: React.FC<{children: React.ReactNode; delay?: number}> = ({
	children,
	delay = 0,
}) => {
	const frame = useCurrentFrame();
	const p = interpolate(frame - delay, [0, 20], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});
	return (
		<div
			style={{
				fontFamily: displayItalic,
				fontStyle: 'italic',
				fontSize: 36,
				color: 'rgba(246,239,226,0.72)',
				textAlign: 'center',
				opacity: p,
			}}
		>
			{children}
		</div>
	);
};
