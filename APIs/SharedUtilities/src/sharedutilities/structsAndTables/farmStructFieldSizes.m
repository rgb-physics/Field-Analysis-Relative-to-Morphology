function [numElmts] = farmStructFieldSizes(inStruct, fieldName)
%FARMSTRUCTFIELDSIZES Return the number of elements in each cell of the
% Inputs:
%   inStruct        Input structure containing the requested fields.
%   fieldName       Name of the structure field.
% Outputs:
%   numElmts        Element counts for the selected field contents.

numElmts = cell2mat(arrayfun(@(x) numel(inStruct(x).(fieldName)), 1:numel(inStruct), 'UniformOutput', false));

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSTRUCTFIELDSIZES Return the number of elements in each cell of the
% inputed structure's field with name fieldName
