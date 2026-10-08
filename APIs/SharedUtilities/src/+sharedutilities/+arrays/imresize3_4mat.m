function [outData] = imresize3_4mat(inData,scaleVec)
%IMRESIZE4 Takes in a a 4-matrix and returns a matrix that has undergone
%imresize3 to each layer in the 4th dimension

% Instantiate output matrix
outData = zeros([scaleVec size(inData,4)]);
% Resize each 3D matrix
for index = 1:size(inData,4)
    outData(:,:,:,index) = imresize3(inData(:,:,:,index),scaleVec,'nearest');
end

end

