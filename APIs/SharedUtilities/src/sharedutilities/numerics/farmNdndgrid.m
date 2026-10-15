function [outMat1,outMat2,outMat3] = farmNdndgrid(inVec1, inVec2, inVec3)
%FARMNDNDGRID Cases of ndgrid up from 1D to 3D for input vectors inVeci

% instantiate
outMat1 = [];   outMat2 = [];   outMat3 = [];
% If cases
if nargin == 1
    outMat1 = inVec1;
elseif nargin == 2
    [outMat1, outMat2] = ndgrid(inVec1, inVec2);
elseif nargin == 3
    [outMat1, outMat2, outMat3] = ndgrid(inVec1, inVec2, inVec3);
end


end

