Exp Info - Session 88, Experiment 4

Raw data is found here: O:\Session 88\Exp 4 - Rmin Redo\0 Raw Tifs
raw560 corresponds to channel 1 from which density data is extracted; 
raw647 corresponds to channel 2 and tracks filaments
Each file is a raw 3D matrix of microscopy data
Voxel spacing [.55 .55 .7]um dx dy dz, 30 seconds between frames

I'd like to generate a correction matrix as I do in my original image correction scripts, say using Times 1-3 to make a correction mask for 560 data, before correcting frame 22 of 560 channel;  this is the data used for "shared preparation example"

16bit corrected data with original voxel sizes: O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit
*560 files correspond to density data
*647 files correspond to filaments
Voxel spacing [.55 .55 .7]um dx dy dz, 30 seconds between frames
These matrices were cropped, so have different dimensions than raw data; no need to worry about raw data size outside of "shared preparation example"
Analyze frames 10-30 from here with frame spacing of 2
Used for "workflow 1" and "workflow 2" and "workflow 3"

.h5 files can be found here: O:\Session 88\all ilastik prep files
File name structure is t<frame>_<name>_<channel>_E4_<string>.h5
Channel order corresponds to: outside, surface, inside (display to confirm)
Voxel spacing is [1.5 1.5 1.5]um dx dy dz
Files were trained on scaled down 560 channel data

The segmentations were trained on files found here: O:\Session 88\Exp 4 - Rmin Redo\2 Downscaled For Ilastik 8bit
Voxel spacing is [1.5 1.5 1.5]um dx dy dz



