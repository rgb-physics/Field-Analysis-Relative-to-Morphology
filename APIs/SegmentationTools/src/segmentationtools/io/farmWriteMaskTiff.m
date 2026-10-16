function farmWriteMaskTiff(mask, filePath, options)
%FARMWRITEMASKTIFF Write a requested mask representation to TIFF.
% Inputs:
%   mask            Binary foreground matrix or volume.
%   filePath        Full input or output file path, including filename.
%   options         Operation settings struct.
% Outputs:
%   None. Requested file or graphics side effects occur during the call.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~(isnumeric(mask) || islogical(mask)) || ~isreal(mask) || isempty(mask)
    error('segmentationtools:InvalidMask', ...
          'mask must be a nonempty real numeric or logical array.');
end
if ndims(mask) > 4
    error('segmentationtools:InvalidMaskDimensions', ...
          'mask must have [Y X Z] or [Y X Z C] dimensions.');
end
if islogical(mask)
    output = mask;
else
    if any(~isfinite(mask(:))) || any(mask(:) < 0) || ...
            any(mask(:) ~= fix(mask(:)))
        error('segmentationtools:InvalidMaskValues', ...
              'Numeric masks must contain finite nonnegative integers.');
    end
    maxValue = double(max(mask(:)));
    if maxValue <= intmax('uint8')
        output = uint8(mask);
    elseif maxValue <= intmax('uint16')
        output = uint16(mask);
    else
        error('segmentationtools:TiffValueRange', ...
              ['ImageStackIO TIFF writers currently support values through ' ...
               'uint16. Store larger lineage IDs in MAT/HDF5 or remap them.']);
    end
end

if ndims(output) <= 3 || size(output, 4) == 1
    farmWriteTiff(output(:, :, :, 1), filePath, options);
else
    image = struct('Data', reshape(output, size(output, 1), size(output, 2), ...
                                   size(output, 3), size(output, 4), 1), 'Axes', 'YXZCT');
    farmWriteImageJHyperstack(image, filePath, options);
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMWRITEMASKTIFF Write a requested mask representation to TIFF.
%   WRITEMASKTIFF(MASK, FILEPATH, OPTIONS) writes logical or nonnegative
%   integer-valued [Y X Z] data using farmWriteTiff. [Y X Z C]
%   data is written as an ImageJ hyperstack with singleton time.
%
%   This function performs no class remapping. Use remapClassLabels first
%   when stored values such as 85/170/255 are required. Files are created
%   only when this function is called.
