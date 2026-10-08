%% This script takes in .h5 files, looks for and finds 2 parallel sheets of protein, and saves the output as tifs at the detected boundaries
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 28, Exp 6';
h5NameForm = 't%03i_illCorr8bit_Probabilities Stage 2.h5';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 28, Exp 6';
imgFile = 't%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveNameForm = "Time%06i_regionsStruct.mat";
selectTimes = 254:1:292;
chanSel = 2;            %Pick channel such that MTs are prob 1 and bg prob 0
cutOffValStart = 100/255;
cutPerimeter = 0;

%% Define save directories
if  ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

%% Generate strel erosion objects
strelObj = strel("sphere", 1);
%% Iterate over all selected time points
for currT = 1:numel(selectTimes)

    %% Load Probability File - .8s
    currProbs = h5read(fullfile(h5Dir,sprintf(h5NameForm,selectTimes(currT))),'/exported_data');
    %Load data set 1
    selectProbs = double(permute(squeeze(currProbs(chanSel,cutPerimeter+1:end-cutPerimeter,cutPerimeter+1:end-cutPerimeter,:)),[2 1 3]));
    %Binarize segmentation weights
    BWProbs = imbinarize(selectProbs,cutOffValStart);
    %Generate operation matrices to be used in all frames
    if currT == 1
        [xMat,yMat,zMat] = ndgrid(1:size(selectProbs,1), 1:size(selectProbs,2), 1:size(selectProbs,3));
        boundMat = circshift(consMatLnB(true(size(selectProbs,1),size(selectProbs,2),size(selectProbs,3)+2), find(true(size(selectProbs)))),1,3);
    end
    
    %% Load tiff - .3s
    currTif = tiffreadVolume(fullfile(imgDir,sprintf(imgFile,selectTimes(currT))));
    
    %% Identify top and bottom layers and generate references matrices - 2.1s
    [topLayer,botLayer,topLayerZs,botLayerZs,~,~,splitSlice] = returnTopBottom2DSheets(BWProbs);
    topProbs = consMatLnB(selectProbs, ~(zMat>splitSlice)); botProbs = consMatLnB(selectProbs, zMat>splitSlice);
    
    %% Display progress
    if mod(currT,10) == 1
        fprintf("Current frame: %i... Current split Z slice: %i...\n", selectTimes(currT),splitSlice);
    end
    
    %% Patch truncated portions - 2.3s
    %Get indices of outer boundary along z for top layer
    topOutside = consMinValsLayer(topLayerZs,3);
    %Fill in outer boundary and return patched surface
    patchedTopProbs = consPatchedSheetSurface_Flat(selectProbs,topLayer,topOutside);
    
    %Get indices of outer boundary along z for bottom layer
    botOutside = max(botLayerZs,[],3);
    %Fill in outer boundary and return patched surface
    patchedBotProbs = consPatchedSheetSurface_Flat(selectProbs,botLayer,botOutside);
    
    %% Normalize probabilities in top and bottom portions by patched sheet maxima - .3s
    %Scale probabilities by scaling matrices generated using consScalerMat
    normTopData = bsxfun(@rdivide, topProbs, consScalerMat(topProbs,patchedTopProbs));
    normBotData = bsxfun(@rdivide, botProbs, consScalerMat(botProbs,patchedBotProbs));
    
    %% Rebinarize using cutoffvalue - .2s
    binTop = consMatLnB(normTopData, imbinarize(normTopData,cutOffValStart));
    binBot = consMatLnB(normBotData, imbinarize(normBotData,cutOffValStart));
    
    %% Stitch floating objects to layers, if they connect - .9s
    %Get layers and indices of all other disconnected objects
    [topLayerPatch,topDiscInds] = removeConObjs(logical(binTop),1,"large");     
    [botLayerPatch,botDiscInds] = removeConObjs(logical(binBot),1,"large");
    %Stitch layers to disconnected objects from other layers, then keep only
    %largest object (layer + reconnected sections/objects)
    topCorrInds = removeConObjs(logical(topLayerPatch) | consMatLnB(true(size(topLayerPatch)),botDiscInds), 1, "large");
    botCorrInds = removeConObjs(logical(botLayerPatch) | consMatLnB(true(size(botLayerPatch)),botDiscInds), 1, "large");
    
    %% Smooth layers - .1s
    %Dilate and erode layers, erode and dilate negatives
    smoothTop = imerode(imdilate( topCorrInds, strelObj), strelObj);
    smoothBot = imerode(imdilate( botCorrInds, strelObj), strelObj);
    smoothTopInv  = ~imdilate(imerode( ~topCorrInds, strelObj), strelObj);
    smoothBotInv  = ~imdilate(imerode( ~botCorrInds, strelObj), strelObj);
    %Combine erosion dilation outputs
    finTopInds = smoothTop | smoothTopInv; finBotInds = smoothBot | smoothBotInv;
    
    %% Fill holes through layers using cumulative sum, logic, and bwconncomp - 1s
    %Get cumsum of each layer pointing outward and remove layers
    topTruncObjs = logical(logical(cumsum(finTopInds,3)) - finTopInds);
    botTruncObjs = logical(logical(cumsum(finBotInds,3,'reverse')) - finBotInds);
    %Remove all small objects and set remainder as center volume
    [centerRegion, resInds] = removeConObjs(~(~botTruncObjs | ~topTruncObjs),1,"large");
    
    %% Get indices of all pixels outside of protein layer - .1s
    %Define residues and split between top and bottom layers
    allResidues = consMatLnB(true(size(selectProbs)),resInds);
    topLayerStitched = xor( ~(zMat>splitSlice), finTopInds );
    topResidues = topLayerStitched & allResidues; botResidues = ~topLayerStitched & allResidues;
    allButOut = centerRegion | finTopInds | finBotInds;
    %Define truncated regions as outsides with appropriate residues
    topOuter = ~logical(cumsum(allButOut,3)) | topResidues;
    botOuter = ~logical(cumsum(allButOut,3,'reverse')) | botResidues;
    
    %% Save indices of regions - 1.3s
    %Instantiate structure
    outputStruct = struct();
    %Store regions in structure
    outputStruct.topOut = topOuter; outputStruct.botOut = botOuter;
    outputStruct.center = centerRegion;
    outputStruct.topInds = finTopInds; outputStruct.botInds = finBotInds;
    %Store parameters in structure
    outputStruct.channel = chanSel; outputStruct.cutoff = cutOffValStart; outputStruct.cutPerim = cutPerimeter;
    %Save structure
    currSaveName = sprintf(saveNameForm, selectTimes(currT));
    save(fullfile(saveDir,currSaveName), 'outputStruct')

end
