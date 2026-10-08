function [imageInterp] = fastLinIntNDScale2(inputStack)
%FASTLININTNDSCALE2 Takes in a matrix and scales linearly interpolates to
%scale it up by a factor of 2.

%Instantiate scaled matrix
inputDims = size(inputStack); inputStack = single(inputStack);
if numel(inputDims) == 2
    inputDims = [inputDims 0];
end
imageInterp = zeros((inputDims)*2,'single');

%Interspace input data across every other index
imageInterp(1:2:end,1:2:end,1:2:end)   = inputStack;

% interpolate columns;
imageInterp(1:2:end,2:2:end,1:2:end)   = imageInterp(1:2:end,2:2:end,1:2:end)+inputStack*.5;
imageInterp(1:2:end,2:2:end-1,1:2:end) = imageInterp(1:2:end,2:2:end-1,1:2:end)+inputStack(:,2:end,:)*.5;

% interpolate rows; 
imageInterp(2:2:end-2,:,:)     = (imageInterp(1:2:end-2,:,:) + imageInterp(3:2:end,:,:))*.5;

% interpolate depth;
imageInterp(:,:,2:2:end-2)     = (imageInterp(:,:,1:2:end-2) + imageInterp(:,:,3:2:end))*.5;

% correct edges along each dim (extend since there is no "right side" data)
imageInterp(end, 1:end, 1:end) = (imageInterp(end-1, 1:end, 1:end));
imageInterp(1:end, end, 1:end) = (imageInterp(1:end, end-1, 1:end));
imageInterp(1:end, 1:end, end) = (imageInterp(1:end, 1:end, end-1));

end

