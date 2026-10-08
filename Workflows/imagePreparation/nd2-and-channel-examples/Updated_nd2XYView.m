% ADAPTED from nd2Sideview; explicitly used for generating 3D tifs, one for
% each channel, of x-y-t for a selected slice z. 
% This script returns slices of nd2s along requested dimensions from data
% with x,y,z,t and channel data. By default, the pipeline will generate a
% series of 3D tifs. Each tif is sampled from a different channel, each
% selected by the user. The dimensions of each tif are 
%
% (select indices in xy plane) x (range of layer i) x (range of layer j)
%
% The user is prompted to sample the dimensions of the nd2 of interest.
% Then the user is expected to input the range over which to sample each
% dimension and which layer to assign to each sample. 
% The script supports nd2s with 1-3 layers (eg. z, t, xy positions)
% 06/29/2023 - 08/31/2023

%% Instantiate file info
% Directory info
% % 'Session 37',...
% 'Session 38',...
%     'Session 39',...
%     'Session 40',...
%     'Session 41',...
% 'Session 42',...
%     'Session 43',...
%     'Session 44',...
%     'Session 45',...
%     'Session 46',...
%     'Session 47',...
%     'Session 48',...
%     'Session 50',...
%     'Session 51',...
%     'Session 52',...
%     'Session 53',...
%     'Session 54',...
% %     'Session 55',...
% dataDirs = {'Session 56',...
%     'Session 57'};
% dataDirs = {'Session 78'};
% dataDirs = {'Session 79'};
% dataDirs = {'<redacted original absolute path>',...
dataDirs = {'Session 80',...
    % '<redacted original absolute path>',...
    'Session 81',...
    % '<redacted original absolute path>',...
    'Session 82',...
    % '<redacted original absolute path>',...
    'Session 83',...
    % '<redacted original absolute path>',...
    'Session 84',...
    % '<redacted original absolute path>',...
    'Session 85',...
    % '<redacted original absolute path>',...
    'Session 87',...
    % '<redacted original absolute path>'};
    'Session 88'};
displayBool = 0;
zDim = 5;       % dimension of the .nd2 corresponding to z
tDim = 4;       % "                                 " to t
% The higher the dimension number,the deeper the for loop nest
combBool = 1;

for dataInd = 1:numel(dataDirs)
dataDir = dataDirs{dataInd};

dataName = dir(fullfile(dataDir,'*.nd2'));

for nameInd = 1:numel(dataName)
% Define current directory info
currData = fullfile(dataDir,dataName(nameInd).name);
saveDir = fullfile(dataDir);

% Get the dimensions of the current .nd2
[dimLens,dimTable] = rem_ND2Dims(currData, displayBool);
if numel(dimLens) ~= 5
    disp(currData)
else
saveName = [dataName(nameInd).name(1:7) '%s_%s_Reslice_CombChans.tif'];
layerLens = dimLens(4:end);

% Select ranges of x-y indices
heightVals = 1:2:dimLens(1);
widthVals = 1:2:dimLens(2);
% Below are Z and T ranges; one must be a scalar, the other a range
% dimTRange = round(dimLens(tDim)/2);
% dimZRange = 1:dimLens(zDim);      
dimZRange = round(dimLens(zDim)/2);
dimTRange = 1:dimLens(tDim);      
% Select lambda channels
selLambdas = 1:table2array(dimTable(3,2)); 
% Define height and width of output image (important if cropping)
outHeight = numel(heightVals);  outWidth = numel(widthVals);
% Define depth of z range and time range
zDepth = numel(dimZRange);      tDepth = numel(dimTRange);     

% Ensure that neither selected coordinate is x,y, or c
baseVec = 4:numel(layerLens);
permVec = [zDim tDim baseVec(~ismember(baseVec, [zDim tDim]))]-3;
% Permutation vector ensures t,z order
[~,antiPermVec] = sort(permVec);
% Output will be a 3D stack with the third dimension corresponding to the
% dimension with non-scalar range
% Generate vector of xy indices, single-valued along x or y
indMat = reshape(1:dimLens(1)*dimLens(2),[dimLens(1) dimLens(2)]);
xyInds = indMat(heightVals, widthVals)';

% Generate vector of indices corresponding to appropriate xy slices from
% which to be sampled.
% NOTE: data in .nd2 files is structured as a library of 1D arrays. Each
% contains the channel, x, and y intensity data corresponding to a given
% set of layer values (eg. t = 40, z = 55). This can be reshaped into a
% (number of channels) x (number of pixels) array; in turn, each row of
% said array can be reshaped into a 2D image with height and width of the
% native .nd2 in question, corresponding to a 2D image in a single channel
% Generate cell array with ranges over all layers
% Select "ranges" for each dimension
% This includes channel selection. Channel as a unique dimension is not
% supported here. Dimension 1 is always expected to be a vector of unique
% scalars corresponding to indices of a 2D matrix with the dimensions of
% the xy image plane. 
% Assign .nd2 layers to dimensions of your output .tif
% Layers are expected to be 1-indexed
inLoopDim = max(zDim,tDim);             outLoopDim = min(zDim,tDim);
inLoopLen = dimLens(inLoopDim);         outLoopLen = dimLens(outLoopDim);
ZTIndMat = reshape(1:(inLoopLen*outLoopLen),[inLoopLen outLoopLen]);
% Sub-selected .nd2 indices based on z-t order
if zDim > tDim
    loopIndices = ZTIndMat(dimZRange,dimTRange);
else
    loopIndices = ZTIndMat(dimTRange,dimZRange);
end

%% Open reader object
[FilePointer, ImagePointer, ImageReadOut] = ND2Open(currData);

%% Non-specific nested for loops
if combBool == 1
    baseMat = zeros(outHeight,outWidth,numel(selLambdas),zDepth,tDepth);  % Dimension of a single slice
end
for layerInd = 1:numel(loopIndices)
    % Read data
    currLayerIndex = loopIndices(layerInd);
    [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', ...
        FilePointer, currLayerIndex - 1, ImagePointer);
    LinImage = reshape(ImageReadOut.pImageData, ...
        [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);
    % Iterate over each channel
    for chanInd = 1:numel(selLambdas)
        currChan = selLambdas(chanInd);
        currSaveDir = fullfile(saveDir,sprintf(saveName,...
                        cell2mat(dimTable{zDim,1}),cell2mat(dimTable{tDim,1})));
        Image2D = reshape(LinImage(currChan,xyInds),[outHeight outWidth 1]);
        Image2D = cast(Image2D,class(LinImage));
        % If not combining channels, save separately
        if combBool == 0
            % Save 2D slices (separate tifs for each channel)
            if layerInd == 1
                imwrite(Image2D, currSaveDir);
            else
                imwrite(Image2D, currSaveDir, 'WriteMode', 'append')
            end
        % If combining channels, store a stack of [x y c z t]; save later
        else
            [currZ,currT] = ind2sub(size(ZTIndMat),currLayerIndex);
            zStoreInd = find(ismember(dimZRange,currZ));
            tStoreInd = find(ismember(dimTRange,currT));
            baseMat(:,:,chanInd,zStoreInd,tStoreInd) = Image2D;
        end
    end                 
end
% Convert to uint16, then save multichannel tiff for fiji
baseMat = cast(baseMat,class(LinImage));
if combBool == 1
    saveNDTiffFIJI(baseMat,currSaveDir);
end
fclose all;

end
end
end

