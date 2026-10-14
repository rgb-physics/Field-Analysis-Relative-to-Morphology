function [outMat] = consMatLnB(baseMat,indices)
%CONSMATLNB Takes in a base/"full" matrix BASEMAT and returns
% a new matrix with zeros at all indices not included in INDICES. INDICES
% is assumed to be a logic matrix with the same dimension as BASEMAT or a
% vector of positive-definite integers corresponding to indices in BASEMAT.
%CONStruct a MATrix from a set of indices/Logicals aNd a Base/og. matrix

if isa(indices, "logical")
    baseMat(~indices) = 0;
    outMat = baseMat;
else
    if isa(baseMat,"logical")
        outMat = false(size(baseMat));
    else
        outMat = zeros(size(baseMat));
    end
    outMat(indices) = baseMat(indices);
end

end

