function [outXs,outYs] = getPolyCoords(yCoords,yHeights,xCoords)
%GETPOLYCOORDS Takes in a set of y-coordinates, y-heights, and optional 
% x-coordinates. Returns a set of coordinates that coorespond to a
% polynomial whose vertices are y-coordinates +/- y-heights at each
% corresponding x-coordinate. Used for plotting standard deviations over
% means.
% 2025-02-12 Rémi Boros

% Define xCoords, if not passed
if nargin == 2
    xCoords = 1:numel(yCoords);
end

% Generate x-coordinates by reflecting
outXs = [xCoords(:); flipud(xCoords(:))]';

% y-coordinates go +height one way and -height the other way
outYsPlus = yCoords + yHeights;
outYsMinus = yCoords - yHeights;
outYs = [outYsPlus, fliplr(outYsMinus)];

end

