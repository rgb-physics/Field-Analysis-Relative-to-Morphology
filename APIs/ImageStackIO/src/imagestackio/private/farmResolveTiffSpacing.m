function [spacing, spacingUnit, spacingSource] = farmResolveTiffSpacing(options, tiffInfo, imageJ)
%FARMRESOLVETIFFSPACING Resolve [Y X Z] calibration for a TIFF image.
%   Explicit options override embedded TIFF/ImageJ calibration. Missing
%   metadata components retain the unit-pixel default value of one.

spacing = [1 1 1];
spacingUnit = 'pixel';
hasMetadata = false;

if isfield(imageJ, 'Unit') && ~isempty(imageJ.Unit)
    spacingUnit = imageJ.Unit;
    hasMetadata = true;
else
    resolutionUnit = localResolutionUnit(tiffInfo);
    if ~isempty(resolutionUnit)
        spacingUnit = resolutionUnit;
        hasMetadata = true;
    end
end

% Treat resolution tags as spatial calibration only when the TIFF or
% ImageJ metadata also supplies a physical unit. Uncalibrated TIFF files
% commonly contain display-resolution tags that do not describe pixels.
hasSpatialUnit = ~strcmp(spacingUnit, 'pixel');
if hasSpatialUnit && isfield(tiffInfo, 'YResolution') && ...
        localPositiveScalar(tiffInfo.YResolution)
    spacing(1) = 1 / double(tiffInfo.YResolution);
    hasMetadata = true;
end
if hasSpatialUnit && isfield(tiffInfo, 'XResolution') && ...
        localPositiveScalar(tiffInfo.XResolution)
    spacing(2) = 1 / double(tiffInfo.XResolution);
    hasMetadata = true;
end
if isfield(imageJ, 'Spacing') && localPositiveScalar(imageJ.Spacing)
    spacing(3) = double(imageJ.Spacing);
    hasMetadata = true;
end

hasSpacingOption = isfield(options, 'Spacing') && ~isempty(options.Spacing);
hasUnitOption = isfield(options, 'SpacingUnit') && ~isempty(options.SpacingUnit);
if hasSpacingOption
    spacing = options.Spacing;
end
if hasUnitOption
    spacingUnit = options.SpacingUnit;
end
[spacing, spacingUnit] = farmParseSpacingOptions(struct( ...
    'Spacing', spacing, 'SpacingUnit', spacingUnit));

if hasSpacingOption || hasUnitOption
    spacingSource = 'options';
elseif hasMetadata
    spacingSource = 'TIFF/ImageJ metadata';
else
    spacingSource = 'default';
end
end

function tf = localPositiveScalar(value)
tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value > 0;
end

function unit = localResolutionUnit(tiffInfo)
unit = '';
if ~isfield(tiffInfo, 'ResolutionUnit') || isempty(tiffInfo.ResolutionUnit)
    return
end
value = tiffInfo.ResolutionUnit;
if isstring(value) && isscalar(value)
    value = char(value);
end
if ~ischar(value)
    return
end
switch lower(strtrim(value))
    case {'inch', 'inches'}
        unit = 'inch';
    case {'centimeter', 'centimeters', 'cm'}
        unit = 'cm';
end
end
