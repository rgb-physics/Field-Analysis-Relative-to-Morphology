function mapped = farmRemapClassLabels(labels, sourceIDs, outputValues, options)
%FARMREMAPCLASSLABELS Map categorical class IDs to user-selected values.
% Inputs:
%   labels          Categorical label array.
%   sourceIDs       IDs to replace in the input label array.
%   outputValues    Replacement values corresponding to sourceIDs.
%   options         Operation settings struct.
% Outputs:
%   mapped          Categorical labels replaced with the selected stored values.

if nargin < 4 || isempty(options)
    options = struct();
end
if ~(isnumeric(labels) || islogical(labels)) || ~isreal(labels)
    error('segmentationtools:InvalidLabels', ...
          'labels must be a real numeric or logical array.');
end
validateattributes(sourceIDs, {'numeric'}, ...
                   {'real', 'finite', 'vector', 'integer', 'nonnegative'}, ...
                   mfilename, 'sourceIDs');
validateattributes(outputValues, {'numeric'}, ...
                   {'real', 'finite', 'vector', 'integer', 'nonnegative', 'numel', numel(sourceIDs)}, ...
                   mfilename, 'outputValues');
if numel(unique(sourceIDs)) ~= numel(sourceIDs)
    error('segmentationtools:DuplicateSourceIDs', ...
          'sourceIDs must be unique.');
end
if isfield(options, 'UnmappedValue')
    unmappedValue = options.UnmappedValue;
else
    unmappedValue = 0;
end
validateattributes(unmappedValue, {'numeric'}, ...
                   {'real', 'finite', 'scalar', 'integer', 'nonnegative'}, ...
                   mfilename, 'options.UnmappedValue');
if isfield(options, 'OutputType') && ~isempty(options.OutputType)
    outputType = char(string(options.OutputType));
else
    maxValue = max([double(outputValues(:)); double(unmappedValue)]);
    if maxValue <= intmax('uint8')
        outputType = 'uint8';
    elseif maxValue <= intmax('uint16')
        outputType = 'uint16';
    else
        outputType = 'uint32';
    end
end
if ~ismember(outputType, {'uint8', 'uint16', 'uint32', 'uint64'})
    error('segmentationtools:InvalidOutputType', ...
          'OutputType must be uint8, uint16, uint32, or uint64.');
end
mapped = repmat(cast(unmappedValue, outputType), size(labels));
for index = 1:numel(sourceIDs)
    mapped(labels == sourceIDs(index)) = cast(outputValues(index), outputType);
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMREMAPCLASSLABELS Map categorical class IDs to user-selected values.
%   MAPPED = REMAPCLASSLABELS(LABELS, SOURCEIDS, OUTPUTVALUES) replaces
%   each SOURCEIDS value with its corresponding OUTPUTVALUES value.
%   Background/unclassified zero remains zero by default.
%
%   OPTIONS.UnmappedValue defaults to zero. OPTIONS.OutputType may be a
%   MATLAB integer class name. If omitted, the smallest unsigned integer
%   type that can represent OUTPUTVALUES and UnmappedValue is selected.
