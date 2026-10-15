function [topLayer,botLayer,topLayerZs,botLayerZs,centerSlice,centerSliceZs,splitSlice] = farmReturnTopBottom2DSheetsConfigurable(inputData,options)
%FARMRETURNTOPBOTTOM2DSHEETSCONFIGURABLE Separate two dominant sheets in a mask.
% Configurable copy of farmReturnTopBottom2DSheets.m; the original is retained.
%
% INPUTDATA is one binary [Y X Z] volume. Select channel and time before
% calling this function. Numeric zeros/ones and logical arrays are accepted.
%
% OPTIONS is an optional scalar struct with these fields:
%   SplitSlice       [] (default): detect a local occupancy minimum nearest
%                    the volume's central Z slice. Otherwise, supply an
%                    integer Z index to override automatic detection.
%   SplitSearchRange [] (default): consider minima throughout the volume.
%                    Otherwise, supply inclusive [firstZ lastZ] bounds.
%                    Used only for automatic detection. Minima are detected
%                    on the full occupancy profile, then filtered by range.
%   GapHalfWidth     2 (default): remove SplitSlice +/- this many slices.
%                    Zero removes only the split slice. Units are voxels.
%   Connectivity     26 (default): 6, 18, or 26 for connected components.
%                    6 joins face neighbors; 18 also joins edge neighbors;
%                    26 additionally joins corner neighbors.
%
% The two largest remaining components are selected, then ordered by mean
% Z index. TOP means smaller mean Z index, not necessarily physical top.
% TOPLAYER and BOTLAYER are logical masks. Their corresponding Z arrays
% contain Z indices at selected voxels and zero elsewhere. CENTERSLICE is
% the original material removed by the cut (the entire band, despite its
% historical name). CENTERSLICEZS contains its Z indices. SPLITSLICE is the
% selected Z index. All mask and coordinate arrays retain the input size.
%
% The removal band must fit inside the volume. No automatic clipping or
% fallback split is applied. An error is raised if no local minimum is found
% in the search range or fewer than two components remain after cutting.
% This function does not guarantee one component on each side of the gap.
%
% Requires Image Processing Toolbox (bwconncomp), and Signal Processing
% Toolbox (findpeaks) when SplitSlice is not supplied.
%
% Example, after adding APIs/SegmentationTools/src to the MATLAB path:
%   opts = struct('SplitSlice', 30, 'GapHalfWidth', 2, 'Connectivity', 26);
%   [top,bottom] = farmReturnTopBottom2DSheetsConfigurable(mask, opts);

if nargin < 2
    options = struct();
end

if ~((isnumeric(inputData) || islogical(inputData)) && ...
        isreal(inputData) && ~issparse(inputData) && ~isempty(inputData) && ...
        ndims(inputData) == 3 && size(inputData,3) > 1)
    error('segmentationtools:InvalidMask', ...
        'inputData must be one nonempty, real, full binary [Y X Z] volume.');
end
if any(inputData(:) ~= 0 & inputData(:) ~= 1)
    error('segmentationtools:InvalidMask', ...
        'inputData must contain only zeros and ones; threshold probabilities first.');
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', 'options must be a scalar struct.');
end

defaults = struct('SplitSlice', [], 'SplitSearchRange', [], ...
    'GapHalfWidth', 2, 'Connectivity', 26);
unknown = setdiff(fieldnames(options), fieldnames(defaults));
if ~isempty(unknown)
    error('segmentationtools:UnknownOption', 'Unknown option: %s.', unknown{1});
end
names = fieldnames(defaults);
for index = 1:numel(names)
    if ~isfield(options, names{index})
        options.(names{index}) = defaults.(names{index});
    end
end

nZ = size(inputData,3);
validateattributes(options.GapHalfWidth, {'numeric'}, ...
    {'real','finite','scalar','integer','nonnegative'}, mfilename, 'GapHalfWidth');
validateattributes(options.Connectivity, {'numeric'}, ...
    {'real','finite','scalar','integer'}, mfilename, 'Connectivity');
if ~ismember(options.Connectivity, [6 18 26])
    error('segmentationtools:InvalidConnectivity', 'Connectivity must be 6, 18, or 26.');
end
if isempty(options.SplitSearchRange)
    searchRange = [1 nZ];
else
    validateattributes(options.SplitSearchRange, {'numeric'}, ...
        {'real','finite','vector','numel',2,'integer','>=',1,'<=',nZ}, ...
        mfilename, 'SplitSearchRange');
    searchRange = double(options.SplitSearchRange(:).');
    if searchRange(1) > searchRange(2)
        error('segmentationtools:InvalidSearchRange', ...
            'SplitSearchRange must be ordered as [firstZ lastZ].');
    end
end

mask = logical(inputData);
if isempty(options.SplitSlice)
    % Preserve the original local-minimum/nearest-volume-center strategy.
    occupancy = squeeze(sum(mask, [1 2]));
    [~, candidates] = findpeaks(-occupancy);
    candidates = candidates(candidates >= searchRange(1) & ...
        candidates <= searchRange(2));
    if isempty(candidates)
        error('segmentationtools:NoSplitCandidate', ...
            ['No local occupancy minimum was found in SplitSearchRange. ' ...
             'Supply SplitSlice explicitly or adjust the search range.']);
    end
    [~, closest] = min(abs(round(nZ/2) - candidates));
    splitSlice = candidates(closest);
else
    validateattributes(options.SplitSlice, {'numeric'}, ...
        {'real','finite','scalar','integer','>=',1,'<=',nZ}, ...
        mfilename, 'SplitSlice');
    splitSlice = double(options.SplitSlice);
end

halfWidth = double(options.GapHalfWidth);
if splitSlice-halfWidth < 1 || splitSlice+halfWidth > nZ
    error('segmentationtools:GapOutsideVolume', ...
        ['The removal band extends beyond the volume. Reduce GapHalfWidth ' ...
         'or choose a SplitSlice farther from the boundary.']);
end
cutSlices = (splitSlice-halfWidth):(splitSlice+halfWidth);
cutData = mask;
cutData(:,:,cutSlices) = false;

% Use the same component definition for ranking and mask extraction.
components = bwconncomp(cutData, double(options.Connectivity));
if components.NumObjects < 2
    error('segmentationtools:TooFewComponents', ...
        ['The cut leaves %d connected component(s); two sheets are required. ' ...
         'Review the mask, split slice, band width, and connectivity.'], ...
        components.NumObjects);
end
volumes = cellfun(@numel, components.PixelIdxList);
[~, sizeOrder] = sort(volumes);
selected = sizeOrder(end:-1:end-1);
firstPixels = components.PixelIdxList{selected(1)};
secondPixels = components.PixelIdxList{selected(2)};
[~,~,firstZ] = ind2sub(size(mask), firstPixels);
[~,~,secondZ] = ind2sub(size(mask), secondPixels);
if mean(firstZ) <= mean(secondZ)
    topPixels = firstPixels; topZ = firstZ;
    bottomPixels = secondPixels; bottomZ = secondZ;
else
    topPixels = secondPixels; topZ = secondZ;
    bottomPixels = firstPixels; bottomZ = firstZ;
end

topLayer = false(size(mask));
botLayer = false(size(mask));
topLayer(topPixels) = true;
botLayer(bottomPixels) = true;
topLayerZs = zeros(size(mask));
botLayerZs = zeros(size(mask));
topLayerZs(topPixels) = topZ;
botLayerZs(bottomPixels) = bottomZ;

centerSlice = false(size(mask));
centerSlice(:,:,cutSlices) = mask(:,:,cutSlices);
centerPixels = find(centerSlice);
[~,~,centerZ] = ind2sub(size(mask), centerPixels);
centerSliceZs = zeros(size(mask));
centerSliceZs(centerPixels) = centerZ;
end
