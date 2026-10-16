function convolved = farmMyconvn(stack, filter)
%FARMMYCONVN Convolve an array using the historical mirrored padding.
% Inputs:
%   stack       Numeric 2D image or 3D volume.
%   filter      Convolution kernel; normally odd-sized Gaussian derivatives.
% Outputs:
%   convolved   Result of mirrored padding followed by convn(..., 'valid').
%
% See also farmGaussD, farmLOG

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
    kersize = size(filter);
    padsize = ceil(kersize / 2) - 1;
    
    if padsize(1) > size(stack, 1) || padsize(2) > size(stack, 2) ||...
        ( numel(padsize) > 2 && padsize(3) > size(stack,3) )
        
        error('the kernel is larger than the stack!');
    end
    
    dim = 1;
    if padsize(dim) > 0

        padding = flip(stack(end-padsize(dim) + 1:end, :, :), dim);
        stack = cat(dim, stack, padding);
        padding = flip(stack(1: padsize(dim), :, :), dim);
        stack = cat(dim, padding, stack);
    end
    
    dim = 2;
    if padsize(dim) > 0 

        padding = flip(stack(:, end-padsize(dim) + 1:end, :), dim);
        stack = cat(dim, stack, padding);
        padding = flip(stack(:, 1: padsize(dim), :), dim);
        stack = cat(dim, padding, stack);
    end
    
    dim = 3;
    if numel(padsize) > 2 && padsize(dim) > 0

        padding = flip(stack(:, :, end-padsize(dim) + 1:end), dim);
        stack = cat(dim, stack, padding);
        padding = flip(stack(:, :, 1: padsize(dim)), dim);
        stack = cat(dim, padding, stack);
    end

    convolved = convn(stack, filter, 'valid');
    
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Preserves the bundled ImSAnE padding and convolution implementation.
% Padding along each dimension is ceil(size(filter) / 2) - 1.
% Odd-sized kernels preserve input dimensions. Even-sized kernels can reduce
% a dimension; this historical behavior is unchanged. Oversized padding errors.
% No filtering or normalization beyond the supplied kernel is inferred.
%
% EXAMPLE
% -------------------------------------------------------------------------
% result = farmMyconvn(ones(16, 16), farmGaussD(1, 0, 2));
