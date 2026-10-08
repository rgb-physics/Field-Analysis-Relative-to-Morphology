% Takes in directories of aLENS filament clusters (3D) and IDed filaments
% (3D) and stores associated quantities

% expIndex = 11;
allInds = 2:16;

for index = 1:numel(allInds)

    expIndex = allInds(index);

% baseDir = fullfile('<redacted original absolute path>',...
baseDir = fullfile('',...
    sprintf('%i',expIndex), '3Width Convolution - Psqrd and sqrtQ');
filDir = fullfile(baseDir,'IDed Filaments');
clusterDir = fullfile(baseDir,'Filament Clusters');
mtProps = 'T%06i_mtProps.mat';
motorProps = 'T%06i_motorProps.mat';
filName = 'Time%06i_IDedFilaments.tif';
clusterName = 'T%06i_clusterIDs.tif';

selTimes = 1:399;
clusterFields = {'Volume','Centroid','VoxelIdxList'};

%% Iterate over time, save properties
for tInd = 1:numel(selTimes)

    % Load
    currT = selTimes(tInd);
    if ~isfile(fullfile(filDir,sprintf(filName,currT)))
        continue
    end
    loadFils = tiffreadVolume(fullfile(filDir,sprintf(filName,currT)));
    loadClusters = tiffreadVolume(fullfile(clusterDir,sprintf(clusterName,currT)));
    
    % Get cluster properties
    if tInd == 1
        matSize = size(loadClusters);
    end
    clusterProps = regionprops3(loadClusters,clusterFields);
    % Iterate through each cluster, store filament info
    for currClust = 1:size(clusterProps,1)
        currInds = (clusterProps.('VoxelIdxList'){currClust});
        filsOnCluster = unique(loadFils(currInds));
        clusterProps.FilIDs{currClust} = filsOnCluster;
    end
    % Save current properties
    save(fullfile(baseDir,sprintf('T%06i_clusterProps.mat',currT)),'clusterProps');

end

end
