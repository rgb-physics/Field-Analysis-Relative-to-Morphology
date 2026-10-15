function result = farmRadialAverage(values,options)
%FARMRADIALAVERAGE Hard bins or historical Gaussian radial weighting.
% Coordinates are axis vectors; default is an fftshift-centered voxel grid.
% Gaussian uses all voxels at each bin center, not only voxels in that bin.
if nargin<2, options = struct(); end
o = farmFAOptions(options, struct('Coordinates',{{}},'Spacing',[], ...
    'Edges',[],'NumBins',50,'Sigma',0));
values = farmFAField(values);
dims = size(values); nD = ndims(values);
validateattributes(o.Sigma,{'numeric'},{'scalar','nonnegative','finite'});
if isempty(o.Coordinates)
    if isempty(o.Spacing), o.Spacing = ones(1,nD); end
    validateattributes(o.Spacing,{'numeric'},{'vector','positive','finite'});
    if numel(o.Spacing)~=nD, error('fieldanalysis:Spacing','Spacing must match dimensions.'); end
    coords = cell(1,nD);
    for d = 1:nD, coords{d} = ((1:dims(d))-(floor(dims(d)/2)+1))*o.Spacing(d); end
else
    coords = o.Coordinates;
    if ~iscell(coords)||numel(coords)~=nD, error('fieldanalysis:Coordinates','Supply one axis vector per dimension.'); end
end
r2 = zeros(dims);
for d = 1:nD
    validateattributes(coords{d},{'numeric'},{'vector','real','finite','numel',dims(d)});
    shape = ones(1,nD); shape(d) = dims(d);
    r2 = r2+reshape(double(coords{d}).^2,shape);
end
radius = sqrt(r2);
if isempty(o.Edges)
    validateattributes(o.NumBins,{'numeric'},{'scalar','integer','positive','finite'});
    [counts,edges,bins] = histcounts(radius(:),o.NumBins);
else
    edges = double(o.Edges(:)');
    validateattributes(edges,{'numeric'},{'vector','finite','increasing'});
    if numel(edges)<2, error('fieldanalysis:Edges','At least two edges required.'); end
    [counts,~,bins] = histcounts(radius(:),edges);
end
centers = (edges(1:end-1)+edges(2:end))/2;
meanPower = NaN(numel(counts),1); sums = zeros(numel(counts),1); weightSums = zeros(numel(counts),1);
for k = 1:numel(counts)
    if counts(k)==0, continue; end
    if o.Sigma==0
        sums(k) = sum(values(bins==k)); weightSums(k) = counts(k);
    else
        w = exp(-((radius(:)-centers(k))/o.Sigma).^2/2);
        sums(k) = sum(values(:).*w); weightSums(k) = sum(w);
    end
    if weightSums(k)>0, meanPower(k) = sums(k)/weightSums(k); end
end
result = struct('Edges',edges,'Centers',centers(:),'Counts',counts(:), ...
    'Mean',meanPower,'Sums',sums,'WeightSums',weightSums, ...
    'Sigma',o.Sigma,'ExcludedCount',nnz(bins==0));
end
