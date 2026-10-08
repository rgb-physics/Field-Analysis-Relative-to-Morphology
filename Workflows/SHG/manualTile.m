%% Takes in the directory of a 3D stack and spits out a tiled 2D matrix
% The 2D matrix will have tilings of tileRow slices stacked along the row
% dimension and tileCols slices stacked along the column dimension.
% rowRange and colRange define the row and column bounds to sample from the
% input tif and tileRows by tileCols slices are loaded by default
% tifDir = '<redacted original absolute path>';
tifDir = '';
tifName = 'TimeStack_Fl_Ints.tif';
% tifName = 'TimeStack_SHG.tif';

tileRows = 32;
tileCols = 29;
rowRange = [1 1 128];
colRange = [1 1 127];

saveBool = 1;
saveDir = tifDir;
saveName = ['Tiled_' tifName];

%% Try reshaping
fullTif = tiffreadVolume(fullfile(tifDir,tifName),'PixelRegion',{rowRange, colRange, [1 1 tileRows*tileCols]});
fullTif = flipud(fullTif);
stackedTifs = reshape(permute(fullTif,[1,3,2]),[],colRange(3));
tiledSlices = blockReshape2D(stackedTifs',rowRange(3)*tileRows)';

% save, if requested
if saveBool == 1
    imwrite(tiledSlices,fullfile(saveDir,saveName));
end

%% Reshaping a tif of (2,2) x and y -> z 
% tifDir = '<redacted original absolute path>';
tifDir = '';
tifName = 'TimeStack_Fl_Ints.tif';
saveDir = tifDir;
saveName = ['Resliced_' tifName];

tileRows = 2;   tileCols = 2;   numDeps = 19;
rowRange = [1 1 128];
colRange = [1 1 127];

stackOrder = [4 1 3 2];     % rows then cols

for tInd = 1:numDeps
    
    zMin = 1 + (tInd - 1) *numel(stackOrder);   
    zMax = zMin + numel(stackOrder) - 1;
    currZRange = [zMin 1 zMax];
    currStack = tiffreadVolume(fullfile(tifDir,tifName),"PixelRegion",{rowRange, colRange, currZRange});
    stackedTifs = blockReshape2D(currStack(:,:,stackOrder),colRange(3));
    tiledSlices = blockReshape2D(stackedTifs',rowRange(3)*tileRows)';

    % Save
    if tInd == 1
        imwrite(tiledSlices,fullfile(saveDir,saveName));
    else
        imwrite(tiledSlices,fullfile(saveDir,saveName),'WriteMode','append');
    end

end




