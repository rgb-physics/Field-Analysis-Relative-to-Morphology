%% Directory info
% Assume directories are split into subdirectories by time point
% motherDir = '<redacted original absolute path>';
motherDir = 'Session 11, Exp 7';
subFolderForm = 'Time %0.6i';
% Mesh object data is assumed to be stored in a table generated with
% allMeshInfoPerTimePoint.m, one table per time point
dataForm = 'meshInfoTime%0.6i.mat';
timeRange = 1:41;

%% Using MATLab external library simple simpletracker: https://www.mathworks.com/matlabcentral/fileexchange/34040-simpletracker
% Convert tables into "points" cell array for function

points = cell(numel(timeRange), 1);
for currT = 1:numel(timeRange)
    
    currDir = fullfile(motherDir, sprintf(subFolderForm, timeRange(currT)));
    dataInfo = load(fullfile(currDir, sprintf(dataForm,timeRange(currT))));
    dataName = fieldnames(dataInfo);
    currData = dataInfo.(dataName{1});
    points{currT} = currData.Centroid;
    
end

%% Generate tracjetories

[ tracks, adjacency_tracks, A ] = simpletracker(points);
% [ tracks, adjacency_tracks, A ] = simpletrackerRevamp(points);
