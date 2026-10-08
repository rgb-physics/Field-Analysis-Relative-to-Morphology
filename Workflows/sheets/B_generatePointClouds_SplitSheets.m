%% Takes in a directory and name type of structures containing indices of sheets
% Run this after running A_identifyFromH5_2DSheets.m
% NOTE: This script runs python scripts through MATLAB and requires access
% to MeshLab. The script expects both the selected meshlab script
% (funcName) and python script to run said meshlab script (ply2Mesh) to be
% in the same folder (scriptDir). 
% Rémi Boros

% structDir = '<redacted original absolute path>';
structDir = 'Session 28, Exp 6';
structName = 'Time%06i_regionsStruct.mat';
% plyDir = '<redacted original absolute path>';
plyDir = 'Session 28, Exp 6';
% meshDir = '<redacted original absolute path>';  
meshDir = 'Session 28, Exp 6';  
saveName = '%s_vertices_t%03i_test.ply';
timeSelect = 120:200;

% scriptDir = '<redacted original absolute path>';
scriptDir = '';
ply2Mesh = 'batch_pointCloud2Mesh - MATLABexec.py';     % Python script to run meshlab
funcName = 'Ray_PointCloud2Mesh_ScreenedPoisson.mlx';   % For meshlab analysis

addpath(scriptDir);

%% Load and save split layers as plys
strelObj = strel('sphere',1);
for tInd = 1:numel(timeSelect)

    currT = timeSelect(tInd);
    
    load(fullfile(structDir,sprintf(structName,currT)));
    topLayer = imdilate(outputStruct.topInds,strelObj) & outputStruct.center;
    logic2Ply(topLayer, fullfile(plyDir,sprintf(saveName,'topLayer',currT)));
    
    botLayer = imdilate(outputStruct.botInds,strelObj) & outputStruct.center;
    logic2Ply(botLayer, fullfile(plyDir,sprintf(saveName,'botLayer',currT)));

end

%% Save "flat" tubes
% Cap the two sheets to make an effective hollow "droplet"
capDim = 1;

for tInd = 1:numel(timeSelect)
    
    currT = timeSelect(tInd);
    load(fullfile(structDir,sprintf(structName,currT)));
    
    topLayer = imdilate(outputStruct.topInds,strelObj) & outputStruct.center;
    botLayer = imdilate(outputStruct.botInds,strelObj) & outputStruct.center;
    
    cappedLayers =  capPtCloudFlat(topLayer, botLayer,capDim);
    logic2Ply(cappedLayers, fullfile(plyDir,sprintf(saveName,'FlatCapBoth',currT)));

end

%% Run meshlab through python through matlab
scriptLoc = fullfile(scriptDir, ply2Mesh);
funcLoc = fullfile(scriptDir, funcName);
pyrunfile(scriptLoc, dataDir = plyDir, saveDir = meshDir, scriptName = funcLoc)


