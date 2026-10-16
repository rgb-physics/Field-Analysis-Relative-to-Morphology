function [outData] = farmImresize3_4mat(inData, scaleVec)
%FARMIMRESIZE3_4MAT Takes in a a 4-matrix and returns a matrix that has undergone
% Inputs:
%   inData          Input numeric array.
%   scaleVec        Scalar scale factor or three-element output size passed to imresize3.
% Outputs:
%   outData         Array resized independently along each fourth-dimension entry.

% Instantiate output matrix
outData = zeros([scaleVec size(inData, 4)]);
% Resize each 3D matrix
for index = 1:size(inData, 4)
    outData(:, :, :, index) = imresize3(inData(:, :, :, index), scaleVec, 'nearest');
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMIMRESIZE3_4MAT Takes in a a 4-matrix and returns a matrix that has undergone
% imresize3 to each layer in the 4th dimension
