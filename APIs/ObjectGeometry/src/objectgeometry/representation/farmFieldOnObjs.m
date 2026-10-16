function [outMat, objInds, validLogic] = farmFieldOnObjs(inField, matDims, objInds, validLogic)
%FARMFIELDONOBJS Assign one scalar per object to its voxel indices.
% Inputs:
%   inField     One scalar per object, in row order of validLogic.
%   matDims     Output matrix dimensions in MATLAB array order.
%   objInds     Linear voxel indices, ordered to match repField(validLogic).
%   validLogic  Logical array: objects by maximum number of samples.
% Outputs:
%   outMat      Double matrix; unassigned locations are zero.
%   objInds     Input indices, returned unchanged.
%   validLogic  Input selection array, returned unchanged.

% Allocate the output and repeat each object's value across its samples.
outMat = zeros(matDims);
repNum = size(validLogic, 2);
repField = repmat(inField(:), 1, repNum);

% MATLAB logical indexing selects samples in column order.
outMat(objInds) = repField(validLogic);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% The number of objInds entries must match nnz(validLogic). Each true entry
% selects the value for that row's object. The indices must follow the same
% column-major order as this logical selection, rather than grouping all
% indices of the first object before those of the second object.
% Repeated output indices retain the last assigned value. No averaging or
% overlap detection occurs. MATLAB reports incompatible dimensions or indices.
% Values retain their supplied units; no coordinate or unit conversion occurs.
%
% EXAMPLES
% -------------------------------------------------------------------------
% Two objects with two samples each, interleaved by sample column:
%   values = farmFieldOnObjs([10; 20], [2 3], [1; 2; 4; 5], true(2, 2));
% Unequal sample counts, with the selection order made explicit:
%   selected = logical([1 1; 1 0]);
%   values = farmFieldOnObjs([10; 20], [2 3], [1; 2; 4], selected);
%
% Adapted from fieldOnObjs.m, supplied by the author for inclusion in FARM.
% Original attribution: Rémi Boros, m2024-10-19.
