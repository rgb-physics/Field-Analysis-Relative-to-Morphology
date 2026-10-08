%% Directory and Data Information
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 12, Exp 4';
fileNameFormat = 'Time000001_OgMesh.ply';
timeRange = 1;
saveDirFoldForm ='Time %0.6i';
saveBool = 1;   ignoreBounds = 0;
cutoff = 200;

%% Iterate through time

for currT = 1:numel(timeRange)
    
    fprintf('\nCurrent time point... %i', timeRange(currT))
    % Load mesh
    meshObj = read_ply_mod(fullfile(dataDir, sprintf(fileNameFormat,timeRange(currT)))) ;

    % Split meshes
    splitMeshes = split_mesh_into_components(meshObj.f, meshObj.v, ...
        cutoff, saveBool, fullfile(dataDir,sprintf(saveDirFoldForm, timeRange(currT))), ignoreBounds); 
    fclose('all');
    
end