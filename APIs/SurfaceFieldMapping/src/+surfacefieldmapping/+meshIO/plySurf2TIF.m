function [] = plySurf2TIF(dataDir,dataName,outFile,outName)
%PLYSURF2TIF This function loads a .ply file and generates a 3D thresholded
%.tif with 1s at locations defined in the .ply file and zeros elsewhere

% Load in point cloud from .ply file
ptCloud = pcread(fullfile(dataDir, dataName));
ptLocs = ptCloud.Location;

% Shift ptLocs to be minimum bounded by zero
ptLocs = ptLocs - min(ptLocs) + 1;

% Initialize thresholded location matrix
tifMat = zeros(max(ptLocs(:,1)),max(ptLocs(:,2)),max(ptLocs(:,3)));

% Assign 1s to valid locations
for currLoc = 1:size(ptLocs,1)
    
   tifMat(ptLocs(currLoc,1),ptLocs(currLoc,2),ptLocs(currLoc,3)) = 1; 
    
end

% % Remove zero planes, if any
% zeroZPlanes = logical(squeeze( 1-(sum(sum(tifMat,1),2) == 0)));
% tifMat = tifMat(:,:,zeroZPlanes);

% Save to 3D .tif
for zLayer = 1:size(tifMat,3)
   
    if zLayer == 1
        mkdir(outFile)
        imwrite(tifMat(:,:,zLayer), fullfile(outFile, outName));
    else
        imwrite(tifMat(:,:,zLayer), fullfile(outFile,outName), 'WriteMode','append');
    end
        
end

end

