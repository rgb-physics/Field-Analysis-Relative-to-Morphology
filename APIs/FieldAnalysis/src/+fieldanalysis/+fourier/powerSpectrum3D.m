function result=powerSpectrum3D(data,options)
%POWERSPECTRUM3D Unnormalized power and spherical spectrum of a YXZ volume.
if nargin<2, options=struct(); end
result=fieldanalysis.internal.spectrum(data,3,options);
end
