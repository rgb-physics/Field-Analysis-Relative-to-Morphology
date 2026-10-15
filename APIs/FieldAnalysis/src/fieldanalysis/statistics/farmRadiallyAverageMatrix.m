function [meanVals,r_bin,r_counts,binnedInds] = farmRadiallyAverageMatrix(inputMat,sigma,polBool,ringSpace)
%FARMRADIALLYAVERAGEMATRIX Legacy interface with corrected centers/bin length.
% Prefer farmRadialAverage for explicit coordinates.
% polBool=1 pools cylindrical XY radii over Z; it does not return each slice.
% Gaussian weighting retains the historical left-edge evaluation convention.
% Empty bins are NaN. There is one output value per bin, not per edge.
if nargin<2, sigma = 0; end
if nargin<3, polBool = 0; end
if nargin<4, ringSpace = 1; end
inputMat = farmFAField(inputMat);
validateattributes(sigma,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(polBool,{'numeric','logical'},{'scalar'});
dims = size(inputMat); coords = cell(1,ndims(inputMat));
for d = 1:numel(dims), coords{d} = (1:dims(d))-(floor(dims(d)/2)+1); end
if ndims(inputMat)==3&&polBool, coords{3} = zeros(1,dims(3)); end
if isscalar(ringSpace)
    validateattributes(ringSpace,{'numeric'},{'positive','finite'});
    r_bin = 0:ringSpace:ceil(max(dims)/2);
    if numel(r_bin)<2, r_bin = [0 ringSpace]; end
else
    r_bin = ringSpace(:)';
end
r = farmRadialAverage(inputMat,struct('Coordinates',{coords},'Edges',r_bin));
meanVals = r.Mean; r_counts = r.Counts';
r2 = zeros(dims);
for d = 1:numel(dims)
    shape = ones(1,numel(dims)); shape(d) = dims(d);
    r2 = r2+reshape(coords{d}.^2,shape);
end
radius = sqrt(r2);
[~,~,bins] = histcounts(radius(:),r_bin); binnedInds = reshape(bins,dims);
if sigma>0
    for k = 1:numel(r_counts)
        if r_counts(k)==0, continue; end
        w = exp(-((radius(:)-r_bin(k))/sigma).^2/2);
        if sum(w)>0, meanVals(k) = sum(inputMat(:).*w)/sum(w); else, meanVals(k) = NaN; end
    end
end
end
