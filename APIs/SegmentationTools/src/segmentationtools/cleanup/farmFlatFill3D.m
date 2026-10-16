function outMat = farmFlatFill3D(inMat, dimFills)
%FARMFLATFILL3D Union independent planar hole fills on a binary volume.
% Inputs:
%   inMat      Nonempty binary image or volume in YXZ array order.
%   dimFills   Numeric vector of plane selections: 0=XY, 1=XZ, 2=YZ.
% Outputs:
%   outMat     Logical union of the original mask and requested planar fills.
%
% See also imfill, farmSidesHoleFill

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

flatConnectivity = false(3, 3, 3);
flatConnectivity(:, :, 2) = conndef(2, 'minimal');
permutation = 1:3;
outMat = logical(inMat);

% Each plane fill starts from the original mask, not an earlier fill result.
for fillAxis = double(dimFills(:).')
    currentKernel = permute(flatConnectivity, ...
        circshift(permutation, fillAxis));
    currentFill = imfill(logical(inMat), currentKernel, 'holes');
    outMat = outMat | currentFill;
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Uses minimal 2D connectivity in the selected planes. Results are unioned
% with the original foreground. Selecting several directions does not apply
% the fills sequentially to the accumulating output.
%
% EXAMPLE
% -------------------------------------------------------------------------
% mask = false(7, 7, 3);
% mask([2 6], 2:6, 2) = true;
% mask(2:6, [2 6], 2) = true;
% filled = farmFlatFill3D(mask, 0);
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% With YXZ arrays: XY varies dimensions 1/2, XZ varies 2/3, YZ varies 1/3.
% Thus 1 selects fixed-Y planes and 2 selects fixed-X planes. This documents
% the existing kernel permutation; earlier help reversed the names for 1/2.
% No physical-spacing conversion or resampling occurs.
