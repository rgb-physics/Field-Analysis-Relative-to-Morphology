function result = farmPowerSpectrum2D(data, options)
%FARMPOWERSPECTRUM2D Unnormalized power and radial spectrum of a YX image.
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
%   result          2D spectrum struct with radial results, frequency axes and normalization metadata.

if nargin < 2
    options = struct();
end
result = farmFASpectrum(data, 2, options);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMPOWERSPECTRUM2D Unnormalized power and radial spectrum of a YX image.
