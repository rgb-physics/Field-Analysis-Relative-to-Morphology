function [numElmts] = structFieldSizes(inStruct,fieldName)
%STRUCTFIELDSIZES Return the number of elements in each cell of the
%inputed structure's field with name fieldName

numElmts = cell2mat( arrayfun( @(x) numel(inStruct(x).(fieldName)), 1:numel(inStruct), 'UniformOutput', false) );

end