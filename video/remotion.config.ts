import {Config} from '@remotion/cli/config';

Config.setVideoImageFormat('jpeg');
Config.setOverwriteOutput(true);
// Grain and the develop wash need the extra headroom; 1 keeps banding away.
Config.setCrf(17);
