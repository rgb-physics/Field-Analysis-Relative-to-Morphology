function outMat = farmConsObjMatSelTrajs(selectTrajs, objIDs, totTable, matDims)
%FARMCONSOBJMATSELTRAJS Historical one-frame reconstruction, corrected output.
% Inputs:
%   selectTrajs     Trajectory IDs to render.
%   objIDs          Object membership structure containing pixIDs.
%   totTable        Historical time/object/trajectory mapping.
%   matDims         Spatial array dimensions.
% Outputs:
%   outMat          One-frame array retaining selected trajectory IDs.

if istable(totTable)
    totTable = table2array(totTable);
end
selected = ismember(totTable(:, 3), selectTrajs);
rows = totTable(selected, :);
outMat = zeros(matDims);
for i = 1:size(rows, 1)
    outMat(objIDs.pixIDs{rows(i, 2)}) = rows(i, 3);
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMCONSOBJMATSELTRAJS Historical one-frame reconstruction, corrected output.
% Numeric mapping [time object trajectory], objIDs.pixIDs cell of indices.
% Native trajectory values retained; file export is a separate operation.
