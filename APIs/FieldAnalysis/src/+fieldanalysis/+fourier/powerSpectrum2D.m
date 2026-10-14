function result=powerSpectrum2D(data,options)
%POWERSPECTRUM2D Unnormalized power and radial spectrum of a YX image.
if nargin<2, options=struct(); end
result=fieldanalysis.internal.spectrum(data,2,options);
end
