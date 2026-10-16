function [hannFunc] = farmGenerateNDHann(matDims)
%FARMGENERATENDHANN Takes in matrix dimensions and returns a 2D or 3D Hann
% Inputs:
%   matDims         Spatial array dimensions.
% Outputs:
%   hannFunc        Separable multidimensional Hann weighting array.

vec1 = hann(matDims(1));
vec2 = hann(matDims(2));

if numel(matDims) == 2
    hannFunc = vec1 .* vec2';
else
    vec3 = hann(matDims(3));
    hannFunc = vec1 .* vec2' .* permute(vec3, [3 2 1]);
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGENERATENDHANN Takes in matrix dimensions and returns a 2D or 3D Hann
% function of the appropriate size
