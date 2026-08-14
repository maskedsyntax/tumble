import React from 'react';
import {Img} from 'remotion';
import {palette, script} from '../theme';
import {Grain} from './Grain';

/// A single instant print, mounted on cream stock — geometry and grading
/// ported from `TumbleKit/Views/PrintView.swift` so the video reads as the
/// real product surface, not a stylised stand-in.
///
/// `develop` (0…1) drives the shake-to-develop look: washed out and
/// desaturated at first, settling into full colour. `age` (0…1) warms and
/// darkens the print the way prints in the Drawer age over time.
export const Print: React.FC<{
	src?: string;
	width: number;
	develop?: number;
	age?: number;
	caption?: string;
	rotation?: number;
	shadow?: number;
}> = ({src, width, develop = 1, age = 0, caption, rotation = 0, shadow = 0.5}) => {
	const pad = width * 0.06;
	const undeveloped = develop <= 0;

	return (
		<div
			style={{
				width,
				padding: pad,
				paddingBottom: pad + width * 0.09,
				backgroundColor: palette.printStock,
				borderRadius: width * 0.025,
				boxShadow: `0 ${width * 0.05}px ${width * 0.12}px rgba(0,0,0,${shadow})`,
				transform: `rotate(${rotation}deg)`,
			}}
		>
			<div
				style={{
					position: 'relative',
					width: '100%',
					aspectRatio: '1 / 1',
					borderRadius: width * 0.01,
					overflow: 'hidden',
					boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)',
				}}
			>
				{undeveloped ? <BlankFace width={width} /> : null}

				{!undeveloped ? (
					<>
						<div
							style={{
								position: 'absolute',
								inset: 0,
								filter: `saturate(${develop}) brightness(${1 + (1 - develop) * 0.18})`,
							}}
						>
							{src ? (
								<Img
									src={src}
									style={{width: '100%', height: '100%', objectFit: 'cover'}}
								/>
							) : (
								<div style={{width: '100%', height: '100%', background: '#2A3A49'}} />
							)}
							{/* Warm aged grade — warm over cool, both scaling with age. */}
							<div
								style={{
									position: 'absolute',
									inset: 0,
									mixBlendMode: 'multiply',
									background: `linear-gradient(135deg, rgba(214,150,90,${
										0.12 + age * 0.24
									}), rgba(120,70,60,${0.06 + age * 0.16}))`,
								}}
							/>
							<Grain opacity={0.4} seed={width} />
							{/* Vignette */}
							<div
								style={{
									position: 'absolute',
									inset: 0,
									background: `radial-gradient(circle at 50% 44%, rgba(28,16,18,0) 42%, rgba(28,16,18,0.42) 100%)`,
								}}
							/>
							{/* Sheen */}
							<div
								style={{
									position: 'absolute',
									inset: 0,
									background:
										'linear-gradient(135deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0) 48%)',
								}}
							/>
						</div>
						{/* The wash that clears as the print develops. */}
						<div
							style={{
								position: 'absolute',
								inset: 0,
								background: `rgba(255,255,255,${(1 - develop) * 0.65})`,
							}}
						/>
					</>
				) : null}
			</div>

			{caption && develop > 0.82 ? (
				<div
					style={{
						marginTop: width * 0.045,
						textAlign: 'center',
						fontFamily: script,
						fontSize: width * 0.078,
						lineHeight: 1,
						color: 'rgba(30,42,52,0.72)',
						opacity: (develop - 0.82) / 0.18,
					}}
				>
					{caption}
				</div>
			) : null}
		</div>
	);
};

/// Blank, face-down: an undeveloped shot you have not shaken yet.
const BlankFace: React.FC<{width: number}> = ({width}) => (
	<div
		style={{
			position: 'absolute',
			inset: 0,
			background: 'linear-gradient(180deg, #E8DFCC, #D8CDB4)',
			display: 'flex',
			alignItems: 'center',
			justifyContent: 'center',
		}}
	>
		<svg
			width={width * 0.16}
			height={width * 0.16}
			viewBox="0 0 24 24"
			fill="none"
			stroke="rgba(30,42,52,0.25)"
			strokeWidth={1.3}
			strokeLinecap="round"
			strokeLinejoin="round"
		>
			<path d="M8.5 12.5V5.2a1.3 1.3 0 0 1 2.6 0v6" />
			<path d="M11.1 11.4V4.1a1.3 1.3 0 0 1 2.6 0v7.3" />
			<path d="M13.7 11.8V6.4a1.3 1.3 0 0 1 2.6 0v6.4" />
			<path d="M16.3 12.8v-2.2a1.3 1.3 0 0 1 2.6 0v5.1c0 3.4-2.4 5.8-5.6 5.8-2.6 0-4-1-5.2-2.8l-3-4.6a1.3 1.3 0 0 1 2-1.6l1.4 1.6" />
		</svg>
	</div>
);
