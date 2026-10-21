function result = farmSegmentIntensity(intensity, options)
%FARMSEGMENTINTENSITY Generate a basic foreground morphology from intensity.
% Inputs:
%   intensity       One finite real 2D image or 3D intensity volume.
%   options         Optional scalar struct with the fields:
%                   Method = character vector or string scalar;
%                   Threshold = numeric scalar or [];
%                   Foreground = character vector or string scalar;
%                   IntensityRange = numeric two-element vector or [];
%                   EstimationMask = logical array or [];
%                   FillHoles = logical scalar;
%                   MinObjectSize = nonnegative integer scalar;
%                   KeepLargest = nonnegative integer scalar or [];
%                   Connectivity = numeric scalar or [];
%                   ReturnLabels = logical scalar;
% Outputs:
%   result          Foreground mask, threshold, counts and optionally connected-object labels.

if nargin < 2
    options = struct();
end
validateattributes(intensity, {'numeric', 'logical'}, ...
                   {'real', 'finite', 'nonempty', 'nonsparse'}, mfilename, 'intensity');
if ndims(intensity) > 3
    error('segmentationtools:InvalidIntensityDimensions', 'Select one channel and time point.');
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', 'Options must be a scalar struct.');
end
defaults = farmMakeIntensityOptions();
unknown = setdiff(fieldnames(options), fieldnames(defaults));
if ~isempty(unknown)
    error('segmentationtools:UnknownOption', 'Unknown option: %s', unknown{1});
end
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(options, names{i})
        options.(names{i}) = defaults.(names{i});
    end
end
method = validatestring(options.Method, {'fixed', 'otsu'});
foreground = validatestring(options.Foreground, {'bright', 'dark'});
validateattributes(options.FillHoles, {'logical'}, {'scalar'});
validateattributes(options.ReturnLabels, {'logical'}, {'scalar'});
validateattributes(options.MinObjectSize, {'numeric'}, ...
                   {'scalar', 'real', 'finite', 'integer', 'nonnegative'});
if ~isempty(options.KeepLargest)
    validateattributes(options.KeepLargest, {'numeric'}, ...
                       {'scalar', 'real', 'finite', 'integer', 'nonnegative'});
end
conn = options.Connectivity;
if isempty(conn)
    if ndims(intensity) == 2
        conn = 8;
    else
        conn = 26;
    end
end
validateattributes(conn, {'numeric'}, {'scalar', 'real', 'finite', 'integer'});
allowed = [6 18 26];
if ndims(intensity) == 2
    allowed = [4 8];
end
if ~ismember(conn, allowed)
    error('segmentationtools:InvalidConnectivity', 'Connectivity does not match image dimensions.');
end
data = double(intensity);
if isempty(options.EstimationMask)
    samples = data(:);
else
    if ~islogical(options.EstimationMask) || ...
            ~isequal(size(options.EstimationMask), size(data)) || ~any(options.EstimationMask(:))
        error('segmentationtools:InvalidEstimationMask', 'Use a nonempty logical mask matching the image.');
    end
    samples = data(options.EstimationMask);
end
range = options.IntensityRange;
if isempty(range)
    range = [min(samples) max(samples)];
else
    validateattributes(range, {'numeric'}, {'real', 'finite', 'vector', 'numel', 2});
    range = double(range(:).');
    if range(1) >= range(2)
        error('segmentationtools:InvalidIntensityRange', 'Range must be [low high] with low < high.');
    end
end
if strcmp(method, 'fixed')
    validateattributes(options.Threshold, {'numeric'}, {'scalar', 'real', 'finite', 'nonempty'});
    threshold = double(options.Threshold);
else
    if ~isempty(options.Threshold)
        error('segmentationtools:UnusedThreshold', 'Use Method=fixed when supplying Threshold.');
    end
    if range(1) == range(2)
        threshold = range(1); % constant reference: strict comparison avoids selecting it
    else
        normalized = min(1, max(0, (samples - range(1)) / (range(2) - range(1))));
        threshold = range(1) + graythresh(normalized) * (range(2) - range(1));
    end
end
if strcmp(foreground, 'bright')
    candidate = data > threshold;
else
    candidate = data < threshold;
end
mask = candidate;
if options.FillHoles
    mask = imfill(mask, conn, 'holes');
end
components = bwconncomp(mask, conn);
sizes = cellfun(@numel, components.PixelIdxList);
selected = find(sizes >= options.MinObjectSize);
if ~isempty(options.KeepLargest)
    [~, order] = sort(sizes(selected), 'descend');
    selected = selected(order(1:min(numel(order), options.KeepLargest)));
end
mask = false(size(data));
for i = selected(:).'
    mask(components.PixelIdxList{i}) = true;
end
result = struct('Mask', mask, 'CandidateMask', candidate, 'Threshold', threshold, ...
                'IntensityRange', range, 'Method', method, 'Foreground', foreground, ...
                'Connectivity', conn, 'VoxelCount', nnz(mask), 'ComponentCount', numel(selected), ...
                'Options', options);
if options.ReturnLabels
    result.LabelVolume = labelmatrix(bwconncomp(mask, conn));
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSEGMENTINTENSITY Generate a basic foreground morphology from intensity.
% Input: one finite real 2-D image or [Y X Z] volume. Select channel/time
% before calling. Requires Image Processing Toolbox. No files are written.
%
% OPTIONS (scalar struct; all optional):
%   Method          'otsu' (default) or 'fixed'. One threshold per volume.
%   Threshold       [] by default; required for fixed, in ORIGINAL units.
%   Foreground      'bright' (default) or 'dark'; strict > or < threshold.
%   IntensityRange  [] uses observed min/max for Otsu scaling; otherwise
%                   [low high] in original units, clipping only for fitting.
%   EstimationMask  [] uses all voxels to estimate range/threshold; logical
%                   mask selects reference voxels, NOT output support.
%   FillHoles       false; fill enclosed holes (2-D/3-D) before filtering.
%   MinObjectSize   0; remove components smaller than this voxel count.
%   KeepLargest     []; optionally keep this many largest components.
%   Connectivity    []; defaults to 8 (2-D), 26 (3-D).
%   ReturnLabels    false; optionally label individual connected objects.
%
% RESULT.Mask is the final logical morphology; CandidateMask is the strict
% threshold result before cleanup. Threshold is in original intensity units.
% IntensityRange records Otsu scaling. VoxelCount and ComponentCount describe
% the final mask. LabelVolume, when requested, stores object IDs, NOT classes.
% This is foreground selection, not probability estimation or touching-cell
% separation. Cleanup order: fill holes, minimum size, largest components.
%
% Example: r = farmSegmentIntensity(volume);
% Fixed: r = farmSegmentIntensity(volume, ...
%     struct('Method','fixed','Threshold',1200,'MinObjectSize',100));
