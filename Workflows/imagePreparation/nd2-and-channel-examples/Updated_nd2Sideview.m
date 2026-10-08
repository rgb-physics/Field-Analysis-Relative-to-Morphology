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
% dataDirs = {'<redacted original absolute path>'};
dataDirs = {'Session 79'};
displayBool = 0;
dim2Layer = 5;   
dim3Layer = 4;   

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
saveName = [dataName(nameInd).name(1:7) '%s_%s_Reslice_Chan%i.tif'];
layerLens = dimLens(4:end); 

% Select "ranges" for each dimension
% This includes channel selection. Channel as a unique dimension is not
% supported here. Dimension 1 is always expected to be a vector of unique
% scalars corresponding to indices of a 2D matrix with the dimensions of
% the xy image plane. 
% Select lambda channels
selLambdas = 1:table2array(dimTable(3,2));
% Assign .nd2 layers to dimensions of your output .tif
% Layers are expected to be 1-indexed
% Support for 2 or 3 layers (stacks for each lambda must be >3D and <6D)
dim2Range = 5:dimLens(dim2Layer); 
dim3Range = 6:dimLens(dim3Layer);
% dim2Layer = 7;   dim2Range = 1:dimLens(dim2Layer); 
% dim3Layer = 4;   dim3Range = 1:dimLens(dim3Layer);
% Select ranges of indices; for now, one of the following vars must be a
% single scalar.
heightVals = 1:dimLens(1);
widthVals = round(dimLens(2)/2);

% Generate vector of xy indices, single-valued along x or y
indMat = reshape(1:dimLens(1)*dimLens(2),[dimLens(1) dimLens(2)]);
xyInds = indMat(heightVals, widthVals);
% Generate vector of indices corresponding to appropriate xy slices from
% which to be sampled.
% NOTE: data in .nd2 files is structured as a library of 1D arrays. Each
% contains the channel, x, and y intensity data corresponding to a given
% set of layer values (eg. t = 40, z = 55). This can be reshaped into a
% (number of channels) x (number of pixels) array; in turn, each row of
% said array can be reshaped into a 2D image with height and width of the
% native .nd2 in question, corresponding to a 2D image in a single channel

% Ensure that neither selected coordinate is x,y, or c
baseVec = 4:numel(layerLens);
permVec = [dim2Layer dim3Layer baseVec(~ismember(baseVec, [dim2Layer dim3Layer]))]-3;
[~,antiPermVec] = sort(permVec);

% Generate cell array with ranges over all layers
rangeCell = num2cell(ones(1,numel(layerLens)));
rangeCell{1} = dim2Range;   rangeCell{2} = dim3Range;
% Need custom input for ranges of other layers; by default, other layer
% ranges are set to 1
% 
% Ask user to update cell input?
% Get minima of ranges and maxima of ranges and sort
rangeBounds = zeros(2,numel(layerLens));
rangeLens = zeros(1,numel(layerLens));
for currLayer = 1:numel(layerLens)
    rangeBounds(1,currLayer) = min(rangeCell{currLayer});
    rangeBounds(2,currLayer) = max(rangeCell{currLayer});
    rangeLens(currLayer) = numel(unique(rangeCell{currLayer}));
    rangeCell{currLayer} = sort(rangeCell{currLayer});
end

%% Open reader object
[FilePointer, ImagePointer, ImageReadOut] = ND2Open(currData);

%% sculpt for loops
% Iterate through all layer indices; outer most loops are for separate tifs
% while the innermost and second innermost iterate over dim3layer and
% dim2layer, respectively
tic
baseMat = zeros(numel(dim2Range),numel(xyInds),numel(selLambdas)); 
loopNum = numel(layerLens);             % Number of loops
indVec = ones(1,numel(layerLens));      % Index vector used to track progress
currInd = rangeBounds(1,:);             % Current layer index, starts at range minima
isReady = false;                        % Looping boolean
while ~isReady
    isReady = true;       % Assume that the WHILE loop is ready to move on
    % Loop through each layer while tracking loop indices
    for loopIndex = 1:loopNum
        % Update index vector
        indVec(loopIndex) = indVec(loopIndex) + 1;
        % Check if the end of current loop has been reached
        if indVec(loopIndex) <= rangeLens(loopIndex) + 1
            % Get the index of the current layer from which to access data
            % NOTE: layers are stored in "opposite" order than order listed
            orderedLayerCoord = num2cell(fliplr(currInd(antiPermVec)));
            currLayerIndex = sub2ind(fliplr(layerLens),orderedLayerCoord{:});        
     %%%%%%%% Tasks based on loop depth, specific for side slices: %%%%%%%%
            % In innermost loop, store data from queried channels in 
            % 3D array ( x dim2 channel )
            if loopIndex == 1          
                [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', FilePointer, (currLayerIndex - 1), ImagePointer);
                LinImage = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);
                baseMat(indVec(loopIndex)-1,:,:) = LinImage(selLambdas,xyInds)';
            % In secondmost, iterate over channels and save/append 2D slice
            elseif loopIndex == 2
                % Convert to data type matching original .nd2 (bit-depth)
                baseMat = cast(baseMat,class(LinImage));    
                % Iterate over channel data
                for currChan = 1:numel(selLambdas)
                    currSaveDir = fullfile(saveDir,sprintf(saveName,...
                        cell2mat(dimTable{dim2Layer,1}),cell2mat(dimTable{dim3Layer,1}),selLambdas(currChan)));
                    % Save 2D slices
                    if indVec(loopIndex) == 2
                        imwrite(baseMat(:,:,currChan), currSaveDir);
                    else
                        imwrite(baseMat(:,:,currChan), currSaveDir, 'WriteMode', 'append')
                    end
                end
            % For all higher level loops, save new 3D tifs using recurrent
            % structure above
            else

            end
            % Update current index for next loop
            currInd(loopIndex) = rangeCell{loopIndex}(min(indVec(loopIndex)-1,layerLens(permVec(loopIndex))));
            isReady = false;
            % End for loop and return to while loop with updated index 
            break;         
        end
      % Reset current index, then move "out" 1 loop layer. Equivalent to
      % resetting current for loop after incrementing outer loop index
      indVec(loopIndex) = 1;     
      currInd(loopIndex) = rangeBounds(1,loopIndex);
    end
end
fclose all;    % clean up
toc
end
end
end
