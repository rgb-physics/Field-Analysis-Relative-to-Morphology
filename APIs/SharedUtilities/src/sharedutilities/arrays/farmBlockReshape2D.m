function [outMat] = farmBlockReshape2D(inMat, outCol)
%FARMBLOCKRESHAPE2D Takes in a 2D array inMat and a desired number of output
% Inputs:
%   inMat           Input numeric array.
%   outCol          Requested number of output columns.
% Outputs:
%   outMat          Array rearranged into the requested output-column blocks.

% Number of rows remains unchanged for inMat and outMat
numRows = size(inMat, 1);

if mod(size(inMat, 2), outCol) ~= 0
    error('Number of columns in requested matrix (%i) is not divisible by requested number of output columns (%i)', size(inMat, 2), outCol);
end

% Reshape and permute input matrix into matrix with requested dimensions,
% then reshape again to properly orient the matrix
reshapedIn = reshape(inMat, numRows, outCol, []);
permutedIn = permute(reshapedIn, [1 3 2]);
outMat = reshape(permutedIn, [], outCol);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMBLOCKRESHAPE2D Takes in a 2D array inMat and a desired number of output
% columns outCol. The function reshapes the requested matrix via "sub-block"
% rearrangements so long as the original number of columns in inMat is
% divisible by the requested output numbe of columns
% Eg.       1 3 5 7  9 11  with outCol = 3 gives  1  3  5
%           2 4 6 8 10 12                         2  4  6
%                                                 7  9 11
%                                                 8 10 12
% Rémi Boros - 2024-03-08
