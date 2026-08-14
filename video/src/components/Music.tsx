import React from 'react';
import {Audio, interpolate, staticFile, useVideoConfig} from 'remotion';

/// "Warm Tape Drift" (Suno, licensed for commercial use under the paid plan).
///
/// The track is 2:33 and has a shape worth using rather than fading in and out
/// of arbitrarily. Measured from the source PCM:
///
///   118.0–121.9s  plucked and gappy — near-silence between notes
///   121.9s        the pluck passage resolves into a sustained pad
///   130–148s      the fullest, loudest sustained passage in the track
///   148.0–153.3s  a genuine outro, decaying to silence
///
/// Each cut is offset so the track's real ending lands on the film's ending —
/// no invented fade-out, and the decay falls under "Wait for it." rather than
/// under the call to action.
export const TRACK = 'warm-tape-drift.m4a';

/// Peak level for the bed. Lands the render near −15 LUFS integrated with
/// roughly 5 dB of true-peak headroom — just under the −14 LUFS that Instagram,
/// TikTok and YouTube normalise to, so the platforms lift it rather than
/// clamping it.
const BASE = 0.95;

export const MusicBed: React.FC<{
	/** Seconds into the track that the film's frame 0 should play. */
	offsetSeconds: number;
}> = ({offsetSeconds}) => {
	const {fps, durationInFrames} = useVideoConfig();

	return (
		<Audio
			src={staticFile(TRACK)}
			trimBefore={Math.round(offsetSeconds * fps)}
			volume={(frame) => {
				// Soft entry so the film does not start on a hard transient, and a
				// short assist at the tail to reach true silence on the last frame.
				const rise = interpolate(frame, [0, 26], [0, 1], {
					extrapolateLeft: 'clamp',
					extrapolateRight: 'clamp',
				});
				const fall = interpolate(
					frame,
					[durationInFrames - 22, durationInFrames - 1],
					[1, 0],
					{extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
				);
				return BASE * Math.min(rise, fall);
			}}
		/>
	);
};
