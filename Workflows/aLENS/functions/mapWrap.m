function [outVals,validIns,invalidIns] = mapWrap(inVals,mapKey,mapVals,rowOpt)
%MAPWRAP Take in an array of values, a mapKey containing candidates for
%inVals for order, and an array of values to output with same number of
%rows as mapKey. This function returns map-values stored in a matrix with
%element indices corresponding to indices in inVals. Useful for moving from
%one non-overlapping matrix representation to another. This is a wrapper.
% If rowOpt is 'rows', mapping is done row-by-row. Otherwise,
% element-by-element.
% Rémi Boros - 2024-11-18, 2024-11-20

% NOTE: THIS CODE WILL MAP DEGENERACIES IN MAPKEY TO THE FIRST ASSOCIATED
% VALUES IN MAPVALS

if nargin == 3
    % Find element-indices of inVals that are in mapKey
    [sharedLogic,inOrder] = ismember(inVals,mapKey);
    % Reconstruct inVals, omitting any values that are not found in the map
    validIns = zeros(size(inVals)); outVals = validIns; invalidIns = validIns;
    validIns(sharedLogic) = mapKey(inOrder(sharedLogic));
    invalidIns(~sharedLogic) = inVals(~sharedLogic);
    % Store values from mapVals corresponding to valid inVals
    outVals(sharedLogic) = mapVals(inOrder(sharedLogic));
else
    % Find element-indices of inVals that are in mapKey
    [sharedLogic,inOrder] = ismember(inVals,mapKey,rowOpt);
    % Reconstruct inVals, omitting any values that are not found in the map
    validIns = zeros(size(inVals)); outVals = zeros(size(inVals,1),size(mapVals,2));
    validIns(sharedLogic,:) = mapKey(inOrder(sharedLogic),:);
    invalidIns(~sharedLogic,:) = inVals(~sharedLogic,:);
    % Store values from mapVals corresponding to valid inVals
    outVals(sharedLogic,:) = mapVals(inOrder(sharedLogic),:);
end



end

