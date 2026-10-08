%% This script takes in .h5 files and applies active contouring to generate
%a point cloud illustrating the interface between channels

% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 25, Exp 5';
h5NameForm = 'Time%06i_acOpt_Probabilities Stage 2.h5';
selectTimes = 3;
chanSel = 2;            %Pick channel such that MTs are prob 1 and bg prob 0
cutOffVal = 100/255;

%% Load File
currData = h5read(fullfile(h5Dir,sprintf(h5NameForm,selectTimes(1))),'/exported_data');
%Load data set 1
selectData = permute(squeeze(currData(chanSel,:,:,:)),[2 1 3]);
BWDATA = imbinarize(selectData,cutOffVal);
%Load data set 2
flipData = 1-BWDATA;

%% Generate Guess
centerGuess = zeros(size(selectData));
centerGuess(:,:,round(size(centerGuess,3)/2)) = 1;

%% Apply active contouring
% tic
% test = activecontour(selectData,centerGuess,600);
% toc

%% Get z layer with least protein
sumZ = sum(BWDATA, [1 2]);
[~, sliceCands] = findpeaks(squeeze(-sumZ));
[~,splitSliceInd] = min( abs(round(size(selectData,3)/2) - sliceCands));
splitSlice = sliceCands(min(splitSliceInd));

%% Artifically set layer to 0
cutData =BWDATA;
cutData(:,:,(splitSlice-2):(splitSlice+2)) = 0;

%% Top Guess
[~, layerSliceCands] = findpeaks(squeeze(sumZ));
[~,topSplitSliceInd] = min( (round(size(selectData,3)/2) - layerSliceCands));
[~,botSplitSliceInd] = max( (round(size(selectData,3)/2) - layerSliceCands));
topGuess = zeros(size(BWDATA));
botGuess = zeros(size(BWDATA));
topGuess(:,:,topSplitSliceInd) = 1;
botGuess(:,:,botSplitSliceInd) = 1;

%% Contouring
topCont = activecontour(double(cutData),topGuess,80);
botCont = activecontour(double(cutData),botGuess,80);

