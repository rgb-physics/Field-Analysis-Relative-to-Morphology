function [outMat] = farmConsMatLnB(baseMat, indices)
%FARMCONSMATLNB Takes in a base/"full" matrix BASEMAT and returns
% Inputs:
%   baseMat         Base array providing retained values and output size.
%   indices         Logical selection or numeric linear indices to retain.
% Outputs:
%   outMat          Base values at selected locations, zero elsewhere.

if isa(indices, "logical")
    baseMat(~indices) = 0;
    outMat = baseMat;
else
    if isa(baseMat, "logical")
        outMat = false(size(baseMat));
    else
        outMat = zeros(size(baseMat), 'like', baseMat);
    end
    outMat(indices) = baseMat(indices);
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMCONSMATLNB Takes in a base/"full" matrix BASEMAT and returns
% a new matrix with zeros at all indices not included in INDICES. INDICES
% is assumed to be a logic matrix with the same dimension as BASEMAT or a
% vector of positive-definite integers corresponding to indices in BASEMAT.
% CONStruct a MATrix from a set of indices/Logicals aNd a Base/og. matrix
