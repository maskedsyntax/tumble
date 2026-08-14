import {loadFont as loadFraunces} from '@remotion/google-fonts/Fraunces';
import {loadFont as loadInter} from '@remotion/google-fonts/Inter';
import {loadFont as loadCaveat} from '@remotion/google-fonts/Caveat';

// Fraunces (display serif), Inter (sans), Caveat (handwritten notes) are the
// exact three faces the app ships in `TumbleKit/Theme/Typography.swift`.
// Only the weights and subsets the film actually sets — the full Google
// families are hundreds of requests per render otherwise.
export const display = loadFraunces('normal', {
	weights: ['600'],
	subsets: ['latin'],
}).fontFamily;
export const displayItalic = loadFraunces('italic', {
	weights: ['400'],
	subsets: ['latin'],
}).fontFamily;
export const sans = loadInter('normal', {
	weights: ['400', '500', '600', '700'],
	subsets: ['latin'],
}).fontFamily;
export const script = loadCaveat('normal', {
	weights: ['400'],
	subsets: ['latin'],
}).fontFamily;

/// The "graincore" palette, ported verbatim from `TumbleKit/Theme/Palette.swift`.
export const palette = {
	blue: '#2E4052',
	blueDeep: '#223140',
	blueLift: '#3A5164',
	cream: '#F6EFE2',
	creamDim: '#E9DCC4',
	ink: '#1E2A34',
	amber: '#DFAB68',
	charcoalDeep: '#202D39',
	printStock: '#F4ECDA',
} as const;

export const FPS = 30;
