function [outMat1, outMat2, outMat3] = farmNdmeshgrid(inVec1, inVec2, inVec3)
%FARMNDMESHGRID Cases of meshgrid up from 1D to 3D for input vectors inVeci
% Inputs:
%   inVec1          First coordinate vector.
%   inVec2          Optional second coordinate vector.
%   inVec3          Optional third coordinate vector.
% Outputs:
%   outMat1         First coordinate array.
%   outMat2         Second coordinate array when requested.
%   outMat3         Third coordinate array when requested.

% instantiate
outMat1 = [];
outMat2 = [];
outMat3 = [];
% If cases
if nargin == 1
    outMat1 = inVec1;
elseif nargin == 2
    [outMat1, outMat2] = meshgrid(inVec1, inVec2);
elseif nargin == 3
    [outMat1, outMat2, outMat3] = meshgrid(inVec1, inVec2, inVec3);
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMNDMESHGRID Cases of meshgrid up from 1D to 3D for input vectors inVeci
