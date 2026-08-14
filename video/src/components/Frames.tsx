import React from 'react';
import {Img, staticFile} from 'remotion';
import {display, palette, sans, script} from '../theme';

/// The four postcard frames, following the geometry and treatments in
/// `TumbleKit/Postcard/`: ClassicInstantFrame, VintagePostcardFrame,
/// BorderedFilmFrame and DeckledEdgeFrame. Labels match the in-app picker.
type FrameProps = {src: string; width: number; note: string};

const stock = (width: number, extra?: React.CSSProperties): React.CSSProperties => ({
	width,
	backgroundColor: palette.printStock,
	borderRadius: width * 0.022,
	boxShadow: `0 ${width * 0.05}px ${width * 0.12}px rgba(0,0,0,0.42)`,
	overflow: 'hidden',
	...extra,
});

const Photo: React.FC<{src: string; style?: React.CSSProperties}> = ({src, style}) => (
	<Img
		src={staticFile(src)}
		style={{width: '100%', aspectRatio: '1 / 1', objectFit: 'cover', display: 'block', ...style}}
	/>
);

/// Classic instant: square image, deep bottom margin, note left, date right.
export const ClassicFrame: React.FC<FrameProps> = ({src, width, note}) => (
	<div style={stock(width, {padding: width * 0.055, paddingBottom: width * 0.17})}>
		<Photo src={src} />
		<div
			style={{
				display: 'flex',
				justifyContent: 'space-between',
				alignItems: 'flex-end',
				marginTop: width * 0.075,
			}}
		>
			<span style={{fontFamily: script, fontSize: width * 0.072, color: 'rgba(30,42,52,0.78)'}}>
				{note}
			</span>
			<span
				style={{
					fontFamily: sans,
					fontSize: width * 0.036,
					letterSpacing: width * 0.004,
					color: 'rgba(30,42,52,0.4)',
				}}
			>
				18 JUL 26
			</span>
		</div>
	</div>
);

/// Vintage postcard: correspondence rule, postmark, note beneath.
export const VintageFrame: React.FC<FrameProps> = ({src, width, note}) => (
	<div style={stock(width, {padding: width * 0.05, paddingBottom: width * 0.09})}>
		<Photo src={src} />
		<div
			style={{
				display: 'flex',
				justifyContent: 'space-between',
				alignItems: 'center',
				marginTop: width * 0.055,
				paddingBottom: width * 0.045,
				borderBottom: `1px dashed rgba(30,42,52,0.28)`,
			}}
		>
			<div>
				<div
					style={{
						fontFamily: display,
						fontSize: width * 0.058,
						letterSpacing: width * 0.008,
						color: 'rgba(30,42,52,0.8)',
					}}
				>
					POST CARD
				</div>
				<div
					style={{
						fontFamily: sans,
						fontSize: width * 0.03,
						letterSpacing: width * 0.004,
						color: 'rgba(30,42,52,0.42)',
						marginTop: width * 0.012,
					}}
				>
					Correspondence
				</div>
			</div>
			<div
				style={{
					width: width * 0.12,
					height: width * 0.12,
					borderRadius: '50%',
					border: '1.5px solid rgba(30,42,52,0.35)',
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					fontFamily: sans,
					fontSize: width * 0.022,
					color: 'rgba(30,42,52,0.45)',
					textAlign: 'center',
					lineHeight: 1.2,
				}}
			>
				18 JUL
				<br />
				2026
			</div>
		</div>
		<div
			style={{
				fontFamily: script,
				fontSize: width * 0.066,
				color: 'rgba(30,42,52,0.75)',
				marginTop: width * 0.05,
			}}
		>
			{note}
		</div>
	</div>
);

/// Bordered film: a thin white border with the note and a date burn on the image.
export const FilmFrame: React.FC<FrameProps> = ({src, width, note}) => (
	<div style={stock(width, {padding: width * 0.035})}>
		<div style={{position: 'relative'}}>
			<Photo src={src} />
			<div
				style={{
					position: 'absolute',
					inset: 0,
					background:
						'linear-gradient(180deg, rgba(0,0,0,0) 62%, rgba(0,0,0,0.34) 100%)',
				}}
			/>
			<div
				style={{
					position: 'absolute',
					left: width * 0.05,
					right: width * 0.05,
					bottom: width * 0.045,
					display: 'flex',
					justifyContent: 'space-between',
					alignItems: 'flex-end',
				}}
			>
				<span style={{fontFamily: script, fontSize: width * 0.07, color: '#F6EFE2'}}>
					{note}
				</span>
				<span
					style={{
						fontFamily: sans,
						fontWeight: 700,
						fontSize: width * 0.042,
						letterSpacing: width * 0.004,
						color: '#E9A13B',
						textShadow: '0 0 8px rgba(233,161,59,0.5)',
					}}
				>
					18·07·26
				</span>
			</div>
		</div>
	</div>
);

/// Deckled edge: a torn print taped down, caption below.
export const DeckledFrame: React.FC<FrameProps> = ({src, width, note}) => {
	// A jagged clip path reads as a hand-torn edge.
	const torn =
		'polygon(1% 3%, 12% 0%, 26% 4%, 40% 1%, 55% 5%, 70% 1%, 84% 4%, 97% 1%, 100% 12%, 96% 26%, 100% 41%, 97% 56%, 100% 70%, 96% 85%, 99% 98%, 86% 100%, 71% 96%, 56% 100%, 42% 96%, 27% 100%, 13% 96%, 2% 99%, 0% 86%, 4% 71%, 0% 56%, 3% 42%, 0% 27%, 4% 13%';

	return (
		<div style={stock(width, {padding: width * 0.06, paddingBottom: width * 0.1})}>
			<div style={{position: 'relative'}}>
				<div style={{clipPath: `${torn})`}}>
					<Photo src={src} />
				</div>
				{/* Strip of tape holding the print down. */}
				<div
					style={{
						position: 'absolute',
						top: -width * 0.035,
						left: '50%',
						width: width * 0.3,
						height: width * 0.075,
						transform: 'translateX(-50%) rotate(-2.5deg)',
						backgroundColor: 'rgba(233,220,196,0.72)',
						boxShadow: '0 2px 6px rgba(0,0,0,0.18)',
					}}
				/>
			</div>
			<div
				style={{
					fontFamily: script,
					fontSize: width * 0.066,
					color: 'rgba(30,42,52,0.72)',
					textAlign: 'center',
					marginTop: width * 0.06,
				}}
			>
				{note}
			</div>
		</div>
	);
};
