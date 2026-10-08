function [vanHove] = generateVanHove(dataSet)
%GENERATEVANHOVE takes in a field (2D or 3D) and returns the van Hove
%function varying over each dimension in the input data set.

%Generate matrix to scale dataSet by to properly normalize
scaleMat = genCorrScaleMat(size(dataSet));

%Calculate correlation using fft
fftpH = fftn(dataSet);
prodpH = fftpH.*conj(fftpH);
corrpH = ifftshift(ifftn(prodpH));
vanHove = corrpH./scaleMat;       %apply hann function on full or partial image?

end

