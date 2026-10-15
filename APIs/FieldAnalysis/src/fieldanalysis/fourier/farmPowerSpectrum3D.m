function result = farmPowerSpectrum3D(data,options)
%FARMPOWERSPECTRUM3D Unnormalized power and spherical spectrum of a YXZ volume.
if nargin<2, options = struct(); end
result = farmFASpectrum(data,3,options);
end
