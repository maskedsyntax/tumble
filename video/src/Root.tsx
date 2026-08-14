import React from 'react';
import {AbsoluteFill, Composition, Sequence} from 'remotion';
import {FPS} from './theme';
import {MusicBed} from './components/Music';
import {Hook} from './scenes/Hook';
import {Roll} from './scenes/Roll';
import {Shake} from './scenes/Shake';
import {Drawer} from './scenes/Drawer';
import {Filters} from './scenes/Filters';
import {FramesScene} from './scenes/FramesScene';
import {Private} from './scenes/Private';
import {CTA} from './scenes/CTA';

// Scenes overlap by `OVERLAP` frames so each one dissolves into the next.
const OVERLAP = 10;

type SceneSpec = {Comp: React.FC; seconds: number};

/// The full cut: site hero, YouTube, and long-form social.
const FULL: SceneSpec[] = [
	{Comp: Hook, seconds: 3.6},
	{Comp: Roll, seconds: 5.4},
	{Comp: Shake, seconds: 6.6},
	{Comp: Drawer, seconds: 5.4},
	{Comp: Filters, seconds: 4.4},
	{Comp: FramesScene, seconds: 5.0},
	{Comp: Private, seconds: 4.6},
	{Comp: CTA, seconds: 6.2},
];

/// The preview cut. App Store app previews are capped at 30 seconds, so this
/// drops the two supporting beats and keeps constraint → ritual → keepsake →
/// ask. Nothing is sped up; scenes are simply tighter.
const SHORT: SceneSpec[] = [
	{Comp: Hook, seconds: 2.8},
	{Comp: Roll, seconds: 4.6},
	{Comp: Shake, seconds: 6.2},
	{Comp: Drawer, seconds: 4.6},
	{Comp: FramesScene, seconds: 4.4},
	{Comp: CTA, seconds: 5.8},
];

const layout = (scenes: SceneSpec[]) =>
	scenes.reduce<{Comp: React.FC; from: number; duration: number}[]>(
		(acc, scene) => {
			const previous = acc[acc.length - 1];
			const from = previous ? previous.from + previous.duration - OVERLAP : 0;
			return [
				...acc,
				{Comp: scene.Comp, from, duration: Math.round(scene.seconds * FPS)},
			];
		},
		[],
	);

const totalOf = (scenes: SceneSpec[]) => {
	const timeline = layout(scenes);
	const last = timeline[timeline.length - 1];
	return last.from + last.duration;
};

const Film: React.FC<{scenes: SceneSpec[]; musicOffset: number}> = ({
	scenes,
	musicOffset,
}) => (
	<AbsoluteFill style={{backgroundColor: '#1B2733'}}>
		<MusicBed offsetSeconds={musicOffset} />
		{layout(scenes).map(({Comp, from, duration}, i) => (
			<Sequence key={i} from={from} durationInFrames={duration}>
				<Comp />
			</Sequence>
		))}
	</AbsoluteFill>
);

// Full cut: 112.77s puts the track's pluck-to-pad resolution (121.9s) on the
// first shake burst at 9.13s, and its outro under the closing card.
const FullFilm: React.FC = () => <Film scenes={FULL} musicOffset={112.77} />;

// Short cut: anchored on the ending instead — 124.91s lands the track's last
// full bar on the pricing cards and its decay on "Wait for it."
const ShortFilm: React.FC = () => <Film scenes={SHORT} musicOffset={124.91} />;

export const RemotionRoot: React.FC = () => {
	return (
		<>
			{/* Vertical master: Reels, TikTok, Shorts, site hero. */}
			<Composition
				id="TumbleFilm"
				component={FullFilm}
				durationInFrames={totalOf(FULL)}
				fps={FPS}
				width={1080}
				height={1920}
			/>
			{/* Under 30s, for App Store Connect app previews. */}
			<Composition
				id="TumbleFilmShort"
				component={ShortFilm}
				durationInFrames={totalOf(SHORT)}
				fps={FPS}
				width={1080}
				height={1920}
			/>
		</>
	);
};
