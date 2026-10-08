% Takes in a 5D nd2 file with dimensions height, width, channel, and two
% further layers (eg. z and t). Note that this can be used even in the
% event that there is only a single channel. All that matters is that there
% are two additional layers.
%% Data info
% nd2Dir = '<redacted original absolute path>';
nd2Dir = 'Session 74';
nd2Name = '3_1340_20x_2x2_1in30fps_1p1umZ_photometrics95b003.nd2';
FileName = fullfile(nd2Dir, nd2Name);
saveDir = nd2Dir;

displayBool = 0;
% width axis is always x,y, or custom vector of indices
% Height is a layer, depth is a layer
% Iterate over channels
% Run this to find which dimension is which
[dimLens,dimTable] = rem_ND2Dims(FileName, displayBool);

selChans = [1 2];
% Assign dimensions of output tif
% dim1
dim2 = 5;           % layer index
dim3 = 4;           % layer index

% Number of layers is number of dims w/o x,y,c
numLayers = numel(dimLens) - 3;

%% Generate xy sample indices
% If dim1 == 0, use custom inds
% If dim2 < dim1, transpose final 


% Transpose correction: always iterate


