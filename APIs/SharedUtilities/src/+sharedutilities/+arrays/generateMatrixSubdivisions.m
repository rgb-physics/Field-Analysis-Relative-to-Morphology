function [outInds] = generateMatrixSubdivisions(inputArray,binWindow,overlapBool)
%GENERATEMATRIXSUBDIVISIONS This functions takes in an array of
%value and returns a 2D vector, each row corresponding to a set of indices
%within a block of size determined by binWindow taken from inputArray. The
%output can return either overlapping or non-overlapping sets. If
%non-overlapping sets are desired, only sets contained within the
%dimensions of inputArray are returned (no padding)

%Edge cases
if nargin == 2
    overlapBool = 0;
end

%Generate index matrices to be used in all cases
inputDims = size(inputArray);
leastInt = floor(inputDims./binWindow);
cutOffShiftVals = mod(inputDims,binWindow) + 1;
cornerInds = inputDims - cutOffShiftVals + 1;

%Construct matrix of indices for 2D input
if numel(inputDims) == 2
    
    %Generate indices in reference frame of submatrix
    [rwinMat, cwinMat] = ndgrid(1:binWindow(1), 1:binWindow(2));
    blockCoords = sub2ind(inputDims,rwinMat(:),cwinMat(:));
    
    [boxRowInds, boxColInds] = ndgrid(1:leastInt(1), 1:leastInt(2));
    %Generate shift matrices for overlap sections; each row in shift
    %matrices corresponds to box of interest
    if overlapBool == 1
        [allRowInds, allColInds] = ndgrid(1:cornerInds(1), 1:cornerInds(2));
        cornerCoords = sub2ind(inputDims, allRowInds(:), allColInds(:));
    else
        rowCornerInds = binWindow(1)*(boxRowInds(:)-1)'+1;
        colCornerInds = binWindow(2)*(boxColInds(:)-1)'+1;
        cornerCoords = sub2ind(inputDims, rowCornerInds, colCornerInds);
    end

%Construct matrix of indices for 3D input
elseif numel(inputDims) == 3

    %Generate indices in reference frame of submatrix
    [rwinMat, cwinMat, dwinMat] = ndgrid(1:binWindow(1), 1:binWindow(2), 1:binWindow(3));
    blockCoords = sub2ind(inputDims,rwinMat(:),cwinMat(:),dwinMat(:));

    [boxRowInds, boxColInds,boxDepthInds] = ndgrid(1:leastInt(1), 1:leastInt(2), 1:leastInt(3));
    %Generate shift matrices for overlap sections; each row in shift
    %matrices corresponds to box of interest
    if overlapBool == 1
        [allRowInds, allColInds, allDepthInds] = ndgrid(1:cornerInds(1), 1:cornerInds(2), 1:cornerInds(3));
        cornerCoords = sub2ind(inputDims, allRowInds(:), allColInds(:), allDepthInds(:));
    else
        rowCornerInds = binWindow(1)*(boxRowInds(:)-1)'+1;
        colCornerInds = binWindow(2)*(boxColInds(:)-1)'+1;
        depthCornerInds = binWindow(3)*(boxDepthInds(:)-1)'+1;
        cornerCoords = sub2ind(inputDims, rowCornerInds, colCornerInds,depthCornerInds);
    end

end

%Use ndgrid to generate combinations of global and sub-box indices
[globalInds, cornerInds] = ndgrid(blockCoords, cornerCoords);
outInds = (globalInds + cornerInds - 1)';

end