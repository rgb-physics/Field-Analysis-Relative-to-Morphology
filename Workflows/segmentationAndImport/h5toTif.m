function [outData] = h5toTif(inData,scaleFacts,binarizeBool,threshVals,distinguishBool)
%H5TOTIF Takes in a matrix directly loaded with loadH5.m INDATA and returns
%a matrix that can be saved as a 3D .tif. SCALEFACTS is a vector that
%determines how to rescale the dimensions of inData, assuming the matrix is
%passed in [x,y,z,chan] form. binarizeBool is a boolean used to determine
%whether or not to binarize 

% Reformat scaleFacts if not a 3 vector
if numel(scaleFacts) == 1
    scaleFacts = [scaleFacts scaleFacts scaleFacts];
elseif numel(scaleFacts) == 2
    scaleFacts = [scaleFacts 1];
end

% Reformat threshVals if not a 3 vector
if numel(threshVals) == 1
    threshVals = repmat(threshVals,1,size(inData,4));
end

% Define size of output matrix
[xSize,ySize,zSize,~] = size(inData);
newDims = [xSize ySize zSize].*scaleFacts;

% Iterate through each channel, resize, binarize (if requested)
outData = zeros(newDims(1), newDims(2), newDims(3), size(inData,4));
for chanInd = 1:numel(size(inData,4))
    currChan = inData(:,:,:,chanInd);
    % Resize, if required
    if prod(scaleFacts) ~= 1
        currChan = imresize3(currChan, newDims);
    end
    %Binarize, if requested
    if binarizeBool == 1
        currChan = imbinarize(currChan, threshVals(chanInd));
    end
    outData(:,:,:,chanInd) = currChan;
end

% Channel distinction
[maxMat,indMat] = max(outData,[],4);
if distinguishBool == 1
    outData = consMatLnB(indMat, ~(maxMat == 0));
else
    outData = ~maxMat == 0;
end

%Convert to 8bit
outData = uint8(255*outData/size(inData,4));

end

