function outKs=genScaledKVec(dimSize,dimdx)
%GENSCALEDKVEC Frequencies in cycles per length, ordered like fftshift(fft).
% For N samples: (-floor(N/2):ceil(N/2)-1)/(N*spacing).
if nargin<2, dimdx=1; end
validateattributes(dimSize,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(dimdx,{'numeric'},{'scalar','positive','finite'});
outKs=(-floor(dimSize/2):ceil(dimSize/2)-1)/(dimSize*dimdx);
end
