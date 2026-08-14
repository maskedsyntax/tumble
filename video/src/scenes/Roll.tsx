import React from 'react';
import {interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Scene} from '../components/Scene';
import {Print} from '../components/Print';
import {Body, Closer, Headline, Kicker} from '../components/Type';
import {palette, sans} from '../theme';

const TAKEN = 4;

/// Scene 2 — the constraint, stated plainly and shown as the app shows it:
/// twelve slots, four of them spent. The limit is the product, so it gets the
/// biggest number on screen.
export const Roll: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const rise = spring({
		frame: frame - 18,
		fps,
		config: {damping: 200, mass: 0.8},
		durationInFrames: 34,
	});

	return (
		<Scene glowX={80} glowY={20} seed={3}>
			<Kicker>The Daily Roll</Kicker>
			<div style={{height: 22}} />
			<Headline delay={4} size={84} maxWidth={904}>
				Twelve shots a day.
			</Headline>
			<div style={{height: 34}} />
			<Body delay={20} maxWidth={800}>
				A fresh roll every morning — enough to notice, never enough to mindlessly
				collect.
			</Body>

			<div
				style={{
					position: 'absolute',
					inset: 0,
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					marginTop: 150,
				}}
			>
				<div
					style={{
						position: 'relative',
						transform: `translateY(${(1 - rise) * 70}px) scale(${0.94 + rise * 0.06})`,
						opacity: rise,
					}}
				>
					<Print
						width={560}
						src={staticFile('photos/img1.JPG')}
						caption="one of twelve"
						rotation={-3}
					/>
					<Counter frame={frame} />
				</div>
			</div>

			<div style={{position: 'absolute', left: 88, right: 88, bottom: 130}}>
				<SlotGrid frame={frame} />
				<div style={{height: 46}} />
				<Closer delay={104}>Four moments taken. Eight still waiting.</Closer>
			</div>
		</Scene>
	);
};

/// The amber counter medallion, lifted from the App Store screenshot set.
const Counter: React.FC<{frame: number}> = ({frame}) => {
	const {fps} = useVideoConfig();
	const pop = spring({
		frame: frame - 40,
		fps,
		config: {damping: 12, mass: 0.7, stiffness: 120},
		durationInFrames: 34,
	});
	return (
		<div
			style={{
				position: 'absolute',
				right: -76,
				top: 300,
				width: 200,
				height: 200,
				borderRadius: 100,
				backgroundColor: palette.amber,
				display: 'flex',
				flexDirection: 'column',
				alignItems: 'center',
				justifyContent: 'center',
				boxShadow: '0 20px 46px rgba(0,0,0,0.34)',
				transform: `scale(${pop})`,
			}}
		>
			<div
				style={{
					fontFamily: sans,
					fontWeight: 700,
					fontSize: 74,
					lineHeight: 1,
					color: palette.blueDeep,
				}}
			>
				12
			</div>
			<div
				style={{
					fontFamily: sans,
					fontWeight: 600,
					fontSize: 20,
					letterSpacing: 2.4,
					marginTop: 8,
					color: palette.blueDeep,
				}}
			>
				SHOTS TODAY
			</div>
		</div>
	);
};

/// Twelve slots; the first four light up in sequence as the roll is spent.
const SlotGrid: React.FC<{frame: number}> = ({frame}) => (
	<div
		style={{
			display: 'grid',
			gridTemplateColumns: 'repeat(6, 1fr)',
			gap: 18,
			padding: 26,
			borderRadius: 34,
			backgroundColor: 'rgba(32,45,57,0.5)',
			border: '1px solid rgba(246,239,226,0.08)',
		}}
	>
		{Array.from({length: 12}).map((_, i) => {
			const on =
				i < TAKEN
					? interpolate(frame - 56 - i * 9, [0, 10], [0, 1], {
							extrapolateLeft: 'clamp',
							extrapolateRight: 'clamp',
					  })
					: 0;
			return (
				<div
					key={i}
					style={{
						height: 74,
						borderRadius: 14,
						display: 'flex',
						alignItems: 'center',
						justifyContent: 'center',
						fontFamily: sans,
						fontWeight: 600,
						fontSize: 26,
						backgroundColor: `rgba(223,171,104,${on})`,
						boxShadow: `inset 0 0 0 1px rgba(246,239,226,${0.1 - on * 0.1})`,
						color: on > 0.5 ? palette.blueDeep : 'rgba(246,239,226,0.45)',
						transform: `scale(${1 + on * 0.03 - (on > 0 && on < 1 ? 0 : 0)})`,
					}}
				>
					{String(i + 1).padStart(2, '0')}
				</div>
			);
		})}
	</div>
);
