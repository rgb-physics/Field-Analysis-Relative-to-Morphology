function [numElmts] = farmStructFieldSizes(inStruct,fieldName)
%FARMSTRUCTFIELDSIZES Return the number of elements in each cell of the
%inputed structure's field with name fieldName

numElmts = cell2mat( arrayfun( @(x) numel(inStruct(x).(fieldName)), 1:numel(inStruct), 'UniformOutput', false) );

end