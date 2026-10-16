function result = farmJointHistogram(a, b, options)
%FARMJOINTHISTOGRAM Native histcounts2 on corresponding full fields or samples.
% Inputs:
%   a               First numeric field or sample vector.
%   b               Corresponding second numeric field or sample vector.
%   options         Operation settings struct.
% Outputs:
%   result          Struct containing joint counts, bin edges and input diagnostics.

if nargin < 3
    options = struct();
end
o = farmFAOptions(options, struct('EdgesA', [], 'EdgesB', [], 'NumBins', 20));
if ~isequal(size(a), size(b)) && ~(isvector(a) && isvector(b) && numel(a) == numel(b))
    error('fieldanalysis:SizeMismatch', 'Arrays must correspond.');
end
a = farmFAField(a);
b = farmFAField(b);
if isempty(o.EdgesA) && isempty(o.EdgesB)
    validateattributes(o.NumBins, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
    if ~ismember(numel(o.NumBins), [1 2])
        error('fieldanalysis:Bins', 'NumBins must have one or two entries.');
    end
    [counts, ea, eb] = histcounts2(a(:), b(:), o.NumBins);
elseif ~isempty(o.EdgesA) && ~isempty(o.EdgesB)
    validateattributes(o.EdgesA, {'numeric'}, {'vector', 'finite', 'increasing'});
    validateattributes(o.EdgesB, {'numeric'}, {'vector', 'finite', 'increasing'});
    [counts, ea, eb] = histcounts2(a(:), b(:), o.EdgesA, o.EdgesB);
else
    error('fieldanalysis:Edges', 'Supply both edge vectors or neither.');
end
result = struct('Counts', counts, 'EdgesA', ea, 'EdgesB', eb, ...
                'InputCount', numel(a), 'ExcludedCount', numel(a) - sum(counts(:)));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMJOINTHISTOGRAM Native histcounts2 on corresponding full fields or samples.
