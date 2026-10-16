function dG = farmGaussD(sigma, n, varargin)
%FARMGAUSSD Construct a sampled one-dimensional Gaussian derivative kernel.
% Inputs:
%   sigma      Positive Gaussian standard deviation in voxels.
%   n          Derivative order: 0, 1 or 2.
%   varargin   Optional array dimension: 1 (column), 2 (row) or 3.
% Outputs:
%   dG         Kernel oriented along the selected array dimension.
%
% See also farmLOG, farmMyconvn

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
    
    % it is common to take the kernel 2.5sigma wide
    N = ceil(3*sigma);
    X = ndgrid(-N:N);
    
    % Gaussian
    G = exp(-X.^2/(2*sigma^2));
    % normalize
    G = G / sum(G(:));
    
    if n==0
        dG = G;
    elseif n==1
        dG = -(X/sigma^2).*G;        % derivative
    elseif n==2
        dG = (X.^2/sigma^4 - 1/sigma^2).*G;
    else
        error('not implemented for this n');
        % can implement general with Hermite polynomials or something
    end    
    
    if nargin == 3
        d = varargin{1};
        if d == 2
            dG = dG';
        elseif d==3
            dG = reshape(dG, [1 1 length(dG)]);
        end
    end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Preserves the bundled ImSAnE formulas and support -ceil(3*sigma):ceil(3*sigma).
% The sampled Gaussian is normalized before differentiation. Derivative
% kernels are not subsequently renormalized. Dimensions are array dimensions,
% not named XYZ components; no physical-unit conversion is performed.
%
% EXAMPLES
% -------------------------------------------------------------------------
% gaussian = farmGaussD(1, 0);
% dxKernel = farmGaussD(1, 1, 2);
