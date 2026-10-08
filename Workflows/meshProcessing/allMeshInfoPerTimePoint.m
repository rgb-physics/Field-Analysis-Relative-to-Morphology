% This script searchs through all mesh .plys in a series of directories,
% returning the mesh centroids, volumes, areas, etc. and saving these in a
% dedicated struct .mat file in each folder
% motherDir = '<redacted original absolute path>';
motherDir = 'Session 12, Exp 4';
dataDirForm = 'plys';
timeRange = 1;
pixDim = .55; flipNorms = 1;

%% iterate and get info
%Iterate through time points
for currT = 1:numel(timeRange)
    
    fprintf('\nCurrent time... %i', timeRange(currT))
    
    %Load data for current time point
    currDir = fullfile(motherDir,sprintf(dataDirForm, timeRange(currT)));
    meshDirInfo = dir(fullfile(currDir,'*.ply'));
    
    %Load each object
     for currObj = 1:numel(meshDirInfo)
        
        meshObj = read_ply_mod(fullfile(currDir, meshDirInfo(currObj).name)) ;
        %Save info in table
        if currObj == 1
            allDataTable = getMeshDims(meshObj, pixDim, flipNorms); 
            allDataTable = repmat(allDataTable, numel(meshDirInfo,1));      %For preallocation
        else
            allDataTable(currObj,:) = getMeshDims(meshObj, pixDim, flipNorms); 
        end
        
    end
    
    %Save data in each subfolder
    save(fullfile(currDir, sprintf('meshInfoTime%0.6i.mat',timeRange(currT))), 'allDataTable');
    
end
