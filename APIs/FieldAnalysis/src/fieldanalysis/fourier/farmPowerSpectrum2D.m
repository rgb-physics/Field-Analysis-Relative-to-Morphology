function result = farmPowerSpectrum2D(data,options)
%FARMPOWERSPECTRUM2D Unnormalized power and radial spectrum of a YX image.
if nargin<2, options = struct(); end
result = farmFASpectrum(data,2,options);
end
