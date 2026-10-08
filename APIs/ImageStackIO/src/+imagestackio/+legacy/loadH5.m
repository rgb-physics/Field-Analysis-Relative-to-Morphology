function [selMat] = loadH5(filePath,inString,chanNum,chanDim,dimOrder)
%LOADH5 Loads an h5 stored in the filePath (including directory and
%filename included) with the field passed in inString. It is assumed that
%the dimensions of the .h5 will be cyx(z) by default. Optionally, one can
%pass the dimensions of the .h5 with x = 1, y = 2, z = 3, c = 4 in a vector
%of the form [# # # #]; This vector will then permute the .h5 before
%returning the data in [x y z c] form. chanNum is the channel number(s) to
%isolate.

% Ensure that string is in correct format
if ~strcmp(inString(1),'/')
    inString = ['/' inString];
end

% Load .h5
allData = h5read(filePath,inString);

% Rearrange dimensions
if nargin < 3
    chanNum = 1;
end
if nargin < 4
    chanDim = 1;
end
if nargin < 5
    dimOrder = 1:numel(size(allData));
    dimOrder(1:2) = dimOrder(2:-1:1);
    dimOrder = circshift(dimOrder,1);           % [c y x (layers)] is expected as default from Ilastik
end

[~,sortOrder] = sort(dimOrder);

% Prepermute data to get channel as dim 1
permOrder = 1:4;
permOrder(1) = dimOrder(chanDim);
permOrder(chanDim) = 1;

% Isolate channel data
permData = permute(allData,permOrder); permDims = size(permData);
selData = permute(reshape(permData(chanNum,:),[numel(chanNum) permDims(2:end)]),permOrder);
selMat = squeeze(permute(selData,sortOrder));

end

