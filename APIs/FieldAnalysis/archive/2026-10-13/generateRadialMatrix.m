function [ringIndMat] = generateRadialMatrix(matSize,ringNum)
%GENERATERADIALMATRIX Takes in a matrix size and generates a matrix of
%ringNum concentric rings with indices indicating bin separation from the
%matrix center. The matrix can be 2D or 3D, depending on the dimension of
%matSize

%Generate vectors for each dimension
rowVec = -floor(matSize(1)/2):floor(matSize(1)/2);
colVec = -floor(matSize(2)/2):floor(matSize(2)/2);

if numel(matSize) == 2
    [rowInds, colInds] = ndgrid(rowVec,colVec);
else
    depthVec = -floor(matSize(3)/2):floor(matSize(3)/2);
    [rowInds, colInds, depthInds] = ndgrid(rowVec,colVec,depthVec);
end

%Instantiate ring matrix and bin values
ringIndMat = zeros(size(rowInds));
maxRad = ceil(min(matSize(:)/2)); radVals = 0:maxRad/ringNum:maxRad;

%Generate matrix of indices of rings to average over
if numel(matSize) == 2
    for currRing = 2:numel(radVals)
        ringIndMat( (rowInds.^2 + colInds.^2) > radVals(currRing-1)^2 & ...
            (rowInds.^2 + colInds.^2) <= radVals(currRing)^2) = currRing - 1;
    end
else
    for currRing = 2:numel(radVals)
        ringIndMat( (rowInds.^2 + colInds.^2 + depthInds.^2) > radVals(currRing-1)^2 & ...
            (rowInds.^2 + colInds.^2 + depthInds.^2) <= radVals(currRing)^2) = currRing - 1;
    end
end

end

