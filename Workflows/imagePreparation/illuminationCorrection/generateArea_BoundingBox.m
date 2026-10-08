function [areaMat] = generateArea_BoundingBox(holeBox,imgSize)
%GENERATEAREA_BOUNDINGBOX Takes in a vector HOLEBOX of bounding box
%information structured as [xmin ymin xwidth ywidth] and a vector IMGSIZE
%with the dimensions of the the object is located. The function returns a
%logic matrix with 1s stored INSIDE the area defined by the bounding box,
%located at the appropriate coordinates. 

% Define minimum and maximum indices
colmin = round(holeBox(1))-1;
colmax = round(holeBox(1)+holeBox(3));
rowmin = round(holeBox(2))-1;
rowmax = round(holeBox(2)+holeBox(4));

% Get Interior coordinates
xRange = max(min(imgSize(1),rowmin+1),1):min(max(1,rowmax-1),imgSize(1));
yRange = max(min(imgSize(2),colmin+1),1):min(max(1,colmax-1),imgSize(2));
% Assign values to the area in the event that the bounding box is of size 1
% and located on the image perimeter
if isempty(xRange)
    xRange = round(holeBox(2));
end
if isempty(yRange)
    yRange = round(holeBox(1));
end
% Using meshgrid, generate the indices of 1s and assign 1s
[intX, intY] = meshgrid(xRange,yRange);
areaMat = logical(zeros(imgSize(1),imgSize(2)));
areaMat(intX, intY) = 1;


end

