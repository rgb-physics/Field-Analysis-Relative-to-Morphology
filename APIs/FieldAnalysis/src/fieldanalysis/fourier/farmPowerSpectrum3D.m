function result = farmPowerSpectrum3D(data, options)
%FARMPOWERSPECTRUM3D Unnormalized power and spherical spectrum of a YXZ volume.
% Inputs:
%   data            Real numeric image or volume.
%   options         Operation settings struct.
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
