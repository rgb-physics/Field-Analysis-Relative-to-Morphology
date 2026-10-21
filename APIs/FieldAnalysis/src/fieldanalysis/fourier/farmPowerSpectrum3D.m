function result = farmPowerSpectrum3D(data, options)
%FARMPOWERSPECTRUM3D Unnormalized power and spherical spectrum of a YXZ volume.
% Inputs:
%   data            Real numeric image or volume.
%   options         Optional scalar struct with the fields:
%                   Spacing = positive numeric vector;
%                   SpacingUnit = character vector or string scalar;
%                   MeanSubtract = logical scalar;
%                   Window = logical scalar;
%                   Edges = numeric vector or [];
%                   NumBins = positive integer scalar;
%                   Sigma = nonnegative numeric scalar;
%                   ReturnPower = logical scalar;
% Outputs:
%   result          3D spectrum struct with radial results, frequency axes and normalization metadata.

if nargin < 2
    options = struct();
end
result = farmFASpectrum(data, 3, options);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMPOWERSPECTRUM3D Unnormalized power and spherical spectrum of a YXZ volume.
