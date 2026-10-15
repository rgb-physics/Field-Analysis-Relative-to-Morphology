function [scalerMat] = farmConsScalerMat(inputData,patchProbs)
%FARMCONSSCALERMAT Used specifically to generate a matrix that will scale
%inputData by the values stored in patchProbs, accounting for cases in
%which the input data has zero values for a set of indices pointed to by
%patchProbs. In these cases, the "holes" are filled by the maximum value in
%the input data at the corresponding (x,y) coordinates
% Rémi Boros

scalerMat = max(farmConsMatLnB(inputData,logical(patchProbs)),[],3);
if ~isempty(find(scalerMat == 0, 1))
    maxVals = max(inputData,[],3);
    scalerMat(scalerMat == 0) = maxVals(scalerMat == 0);
end

end

