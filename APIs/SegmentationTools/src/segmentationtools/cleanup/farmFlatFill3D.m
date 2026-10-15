function outMat = farmFlatFill3D(inMat, dimFills)
%FARMFLATFILL3D Fill a binary volume along selected Cartesian viewing axes.
%   DIMFILLS uses the historical convention: 0 fills XY slices, 1 fills
%   YZ slices, and 2 fills XZ slices. Fills are calculated independently
%   from the original mask and unioned. INPUT and output are [Y X Z].

if ~((isnumeric(inMat) || islogical(inMat)) && isreal(inMat) && ...
        ~issparse(inMat) && ~isempty(inMat) && ndims(inMat) <= 3)
    error('segmentationtools:InvalidMask', ...
        'inMat must be a nonempty real [Y X Z] array.');
end
if any(inMat(:) ~= 0 & inMat(:) ~= 1)
    error('segmentationtools:InvalidMask', ...
        'inMat must contain only zeros and ones.');
end
validateattributes(dimFills, {'numeric'}, ...
    {'real','finite','vector','integer','>=',0,'<=',2}, ...
    mfilename, 'dimFills');

flatConnectivity = false(3,3,3);
flatConnectivity(:,:,2) = conndef(2, 'minimal');
permutation = 1:3;
outMat = logical(inMat);
for fillAxis = double(dimFills(:).')
    currentKernel = permute(flatConnectivity, ...
        circshift(permutation, fillAxis));
    currentFill = imfill(logical(inMat), currentKernel, 'holes');
    outMat = outMat | currentFill;
end
end
