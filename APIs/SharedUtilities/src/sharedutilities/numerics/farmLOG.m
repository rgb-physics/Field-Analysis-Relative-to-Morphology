function logstack = farmLOG(stack, sigma)
%FARMLOG Calculate the 2D/3D Laplacian of Gaussian using shared separable filters.
% Inputs:
%   stack      Numeric 2D image or 3D volume.
%   sigma      Positive Gaussian standard deviation in voxels.
% Outputs:
%   logstack   Sum of second derivatives, with the input array dimensions.
%              Single input returns single; integer/logical inputs return double.
%
% Uses the historical farmGaussD kernels with symmetric endpoint padding.
% Requires Image Processing Toolbox (imfilter).
%
% See also farmGaussD, farmMyconvn, imfilter

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

% Input and Kernel Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep integer/logical input in floating point during derivative filtering.
% Historical convn promoted these inputs to double; imfilter would otherwise
% retain their class and round or clip derivative values after each pass.
validateattributes(stack, {'numeric', 'logical'}, {'nonempty', 'nonsparse'});
validateattributes(sigma, {'numeric'}, {'real', 'finite', 'scalar', 'positive'});
dimensions = ndims(stack);
if ~ismember(dimensions, [2 3])
    error('sharedutilities:LoGDimensions', 'Use one 2-D image or 3-D volume.');
end
% Preserve the historical mirrored-padding limit on small image dimensions.
if any(size(stack) < ceil(3 * sigma))
    error('the kernel is larger than the stack!');
end
if ~isfloat(stack)
    stack = double(stack);
end

gY = farmGaussD(sigma, 0, 1);
gX = farmGaussD(sigma, 0, 2);
dYY = farmGaussD(sigma, 2, 1);
dXX = farmGaussD(sigma, 2, 2);

% YX Derivatives %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Passes 1-2: calculate Y smoothing and the Y second derivative separately.
smoothY = imfilter(stack, gY, 'symmetric', 'conv', 'same');
secondY = imfilter(stack, dYY, 'symmetric', 'conv', 'same');
% Passes 3-4: smooth Iyy along X and add the X derivative of the Y-smoothed input.
laplacianYX = imfilter(secondY, gX, 'symmetric', 'conv', 'same');
clear secondY
laplacianYX = laplacianYX + imfilter(smoothY, dXX, 'symmetric', 'conv', 'same');
if dimensions == 2
    logstack = laplacianYX;
    return
end

% Z Derivatives and Final Sum %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gZ = farmGaussD(sigma, 0, 3);
dZZ = farmGaussD(sigma, 2, 3);
% Pass 5: reuse Y smoothing for the input to the Z second derivative.
smoothYX = imfilter(smoothY, gX, 'symmetric', 'conv', 'same');
clear smoothY
% Passes 6-7: smooth the combined YX derivatives along Z, then add Izz.
logstack = imfilter(laplacianYX, gZ, 'symmetric', 'conv', 'same');
clear laplacianYX
logstack = logstack + imfilter(smoothYX, dZZ, 'symmetric', 'conv', 'same');

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Adapted from the bundled ImSAnE implementation using imfilter and shared
% intermediate smoothing. Preserves farmGaussD kernels and mirrored padding.
% Uses four axis-filter passes in 2-D and seven in 3-D. Combining terms before
% final Z smoothing can change floating-point rounding; bitwise equality to
% the original nine-pass 3-D implementation is not assumed.
% Integer/logical input is converted to double before filtering. Single input
% retains single precision. Each active image dimension must contain at least
% ceil(3*sigma) samples, matching the historical padding limit.
% Each output derivative is smoothed along the other array dimensions.
% For bright-on-dark extraction, callers may explicitly use -farmLOG(...).
% No intensity stretching, physical-unit conversion or PSF correction occurs.
%
% EXAMPLE
% -------------------------------------------------------------------------
% response = -farmLOG(ones(16, 16), 1);
