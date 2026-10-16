function ringIndMat = farmGenerateRadialMatrix(matSize, ringNum)
%FARMGENERATERADIALMATRIX Centered YX/YXZ ring IDs; zero outside included radius.
% Inputs:
%   matSize         Matrix dimensions in array-axis order.
%   ringNum         Number of radial bins within the included radius.
% Outputs:
%   ringIndMat      Centered ring IDs with zero outside the included radius.

validateattributes(matSize, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
validateattributes(ringNum, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'});
if ~ismember(numel(matSize), [2 3])
    error('fieldanalysis:Dimensions', 'Specify YX or YXZ dimensions.');
end
matSize = matSize(:)';
r2 = zeros(matSize);
for d = 1:numel(matSize)
    shape = ones(1, numel(matSize));
    shape(d) = matSize(d);
    axis = (1:matSize(d)) - (floor(matSize(d) / 2) + 1);
    r2 = r2 + reshape(axis.^2, shape);
end
edges = linspace(0, ceil(min(matSize) / 2), ringNum + 1);
[~, ~, bins] = histcounts(sqrt(r2(:)), edges);
ringIndMat = reshape(bins, matSize);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGENERATERADIALMATRIX Centered YX/YXZ ring IDs; zero outside included radius.
% Corrected even-sized grids. Origin follows fftshift: floor(N/2)+1.
