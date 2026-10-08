function [outMat,objInds,validLogic] = fieldOnObjs(inField,matDims,objInds,validLogic)
%FIELDONFILS Used to assign values of a field into all indices
%corresponding to specific object IDs. INFIELD of scalar values, one for
%each object ID. MATDIMS is the dimension of the matrix objects reside in.
%OBJINDS is a vector of indices used to map field values to objects.
%VALIDLOGIC is a binary matrix with dims (num objs) x (max num indices),
%with each row containing a number of ones/trues equal to the number of
%indices in the corresponding object. 
% The function uses repmat to extend the input field to a 2D matrix with
% the same size as validLogic. It then uses validLogic to select an
% appropriate number of copies of the field to assign to each index in each
% object. Lastly, it uses objInds as a map to assign field values to the
% output matrix
% Rémi Boros, m2024-10-19

% Instantiate out matrix and replicated field matrix
outMat = zeros(matDims);
repNum = size(validLogic,2);
repField = repmat(inField(:),1,repNum);

% Assign filament IDs to out matrix
outMat(objInds) = repField(validLogic);

end

