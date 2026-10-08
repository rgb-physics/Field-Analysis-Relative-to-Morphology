function [outMat] = consObjMatSelTrajs(selectTrajs, objIDs, totTable, matDims)
%CONSOBJMATSELTRAJS This function takes in a vector of requested
%trajectories SELECTTRAJS, a structure of indices corresponding to object
%locations called OBJIDS, a table of times, objects, and trajectories for
%the desired time (ONE TIME ONLY), and a table
%called TOTTABLE to be used as a map for selecting appropriate objects. The
%function returns a binarized matrix OUTMAT with ones at indices
%corresponding to objects in the requested trajectories and zeroes
%elsewhere. MATDIMS are the dimensions of the desired output matrix
%OUTMAT objects have different values corresponding to trajectory ID stored
%at appopriate indices

% Define variables for clarity
trajInds = ismember(totTable(:,3), selectTrajs);
selObjs = totTable(trajInds,2);
selTrajs = totTable(trajInds,3);

% Iterate through trajectories and store 1s in object indices
outMat = zeros(matDims);
for trajID = 1:numel(selTrajs)
    matDims(objIDs.pixIDs{selObjs(trajID)}) = selTrajs(trajID);
end

end

