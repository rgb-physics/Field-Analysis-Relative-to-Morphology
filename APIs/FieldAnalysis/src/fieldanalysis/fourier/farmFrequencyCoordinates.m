function axes = farmFrequencyCoordinates(gridSize, spacing)
%FARMFREQUENCYCOORDINATES Shifted FFT axes, Y X [Z], cycles per spacing unit.
% Inputs:
%   gridSize        Array dimensions in YX or YXZ order.
%   spacing         Sample spacing in array-axis order.
% Outputs:
%   axes            Cell array of shifted frequency vectors in array-axis order.

if nargin < 2
    spacing = ones(size(gridSize));
end
validateattributes(gridSize, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
if ~ismember(numel(gridSize), [2 3])
    error('fieldanalysis:Dimensions', 'Specify two or three dimensions.');
end
validateattributes(spacing, {'numeric'}, {'vector', 'positive', 'finite'});
if numel(spacing) ~= numel(gridSize)
    error('fieldanalysis:Spacing', 'Spacing must match dimensions in YXZ order.');
end
axes = cell(1, numel(gridSize));
for d = 1:numel(gridSize)
    axes{d} = farmGenScaledKVec(gridSize(d), spacing(d));
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMFREQUENCYCOORDINATES Shifted FFT axes, Y X [Z], cycles per spacing unit.
