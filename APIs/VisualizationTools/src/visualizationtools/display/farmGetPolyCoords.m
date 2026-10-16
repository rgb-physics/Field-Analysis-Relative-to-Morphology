function [outXs, outYs] = farmGetPolyCoords(yCoords, yHeights, xCoords)
%FARMGETPOLYCOORDS Construct polygon vertices around central Y values.
% Inputs:
%   yCoords         Central Y values of the plotted envelope.
%   yHeights        Positive/negative offsets from the central Y values.
%   xCoords         Optional corresponding X coordinates.
% Outputs:
%   outXs           X vertices of the spread polygon.
%   outYs           Y vertices of the spread polygon.

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

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGETPOLYCOORDS Takes in a set of y-coordinates, y-heights, and optional
% x-coordinates. Returns a set of coordinates that coorespond to a
% polynomial whose vertices are y-coordinates +/- y-heights at each
% corresponding x-coordinate. Used for plotting standard deviations over
% means.
% 2025-02-12 Rémi Boros
