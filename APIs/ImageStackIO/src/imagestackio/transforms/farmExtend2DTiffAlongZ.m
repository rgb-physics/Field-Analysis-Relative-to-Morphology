function [currTiff] = farmExtend2DTiffAlongZ(tiffData, repNum, saveDir)
%FARMEXTEND2DTIFFALONGZ Repeat a 2D image along Z and optionally write TIFF.
% Inputs:
%   tiffData   Numeric 2D image in YX array order.
%   repNum     Number of copies along the third array dimension.
%   saveDir    Optional output TIFF path, including filename.
% Outputs:
%   currTiff   Repeated image array, retaining the input numeric type.
%
% See also farmWriteTiff

if nargin == 2
    saveBool = 0;
else
    saveBool = 1;
end

currTiff = repmat(tiffData, [1 1 repNum]);

%Save tiff
if saveBool == 1
    farmWriteTiff(currTiff, saveDir);
end


end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Exactly two arguments disable writing. Supplying saveDir enables writing
% through farmWriteTiff with its default validation and overwrite protection.
% The full repeated array is allocated; no interpolation is performed.
%
% EXAMPLE
% -------------------------------------------------------------------------
% volume = farmExtend2DTiffAlongZ(uint16(ones(8, 10)), 4);
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Output array order is YXZ. Replication does not establish physical Z spacing.
