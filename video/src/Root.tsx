import React from 'react';
import {AbsoluteFill, Composition, Sequence} from 'remotion';
import {FPS} from './theme';
import {AD_TRACK, MusicBed} from './components/Music';
import {Hook} from './scenes/Hook';
import {Roll} from './scenes/Roll';
import {Shake} from './scenes/Shake';
import {Drawer} from './scenes/Drawer';
import {Filters} from './scenes/Filters';
import {FramesScene} from './scenes/FramesScene';
import {Private} from './scenes/Private';
import {CTA} from './scenes/CTA';
import {Open} from './preview/Open';
import {Looks} from './preview/Looks';
import {Develop} from './preview/Develop';
import {Postcards} from './preview/Postcards';
import {Drawer as PreviewDrawer} from './preview/Drawer';
import {Close} from './preview/Close';
import {Buried} from './ad/Buried';
import {Lift} from './ad/Lift';
import {Twelve} from './ad/Twelve';
import {Keepsake} from './ad/Keepsake';
import {Ask} from './ad/Ask';

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

/// The 2.0 preview: look first. The old cut opened on the twelve-shot roll,
/// which asks a stranger to care about a constraint before they have seen
/// anything they want - so this one opens on the grade sweeping across a
/// photograph, spends its longest beat on the stocks, and keeps the roll and
/// the price for the ask at the end.
const PREVIEW: SceneSpec[] = [
	{Comp: Open, seconds: 4.0},
	{Comp: Looks, seconds: 6.8},
	{Comp: Develop, seconds: 5.6},
	{Comp: Postcards, seconds: 4.4},
	{Comp: PreviewDrawer, seconds: 4.2},
	{Comp: Close, seconds: 5.0},
];

/// The paid social ad. Not a feature tour: it opens on something the viewer
/// already feels - a camera roll they never revisit - and only offers Tumble
/// once that loss is on the table. The last card counts today's roll down,
/// because the thing they are missing has a clock on it.
const AD: SceneSpec[] = [
	{Comp: Buried, seconds: 4.6},
	{Comp: Lift, seconds: 4.4},
	{Comp: Twelve, seconds: 6.4},
	{Comp: Keepsake, seconds: 5.6},
	{Comp: Ask, seconds: 5.4},
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

const Film: React.FC<{
	scenes: SceneSpec[];
	musicOffset: number;
	track?: string;
	rise?: number;
	fall?: number;
}> = ({scenes, musicOffset, track, rise, fall}) => (
	<AbsoluteFill style={{backgroundColor: '#1B2733'}}>
		<MusicBed offsetSeconds={musicOffset} track={track} rise={rise} fall={fall} />
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

// 2.0 preview: 28.7s, so 124.6s puts the track's decay (148.0-153.3s) under
// "wait for it." rather than under the pricing line.
const PreviewFilm: React.FC = () => <Film scenes={PREVIEW} musicOffset={124.6} />;

// The ad runs on its own bed, cut to length by scripts/build-ad-audio.sh so the
// track's hardest entry (144.000s in the source) lands on frame 250 - the cut
// into "what if you only got twelve a day?". Playing from 0 with almost no
// ramps here, because that file already carries its own fades.
const AdFilm: React.FC = () => (
	<Film scenes={AD} musicOffset={0} track={AD_TRACK} rise={2} fall={2} />
);

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
			{/* Paid social: Reels, TikTok, Shorts. */}
			<Composition
				id="TumbleAd"
				component={AdFilm}
				durationInFrames={totalOf(AD)}
				fps={FPS}
				width={1080}
				height={1920}
			/>
			{/* The 2.0 App Store preview - look first, under 30s. */}
			<Composition
				id="TumblePreview"
				component={PreviewFilm}
				durationInFrames={totalOf(PREVIEW)}
				fps={FPS}
				width={1080}
				height={1920}
			/>
			{/* The 1.2 cut, kept while 2.0 is unreleased. */}
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
