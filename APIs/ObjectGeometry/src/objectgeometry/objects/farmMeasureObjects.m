function [properties, objects] = farmMeasureObjects(input, requested, options)
%FARMMEASUREOBJECTS User-selected native regionprops/regionprops3 properties.
% Inputs:
%   input           Object input accepted by farmPrepareObjects.
%   requested       Names of the properties or statistics to calculate.
%   options         Operation settings struct.
% Outputs:
%   properties      Identity columns and the requested native measurements.
%   objects         Prepared object membership and grid metadata used for measurement.

if nargin < 2 || isempty(requested)
    requested = {'Centroid'};
end
if nargin < 3
    options = struct();
end
intensity = [];
if isfield(options, 'Intensity')
    intensity = options.Intensity;
    options = rmfield(options, 'Intensity');
end
objects = farmPrepareObjects(input, options);
cc = objects.Components;
if ~isempty(intensity) && ~isequal(size(intensity), cc.ImageSize)
    error('objectgeometry:GridMismatch', 'Intensity dimensions must match the current object grid.');
end
names = cellstr(string(requested));
names = names(:).';
% 'all' is a native selector, not a property name inside a cell list.
% Forward names as separate arguments so MATLAB recognizes that selector.
if any(strcmpi(names, 'all'))
    names = {'all'};
end
measurementCC = cc;
emptyForeground = cc.NumObjects == 0;
if emptyForeground
    % Native zero-object tables can lose vector-column widths (0x0).
    % Measure a single template voxel, then discard its row to retain the
    % release-specific schema for EVERY requested native property.
    measurementCC.NumObjects = 1;
    measurementCC.PixelIdxList = {1};
end
if numel(cc.ImageSize) == 3
    if ~isempty(intensity)
        error('objectgeometry:NativeIntensity3D', 'regionprops3 does not accept intensity input. Use the separate field-query API.');
    end
    native = regionprops3(measurementCC, names{:});
else
    if isempty(intensity)
        native = regionprops('table', measurementCC, names{:});
    else
        native = regionprops('table', measurementCC, intensity, names{:});
    end
end
if emptyForeground
    native = native([], :);
end
if height(native) ~= numel(objects.ObjectIDs)
    error('objectgeometry:PropertyRowMismatch', 'Native measurements did not preserve component count.');
end
keys = table(repmat(objects.DatasetID, height(native), 1), ...
             repmat(objects.Frame, height(native), 1), objects.ObjectIDs, ...
             'VariableNames', {'DatasetID', 'Frame', 'ObjectID'});
properties = [keys native];
properties.Properties.UserData = struct('Grid', objects.Grid, 'SourceGrid', objects.SourceGrid, ...
                                        'Transform', objects.Transform, 'Units', 'voxel', 'InputType', objects.InputType, ...
                                        'DatasetID', objects.DatasetID, 'Frame', objects.Frame);
farmOGValidateKeys(properties);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMMEASUREOBJECTS User-selected native regionprops/regionprops3 properties.
% [TABLE,OBJECTS]=farmMeasureObjects(INPUT,PROPERTIES,OPTIONS). PROPERTIES is a
% cell/string array of native property names, or 'all'. Identity options go
% to prepareObjects; OPTIONS.Intensity=[] supplies matching grayscale data
% for native 2-D intensity properties. MATLAB determines property availability
% for the installed release. No custom properties computed silently.
% Table keys are DatasetID/Frame/ObjectID. Native geometric values are in
% pixel/voxel units. Centroid/BoundingBox/VoxelList use MATLAB XYZ ordering;
% raw 3-D EigenVectors retain MATLAB ordering (see measureFilaments).
% Optional large native properties are included only when requested.
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% Join measurements using DatasetID, Frame and ObjectID together.
% Native geometric measurements remain in pixel/voxel units; no resampling occurs.
