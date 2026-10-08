% This script returns slices of nd2s along requested dimensions from data
% with x,y,z,t and channel data. 
% 06/29/2023 - 07/19/2023
%% Directory info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 74';
dataName = '3_1340_20x_2x2_1in30fps_1p1umZ_photometrics95b003.nd2';
FileName = fullfile(dataDir,dataName);

SavePath = fullfile(dataDir);
selChans = [1 2];       % Only support for one channel at a time for now
% cutDim = 1 corresponds to single x value (column cut), cutDim = 2 is y
% cutDim = 1;
cutInd = 100;   %Note one can pass lineStart and lineEnd variables to define a truncated line
% Set of indices in matrix of x,y to be sampled
% cutDim = 1 samples select rows, cutDim = 2 samples select cols
cutDim = 1;    sampVals = 6;

% Run this to find which dimension is which
displayBool = 0;
[dimLens,dimTable] = rem_ND2Dims(FileName, displayBool);

sampInds = genLineInds2D([dimLens(1) dimLens(2)],cutInd,cutDim);

%% Open reader object
[FilePointer, ImagePointer, ImageReadOut] = ND2Open(fullfile(dataDir,dataName));

%% 
    [ImageInfo] = ND2Info(FileName,displayBool);
    [rowMat,colMat] = ndgrid(1:(ImageReadOut.uiWidth), 1:(ImageReadOut.uiHeight));

    if cutDim == 1
        sampInds = rowMat == sampVals;
    elseif cutDim == 2
        sampInds = colMat == sampVals;
    end
    
    % Channel indices
    ChannelNum = dimLens(3);
    ChannelIndex = 1:ChannelNum;
    % Other layer indices
    offDims = dimLens(4:end);
    % Explicitly for data with two off dims, like z and t
    ImageIndex = reshape(1:ImageInfo.numImages, dimLens(4:end));
    [mat1, mat2] = meshgrid(1:dimLens(4), 1:dimLens(5));


%% 
% For naming
    Tag = char(datetime('now', 'format', '-HH-mm-ss'));
    Layer0Index = 1:ImageInfo.Experiment(1).count;
    Layer1Index = 1:ImageInfo.Experiment(2).count;
    ImageIndex = reshape(1:ImageInfo.numImages, [ImageInfo.Experiment(2).count, ImageInfo.Experiment(1).count]);

%% Iterate through layers
% all
for ind0 = Layer0Index

    for sliceInd = Layer1Index

        % Select 2D slice in all channels, then (dim,dim0), where dim0 and
        % dim1 correspond to non-x,y orthogonal coordinates like z or t
        [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', ...
            FilePointer, uint32(ImageIndex(sliceInd, ind0) - 1), ImagePointer);
        
        % Reshape the slice
        Image = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);

        selVals = Image(selChans,sampVals);

        % Iterate through channels (lambda)
        for k = 1:size(ChannelIndex(:), 1)

            Original_Image = reshape(Image(ChannelIndex(k), :), [ImageReadOut.uiWidth, ImageReadOut.uiHeight])';

        end

    end

    DisplayBar(ind0, size(Layer0Index(:), 1));
end
disp('--------------------------------------------------------------------------------')
ND2Close(FilePointer);
clear('FilePointer')

    %% OTHER %%%%%%%
    tic
    allInds = zeros(offDims(mod1b(cutDim+1,2)),sum(sampInds(:)),numel(selChans));
    for sliceInd = LayerIndex
        
        % Select 2D slice in all channels, then (dim,dim0), where dim0 and
        % dim1 correspond to non-x,y orthogonal coordinates like z or t
        % Explicitly for data with two off dims, like z and t
        [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', ...
            FilePointer, uint32(ImageIndex(ind1, ind0) - 1), ImagePointer);
        
        % Reshape the slice
        Image = reshape(ImageReadOut.pImageData, [ImageReadOut.uiComponents, ImageReadOut.uiWidth * ImageReadOut.uiHeight]);

        selVals = Image(selChans,sampInds);
        allInds(sliceInd,:,:) = reshape(selVals', [ 1, size(selVals,2), size(selVals,1)]);
    end

    disp('--------------------------------------------------------------------------------')
    ND2Close(FilePointer);
    clear('FilePointer')
    toc
        %% Only necessary if incorporating old file names into new
%     TifFileName = cell(0);
%     for i = 1:ChannelNum
% 
%         for j = 1:ImageInfo.Experiment(2).count
%             TifFileName{i}{j} = [SavePath, Name, Tag, '_', ...
%                 ImageInfo.metadata.channels(i).channel.name, '_' ImageInfo.Experiment(2).type, '_', num2str(j), '.tif'];              
%         end
% 
%     end