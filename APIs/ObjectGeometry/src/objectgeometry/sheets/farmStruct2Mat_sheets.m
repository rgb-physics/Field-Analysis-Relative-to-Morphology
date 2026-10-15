function [maskMat] = farmStruct2Mat_sheets(outputStruct,fieldNames,matSize)
%FARMSTRUCT2MAT_SHEETS Take in a structure outputStruct with indices stored in
%fieldNames. Iterate through each fieldName and construct a logical matrix
%containing all indices in fieldNames
% 2025-05-26 - Rémi Boros

maskMat = false(matSize);
for index = 1:numel(fieldNames)
    currField = fieldNames{index};
    if isfield(outputStruct,currField)
        maskMat(outputStruct.(currField)) = true;
    end
end

end


