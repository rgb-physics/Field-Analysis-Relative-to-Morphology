function [matrix, map] = farmExportDetections(detections, options)
%FARMEXPORTDETECTIONS Explicit original-row identity map for position tracking.
% Inputs:
%   detections      Detection table with identity and centroid coordinates.
%   options         Optional scalar struct with the fields:
%                   MassProperty = character vector or string scalar;
%                   CoordinateScale = numeric vector or [];
% Outputs:
%   matrix          Numeric coordinates, mass and frame columns for the linker.
%   map             Original-row identities, including one-based RowID.

if nargin < 2
    options = struct();
end
options = farmOGOptions(options, struct('MassProperty', '', 'CoordinateScale', []));
farmOGValidateKeys(detections);
if numel(unique(detections.DatasetID)) > 1
    error('objecttracking:TrackpyDataset', 'Link one dataset at a time.');
end
coordinates = detections.Centroid;
dims = size(coordinates, 2);
validateattributes(coordinates, {'numeric'}, {'real', 'finite', '2d'});
if ~ismember(dims, [2 3])
    error('objecttracking:TrackpyCoordinates', 'Centroid must contain XY or XYZ coordinates.');
end
scale = options.CoordinateScale;
if isempty(scale)
    scale = ones(1, dims);
end
validateattributes(scale, {'numeric'}, {'real', 'finite', 'vector', 'numel', dims, 'positive'});
mass = ones(height(detections), 1);
if strlength(string(options.MassProperty)) > 0
    mass = detections.(char(options.MassProperty));
end
validateattributes(mass, {'numeric'}, {'real', 'finite', 'column'});
if numel(mass) ~= height(detections)
    error('objecttracking:TrackpyMass', 'Mass property must be scalar per detection.');
end
matrix = [double(coordinates) .* double(scale(:).') double(mass) double(detections.Frame)];
map = detections(:, {'DatasetID', 'Frame', 'ObjectID'});
map.RowID = (1:height(map)).';
coordinateOrder = 'XYZ';
map.Properties.UserData = struct('Options', options, 'CoordinateOrder', coordinateOrder(1:dims), 'ScaledCoordinates', true);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMEXPORTDETECTIONS Explicit original-row identity map for position tracking.
% Input table DatasetID/Frame/ObjectID/Centroid (XYZ or XY). One dataset only.
% MassProperty='' uses ones; e.g. 'Volume' preserves historical mass column.
% CoordinateScale=[] optionally scales each coordinate WITHOUT matrix resizing.
% Numeric output is [coordinates mass frame]. RowID is one-based original row,
% explicitly carried through Python; not inferred from frame counts/order.
