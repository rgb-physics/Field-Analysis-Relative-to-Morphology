function [data, sourceDimensions] = farmNormalizeAxes(data, sourceAxes)
%FARMNORMALIZEAXES Reorder labeled image dimensions into [Y X Z C T].

canonicalAxes = 'YXZCT';
sourceAxes = upper(sourceAxes);
numSourceAxes = numel(sourceAxes);

if numSourceAxes < ndims(data)
    extraDimensions = arrayfun(@(dimension) size(data, dimension), ...
        numSourceAxes + 1:ndims(data));
    if any(extraDimensions ~= 1)
        error('imagestackio:SourceAxesDimensionCount', ...
            ['SourceAxes has %d labels, but the HDF5 array has additional ' ...
             'non-singleton dimensions.'], numSourceAxes);
    end
end

sourceDimensions = arrayfun(@(dimension) size(data, dimension), ...
    1:numSourceAxes);
data = reshape(data, sourceDimensions);

presentAxes = canonicalAxes(ismember(canonicalAxes, sourceAxes));
permutation = arrayfun(@(axis) find(sourceAxes == axis, 1), presentAxes);
data = permute(data, permutation);

canonicalDimensions = ones(1, numel(canonicalAxes));
for sourceIndex = 1:numSourceAxes
    canonicalIndex = find(canonicalAxes == sourceAxes(sourceIndex), 1);
    canonicalDimensions(canonicalIndex) = sourceDimensions(sourceIndex);
end
data = reshape(data, canonicalDimensions);
end
