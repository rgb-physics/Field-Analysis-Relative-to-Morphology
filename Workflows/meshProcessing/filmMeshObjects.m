%% This function displays a series of meshes over time and saves images of them
%% Define directories
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 11, Exp 7';
% motherDir = '<redacted original absolute path>';
motherDir = 'Session 11, Exp 7';
saveDir = fullfile(motherDir, 'Displayed Meshes');
imgNameForm = 'Time%0.6i.tif';
dataDirForm = 'Ply Files';
saveNameForm = 'Time %0.6i';
timeRange = 16:20; pixSize = 11*2/40;
saveMode = 1;
bitNum = 255;

%% Define colormap
color1 = [139, 13, 3]; color2 = [255, 160, 153];
colorForMap = meldNcolors([color1; color2], 200);

%% Make save directory
mkdir(saveDir);

%% Iterate through folders and display all meshes
for currTime = 1:numel(timeRange)
    
    currDir = sprintf(dataDirForm, timeRange(currTime));
    fileInfo = dir(fullfile(motherDir, currDir,'*.ply'));
    imageVol = tiffreadVolume(fullfile(imgDir, sprintf(imgNameForm,timeRange(currTime))));
    maxVal = double(max(imageVol, [], [1 2 3]))/bitNum; minVal = double(min(imageVol, [], [1 2 3]))/bitNum;
    imageVol = (minVal + (im2double(imageVol))*(maxVal-minVal));
    
    [rowMat, colMat, depthMat] = ndgrid(1:size(imageVol,1), 1:size(imageVol,2), 1:size(imageVol,3));
    ginterpInts = griddedInterpolant(rowMat, colMat, depthMat, (imageVol));
    figure
%     for currMesh = 1:numel(fileInfo)
% 
%         currMeshName = fileInfo(currMesh).name;
%         %Load mesh
%         meshLoad = read_ply_mod(fullfile(motherDir, currDir, currMeshName));    
%         currVerts = meshLoad.v; currFaces = meshLoad.f;
%         %Get barycenter coordinates
%         bcs = barycenter(currVerts, currFaces);
%         intAtCents = ginterpInts(bcs(:,1), bcs(:,2), bcs(:,3));
%         % Display mesh with intensities at barycenters
%         tri = triangulation(currFaces, currVerts);
%         trisurf(tri, intAtCents(:), 'edgecolor', 'none')
%         hold on
%     end
%     

    currMeshName = sprintf('Time%0.6i_PixelSegPly.ply',timeRange(currTime));
    %Load mesh
    meshLoad = read_ply_mod(fullfile(motherDir, currDir, currMeshName));    
    currVerts = meshLoad.v; currFaces = meshLoad.f;
    %Get barycenter coordinates
    bcs = barycenter(currVerts, currFaces);
    intAtCents = ginterpInts(bcs(:,1), bcs(:,2), bcs(:,3));
    % Display mesh with intensities at barycenters
    tri = triangulation(currFaces, currVerts);
    trisurf(tri, bcs(:,3))
    hold on

    
    axis equal
    xlim([40 120])
    ylim([260 360])
    zlim([80 150])
    axis off
    colormap(colorForMap)
    cb = colorbar;
    caxis([1 200])
    set(cb,'YTick',[])
    
    
    if saveMode
        saveas(gca, fullfile(saveDir, [sprintf(saveNameForm, timeRange(currTime)) '.fig']));
        saveas(gca, fullfile(saveDir, [sprintf(saveNameForm, timeRange(currTime)) '.png']));
    end
    
    close all
    
end