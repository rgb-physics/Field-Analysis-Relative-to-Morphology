function [spacing, spacingUnit] = parseSpacingOptions(options)
%PARSESPACINGOPTIONS Validate spatial calibration loader options.
%   Spacing follows the canonical spatial axis order [Y X Z].

if isfield(options, 'Spacing') && ~isempty(options.Spacing)
    spacing = options.Spacing;
else
    spacing = [1 1 1];
end
if ~isnumeric(spacing) || ~isreal(spacing) || ~isvector(spacing) || ...
        numel(spacing) ~= 3 || any(~isfinite(spacing)) || any(spacing <= 0)
    error('imagestackio:InvalidSpacing', ...
        'OPTIONS.Spacing must be a three-element positive finite vector [Y X Z].');
end
spacing = reshape(double(spacing), 1, 3);

if isfield(options, 'SpacingUnit') && ~isempty(options.SpacingUnit)
    spacingUnit = options.SpacingUnit;
else
    spacingUnit = 'pixel';
end
if isstring(spacingUnit) && isscalar(spacingUnit)
    spacingUnit = char(spacingUnit);
end
if ~ischar(spacingUnit) || ~isrow(spacingUnit) || isempty(spacingUnit)
    error('imagestackio:InvalidSpacingUnit', ...
        'OPTIONS.SpacingUnit must be a nonempty character row vector or string scalar.');
end
if any(spacingUnit == newline) || any(spacingUnit == char(13))
    error('imagestackio:InvalidSpacingUnit', ...
        'OPTIONS.SpacingUnit cannot contain newline characters.');
end
end

