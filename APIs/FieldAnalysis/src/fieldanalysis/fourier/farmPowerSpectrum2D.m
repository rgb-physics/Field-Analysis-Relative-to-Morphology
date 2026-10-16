function result = farmPowerSpectrum2D(data, options)
%FARMPOWERSPECTRUM2D Unnormalized power and radial spectrum of a YX image.
% Inputs:
%   data            Real numeric image or volume.
%   options         Operation settings struct.
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
