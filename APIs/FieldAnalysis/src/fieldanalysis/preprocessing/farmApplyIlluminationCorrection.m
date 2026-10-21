function [corrected, info] = farmApplyIlluminationCorrection(field, model, options)
%FARMAPPLYILLUMINATIONCORRECTION Correct a quantitative field without stretching.
% Inputs:
%   field           Numeric field array or a struct containing Data and grid metadata.
%   model           Correction model returned by farmFitIlluminationCorrection.
%   options         Optional scalar struct with the fields:
%                   BleachScale = logical scalar;
% Outputs:
%   corrected       Double corrected field without range stretching.
%   info            Correction and optional scaling metadata.

if nargin < 3
    options = struct();
end
o = farmFAOptions(options, struct('BleachScale', false));
validateattributes(o.BleachScale, {'logical'}, {'scalar'});
field = farmFAField(field);
if ~isequal(size(field), size(model.Correction))
    error('fieldanalysis:SizeMismatch', 'Correction and field grids must match.');
end
if any(~isfinite(model.Correction(:))) || any(model.Correction(:) <= 0)
    error('fieldanalysis:Correction', 'Invalid correction.');
end
factor = 1;
if o.BleachScale
    [~, factor] = farmScaleToReferenceTotal(field, model.ReferenceTotal);
end
corrected = field ./ model.Correction * factor;
info = struct('BleachScale', o.BleachScale, 'AppliedFactor', factor, 'ReferenceTotal', model.ReferenceTotal);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMAPPLYILLUMINATIONCORRECTION Correct a quantitative field without stretching.
% BleachScale=false by default. Returns double; export conversion is external.
