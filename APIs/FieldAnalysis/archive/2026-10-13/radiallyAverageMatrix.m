function [meanVals,r_bin,r_counts,binnedInds] = radiallyAverageMatrix(inputMat,sigma,polBool,ringSpace)
%RADIALLYAVERAGEMATRIX Radially averages the contents of a matrix INPUTMAT
%over a series of concentric rings centered at each pixel. If polBool == 1,
%the script will asume cylindrical coordinates over spherical (2D slice
%circular averages rather than 3D sphere shell averages). ringSpace can be
%a scalar value, indicating the spacing of rings (in pixels) over which to
%average. Alternatively, ringSpace can be a vector which represents the set
%of rings over which to average.

% Define ringSpace if omitted by user
if nargin == 2
    polBool = 0;
    ringSpace = 1;
elseif nargin == 3
    ringSpace = 1;
end

% Prep radial coords for binning
[rows, cols, depths] = size(inputMat);
y = (1:rows) - round(rows/2) - 1;
x = (1:cols) - round(cols/2) - 1;
if numel(size(inputMat)) == 2
    [xMat,yMat] = meshgrid(x,y);
    [~,rCoords]  = cart2pol(xMat,yMat);
elseif numel(size(inputMat)) == 3 && (polBool == 0)
    z = (1:depths) - round(depths/2);
    [xMat,yMat,zMat] = meshgrid(x,y,z);
    [~,~,rCoords]  = cart2sph(xMat,yMat,zMat);
elseif numel(size(inputMat)) == 3 && (polBool == 1)
    z = (1:depths) - round(depths/2);
    [xMat,yMat,zMat] = meshgrid(x,y,z);
    [~,rCoords,~]  = cart2pol(xMat,yMat,zMat);
end

% Average over rings of radius rCoords(i)
if numel(ringSpace) == 1
    r_bin = 1:ringSpace:max(round(size(inputMat)/2));
else
    r_bin = ringSpace;
end
[r_counts,~,binnedInds] = histcounts(rCoords,r_bin);
meanVals = zeros(numel(r_bin),1);
for ringInd = 1:numel(r_counts)    
    if sigma == 0
        % Average over binned values
        meanVals(ringInd) = sum(inputMat(binnedInds == ringInd))/r_counts(ringInd);
    else
        % With gaussian profile if sigma is non-zero (look at again)
        meanVals(ringInd) = sum(inputMat(:).*exp(-(rCoords(:)-r_bin(ringInd)).^2/2/sigma^2))/...
            sum(exp(-(rCoords(:)-r_bin(ringInd)).^2/2/sigma^2));
    end
end
end

