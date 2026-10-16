%% Real-data SegmentationTools experiments for visual inspection
% Run from MATLAB R2023a with Image Processing Toolbox.
% Edit these settings, then run the whole script. Each run creates a NEW
% temporary output folder; input fixtures are never modified.
% These are behavior checks and visual experiments, not scientific ground truth.

farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this saved script.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

semanticChannels = [1 3 2]; % ASSUMPTION: [inside wall outside]; confirm by eye!
probabilityThresholdSets = [0.5 0.5 0.5];
% probabilityThresholdSets = [0.2 0.5 0.5; 0.5 0.5 0.5; 0.7 0.7 0.7];
openingRadius = 1;          % voxels; inspect loss of thin walls
intensityThresholds = [0.2 0.4 0.6]; % fractions of each channel's min-max range
keepLargest = 3;
fillDirections = [0 1 2];  % 0=XY, 1=XZ, 2=YZ; independently filled and unioned
runDistanceCleanup = false; % enable only for verified isotropic data
distanceMean = 0; distanceWidth = 0; gaussianSigma = 0.5;
runSheetExperiment = false; % enable only if chosen mask contains two Z sheets
sheetSplitSlice = [];      % [] detects automatically (Signal Processing Toolbox)
sheetGapHalfWidth = 1;

%% Locate fixtures and create an output folder
testsDirectory = fileparts(mfilename('fullpath'));
repositoryRoot = fullfile(testsDirectory,'..','..','..');
addpath(fullfile(repositoryRoot,'tests'));
addpath(fullfile(repositoryRoot,'APIs','SegmentationTools','src'));
addpath(fullfile(repositoryRoot,'APIs','ImageStackIO','src'));
addpath(fullfile(repositoryRoot,'APIs','SharedUtilities','src'));
dataDirectory = farmTestDataRoot();
outputDirectory = tempname;
mkdir(outputDirectory);
fprintf('Visual-test outputs: %s\n',outputDirectory);
writeOptions = struct('Overwrite',false);
summary = struct('Source',{},'Experiment',{},'SelectedVoxels',{});
settings = struct('SemanticChannels',semanticChannels, ...
    'ProbabilityThresholdSets',probabilityThresholdSets, ...
    'OpeningRadius',openingRadius,'IntensityThresholds',intensityThresholds, ...
    'KeepLargest',keepLargest,'FillDirections',fillDirections, ...
    'RunDistanceCleanup',runDistanceCleanup,'DistanceMean',distanceMean, ...
    'DistanceWidth',distanceWidth,'GaussianSigma',gaussianSigma, ...
    'RunSheetExperiment',runSheetExperiment,'SheetSplitSlice',sheetSplitSlice, ...
    'SheetGapHalfWidth',sheetGapHalfWidth);

%% HDF5 probabilities: inspect channel identity BEFORE interpreting labels
% h5Path = fullfile(dataDirectory,'image-stacks','hdf5', ...
%     'inOnOut_3ChannelSegmentation_cropped.h5');
h5Path = fullfile(dataDirectory,'image-stacks','hdf5', ...
    'inOnOut_3Chan_Full_60x.h5');
% CYXZ is the layout documented for this specific fixture's MATLAB h5read.
h5Image = farmReadH5(h5Path,'/exported_data',struct('SourceAxes','CYXZ'));
probabilities = h5Image.Data(:,:,:,:,1);
assert(size(probabilities,4)==3,'Expected three probability channels.');
assert(all(isfinite(probabilities(:))) && all(probabilities(:)>=0) && ...
    all(probabilities(:)<=1),'Expected finite probabilities in [0,1].');
localWrite(uint16(double(probabilities)*65535),'h5_original_channels', ...
    outputDirectory,writeOptions);
% Specify which manipulations we wish to generate from input probabilities
classifyOptions = struct('ReturnLabelVolume',true,'ReturnMasks',true, ...
    'ReturnCandidateMasks',true,'ReturnOverlapMask',true, ...
    'ReturnUnclassifiedMask',true,'ReturnChangedVoxelMask',true, ...
    'CountComponents',true);
probabilityReports = cell(size(probabilityThresholdSets,1),1);
for experiment = 1:size(probabilityThresholdSets,1)
    thresholds = probabilityThresholdSets(experiment,:);
    prefix = sprintf('h5_threshold_set_%02d',experiment);
    result = farmSegmentInOnOutProbabilities( ...
        probabilities,semanticChannels,thresholds, ...
        struct('ClassifyOptions',classifyOptions));
    assert(~any(sum(result.Masks,4)>1,'all'),'Final masks must be disjoint.');
% channel IDs stored in voxels
    localWrite(result.LabelVolume,[prefix '_labels'],outputDirectory,writeOptions);
% Multi-channel with no more than one voxel selected per channel
    localWrite(result.Masks,[prefix '_inside_wall_outside'],outputDirectory,writeOptions);
% Multi-channel with allowing for multiple candidate voxels per channel
    localWrite(result.CandidateMasks,[prefix '_candidate_masks'],outputDirectory,writeOptions);
% Identify voxels that are multi-valued or excluded after thresholding
    localWrite(cat(4,result.OverlapMask,result.UnclassifiedMask, ...
        result.ChangedVoxelMask),[prefix '_overlap_unclassified_changed'], ...
        outputDirectory,writeOptions);
% Reassign 
    encoded = farmRemapClassLabels( ...
        result.LabelVolume,[1 2 3],[85 170 255]);
    localWrite(encoded,[prefix '_labels_85_170_255'],outputDirectory,writeOptions);
    [inside,wall,outside] = farmSmoothInOnOutProbabilities(probabilities,semanticChannels,thresholds, ...
        struct('OpeningRadius',openingRadius,'SpanSpace',false));
    localWrite(cat(4,inside,wall,outside),[prefix '_historical_opening'], ...
        outputDirectory,writeOptions);
    summary(end+1) = struct('Source','HDF5','Experiment',prefix, ...
        'SelectedVoxels',nnz(result.LabelVolume)); %#ok<SAGROW>
    probabilityReports{experiment} = struct('Thresholds',thresholds, ...
        'VoxelCounts',result.VoxelCounts,'ComponentCounts',result.ComponentCounts, ...
        'OverlapCandidates',nnz(result.OverlapMask), ...
        'Unclassified',nnz(result.UnclassifiedMask));
    % First setting supplies the cleanup example (inside mask).
    if experiment==1
        localCleanup(result.Masks(:,:,:,1),'h5_inside',outputDirectory, ...
            writeOptions,keepLargest,fillDirections,runDistanceCleanup, ...
            distanceMean,distanceWidth,gaussianSigma);
        sheetMask = result.Masks(:,:,:,2); % wall mask, only if sheet-like
    end
end
% Compare "add two fields then threshold" with "either field passes".
group = semanticChannels([1 2]);
sumMask = farmThresholdProbabilityGroup( ...
    probabilities,group,0.5,struct('CombineMethod','sum'));
unionMask = farmThresholdProbabilityGroup( ...
    probabilities,group,[0.5 0.5],struct('CombineMethod','union'));
localWrite(cat(4,sumMask,unionMask,xor(sumMask,unionMask)), ...
    'h5_inside_plus_wall_sum_union_difference',outputDirectory,writeOptions);

%% Intensity TIFFs: min-max scaling is for this threshold experiment only
% These channels are NOT class probabilities. Thresholds are fractions of
% the observed intensity range, and are sensitive to bright outliers.
tiffFiles = dir(fullfile(dataDirectory,'image-stacks','tiff','*.tif*'));
intensityRanges = struct('File',{},'Channel',{},'Minimum',{},'Maximum',{});
tifOptions = struct('SourceAxes','YXZ');
tifOptions.SourceAxes = 'YXZ';
for fileIndex = 1:numel(tiffFiles)
    inputPath = fullfile(tiffFiles(fileIndex).folder,tiffFiles(fileIndex).name);
    image = farmReadTiff(inputPath,tifOptions); % honor channel/time metadata
    [~,stem] = fileparts(inputPath);
    for channel = 1:size(image.Data,4)
        raw = image.Data(:,:,:,channel,1); % first time point
        assert(all(isfinite(raw(:))),'Intensity input contains nonfinite values.');
        low = double(min(raw(:))); high = double(max(raw(:)));
        scaled = (double(raw)-low)/max(high-low,eps);
        prefix = sprintf('%s_ch%02d',stem,channel);
        localWrite(uint16(scaled*65535),[prefix '_intensity_preview'], ...
            outputDirectory,writeOptions);
        intensityRanges(end+1) = struct('File',inputPath,'Channel',channel, ...
            'Minimum',low,'Maximum',high); %#ok<SAGROW>
        for experiment = 1:numel(intensityThresholds)
            threshold = intensityThresholds(experiment);
            mask = farmImbinarize3_4D(scaled,threshold);
            maskName = sprintf('%s_threshold_%02d',prefix,experiment);
            localWrite(mask,maskName,outputDirectory,writeOptions);
            summary(end+1) = struct('Source',tiffFiles(fileIndex).name, ...
                'Experiment',maskName,'SelectedVoxels',nnz(mask)); %#ok<SAGROW>
            % Middle threshold supplies each channel's cleanup comparison.
            if experiment==ceil(numel(intensityThresholds)/2)
                localCleanup(mask,maskName,outputDirectory,writeOptions, ...
                    keepLargest,fillDirections,runDistanceCleanup, ...
                    distanceMean,distanceWidth,gaussianSigma);
            end
        end
    end
end

%% Optional sheet experiment: unsuitable masks may correctly raise an error
if runSheetExperiment
    sheetOptions = struct('SplitSlice',sheetSplitSlice, ...
        'GapHalfWidth',sheetGapHalfWidth,'Connectivity',26);
    [top,bottom,~,~,removed,~,split] = farmReturnTopBottom2DSheetsConfigurable(sheetMask,sheetOptions);
    localWrite(cat(4,top,bottom,removed),'h5_sheets_top_bottom_cut', ...
        outputDirectory,writeOptions);
    fprintf('Sheet split Z index: %d\n',split);
end

%% Save small reports; the image arrays remain available in the workspace
save(fullfile(outputDirectory,'experiment_settings_and_reports.mat'), ...
    'settings','probabilityReports','intensityRanges','summary');
writetable(struct2table(summary),fullfile(outputDirectory,'voxel_counts.csv'));
disp(struct2table(summary));
fprintf('Open TIFFs in FIJI or MATLAB. Output folder:\n%s\n',outputDirectory);


%% Additional functions
function localWrite(data,name,folder,options)
path = fullfile(folder,[name '.tif']);
farmWriteMaskTiff(data,path,options);
roundTrip = farmReadProbabilityTiff(path);
assert(isequal(double(roundTrip),double(data)),'TIFF round trip failed: %s',name);
end

function localCleanup(mask,prefix,folder,options,keep,axesToFill,doDistance,meanD,width,sigma)
[retained,removedPixels] = farmRemoveConObjs(mask,keep,'large');
removed = false(size(mask)); removed(removedPixels) = true;
localWrite(cat(4,mask,retained,removed),[prefix '_original_retained_removed'],folder,options);
for axis = axesToFill
    filled = farmFlatFill3D(mask,axis);
    localWrite(cat(4,mask,filled,filled & ~mask), ...
        sprintf('%s_fill_axis_%d_original_filled_added',prefix,axis),folder,options);
end
filled = farmFlatFill3D(mask,axesToFill);
localWrite(filled,[prefix '_fill_all_selected_axes'],folder,options);
if doDistance
    smooth = farmReturnSmoothBlobsBW(mask,meanD,width,sigma);
    localWrite(cat(4,mask,smooth,xor(mask,smooth)), ...
        [prefix '_distance_original_smoothed_changed'],folder,options);
    labels = uint16(bwlabeln(retained));
    fast = farmReturnSmoothBlobsIDed(labels,meanD,width,sigma,'fast');
    slow = farmReturnSmoothBlobsIDed(labels,meanD,width,sigma,'slow');
    localWrite(cat(4,labels,fast,slow),[prefix '_IDs_original_fast_slow'],folder,options);
end
end
