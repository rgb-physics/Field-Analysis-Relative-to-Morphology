function outKs = farmGenScaledKVec(dimSize, dimdx)
%FARMGENSCALEDKVEC Frequencies in cycles per length, ordered like fftshift(fft).
% Inputs:
%   dimSize         Number of samples on the axis.
%   dimdx           Sample spacing along that axis.
% Outputs:
%   outKs           Shifted frequencies in cycles per spacing unit.

if nargin < 2
    dimdx = 1;
end
validateattributes(dimSize, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'});
validateattributes(dimdx, {'numeric'}, {'scalar', 'positive', 'finite'});
outKs = (-floor(dimSize / 2):ceil(dimSize / 2) - 1) / (dimSize * dimdx);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGENSCALEDKVEC Frequencies in cycles per length, ordered like fftshift(fft).
% For N samples: (-floor(N/2):ceil(N/2)-1)/(N*spacing).
