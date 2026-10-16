function logstack = farmLOG(stack, sigma)
%FARMLOG Calculate the historical 2D/3D Laplacian of Gaussian.
% Inputs:
%   stack      Numeric 2D image or 3D volume.
%   sigma      Positive Gaussian standard deviation in voxels.
% Outputs:
%   logstack   Sum of second derivatives, with the input array dimensions.
%
% See also farmGaussD, farmMyconvn

    %---------------------------------------------------------------------
    % license
    %---------------------------------------------------------------------

    % Copyright 2015 Idse Heemskerk and Sebastian Streichan
    %
    % This file is part of ImSAnE.
    % 
    % ImSAnE is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License, or
    % (at your option) any later version.
    % 
    % ImSAnE is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    % 
    % You should have received a copy of the GNU General Public License
    % along with ImSAnE.  If not, see <http://www.gnu.org/licenses/>.
    %
    % We make an explicit exception giving permission to link this code
    % with GPL-incompatible matlab facilities.

    D = ndims(stack);
    
    d2 = {stack, stack, stack};

    for i = 1:D
        for j = 1:D
            % 2nd derivative if i == j
            n = 2*(i==j);
            % d2{i} = convn(d2{i}, farmGaussD(sigma, n, j), 'same');
            d2{i} = farmMyconvn(d2{i}, farmGaussD(sigma, n, j));
        end
    end
    
    % add up second derivative to get Laplacian
    if D == 2
        logstack = d2{1} + d2{2};
    elseif D == 3
        logstack = d2{1} + d2{2} + d2{3};
    end

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Preserves the bundled ImSAnE algorithm and mirrored-padding convolution.
% Each output derivative is smoothed along the other array dimensions.
% For bright-on-dark extraction, callers may explicitly use -farmLOG(...).
% No intensity stretching, physical-unit conversion or PSF correction occurs.
%
% EXAMPLE
% -------------------------------------------------------------------------
% response = -farmLOG(ones(16, 16), 1);
