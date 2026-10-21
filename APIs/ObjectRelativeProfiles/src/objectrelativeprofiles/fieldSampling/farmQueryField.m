function results = farmQueryField(field, inputSupport, requested, options)
%FARMQUERYFIELD Scalar/component statistics at indices, masks or ID groups.
% Inputs:
%   field           Numeric field array or a struct containing Data and grid metadata.
%   inputSupport    Sampling indices, mask, labels, index groups or prepared geometry/support.
%   requested       Names of the properties or statistics to calculate.
%   options         Optional scalar struct with the fields:
%                   FieldName = character vector or string scalar;
%                   Support = scalar struct;
%                   Grid = scalar struct or [];
%                   Quantiles = numeric vector in [0, 1];
%                   BinEdges = numeric vector or [];
%                   NumBins = positive integer scalar or [];
%                   VarianceNormalization = numeric scalar (0 or 1);
%                   SampleOperation = function handle or [];
%                   CustomOperations = scalar struct of function handles;
% Outputs:
%   results         Identity columns, requested statistics and sampling diagnostics.
%
% Supply indices or a prepared Support to choose where values are read.
% For one output row per index, supply num2cell(indices(:)) as inputSupport.
% A numeric index vector instead defines one group for combined statistics.
% Mean at one selected location returns that location's finite value; an
% empty or nonfinite-only group returns NaN for Mean and zero for Count.
% Values and their units come from the supplied field; no calibration is inferred.
% Enter farmGlossary("Support") for selection types and the Data Dictionary
% entries SelectedCount and FiniteCount for sampling diagnostics.
%
% See also farmPrepareSupport, farmQueryVectorField, farmAttachResults

if nargin < 3 || isempty(requested)
    requested = {'Mean'};
end
if nargin < 4
    options = struct();
end
options = farmOGOptions(options, struct('FieldName', 'Field', 'Support', struct(), ...
                                       'Grid', [], 'Quantiles', [.25 .5 .75], 'BinEdges', [], 'NumBins', [], ...
                                       'VarianceNormalization', 0, 'SampleOperation', [], 'CustomOperations', struct()));
% Output Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name the requested statistics and diagnostic columns for this field.
name = char(string(options.FieldName));
if ~isvarname(name)
    error('objectrelativeprofiles:InvalidFieldName', 'FieldName must be a valid MATLAB identifier.');
end
validateattributes(options.VarianceNormalization, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 1});
validateattributes(options.Quantiles, {'numeric'}, {'real', 'finite', 'vector', '>=', 0, '<=', 1});
if ~isempty(options.BinEdges)
    validateattributes(options.BinEdges, {'numeric'}, {'real', 'vector', 'nondecreasing'});
    if numel(options.BinEdges) < 2 || any(diff(options.BinEdges) <= 0) || any(isnan(options.BinEdges))
        error('objectrelativeprofiles:InvalidBins', 'Edges must strictly increase.');
    end
end
if ~isempty(options.NumBins)
    validateattributes(options.NumBins, {'numeric'}, {'scalar', 'integer', 'positive'});
end
if ~isempty(options.NumBins) && ~isempty(options.BinEdges)
    error('objectrelativeprofiles:InvalidBins', 'Choose bin count OR edges.');
end
stats = {'Count', 'Sum', 'Mean', 'Median', 'Variance', 'Std', 'Min', 'Max', 'Quantiles', 'Histogram'};
requested = cellstr(string(requested));
requested = requested(:).';
if any(strcmpi(requested, 'all'))
    requested = stats;
end
for i = 1:numel(requested)
    requested{i} = validatestring(requested{i}, stats);
end
requested = unique(requested, 'stable');
if ~isstruct(options.CustomOperations) || ~isscalar(options.CustomOperations)
    error('objectrelativeprofiles:InvalidCustomOperations', 'Supply a scalar struct of named function handles.');
end
custom = fieldnames(options.CustomOperations);
reserved = [stats {'SelectedCount', 'FiniteCount', 'NaNCount', 'PositiveInfCount', 'NegativeInfCount', ...
                   'SelectionEmpty', 'GeometryEmpty', 'EmptyGeometryCount', 'UsedFallback', 'FallbackCount'}];
if any(ismember(lower(string(custom)), lower(string(reserved))))
    error('objectrelativeprofiles:CustomNameCollision', 'Custom names must differ from statistics and diagnostic names.');
end
for column = [reserved custom.']
    if ~isvarname([name '_' column{1}])
        error('objectrelativeprofiles:InvalidFieldName', 'FieldName plus statistic name exceeds MATLAB identifier limits.');
    end
end
for i = 1:numel(custom)
    if ~isa(options.CustomOperations.(custom{i}), 'function_handle')
        error('objectrelativeprofiles:InvalidCustomOperation', 'Use function handles.');
    end
end
% Sampled Fields %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read one scalar field, or combine named fields with a supplied operation.
if isempty(options.SampleOperation)
    [data, fieldGrid] = localField(field);
    sources = {'value'};
    fields = struct('value', data);
    sourceGrids = struct('value', fieldGrid);
else
    if ~isa(options.SampleOperation, 'function_handle') || ~isstruct(field) || ~isscalar(field) || isfield(field, 'Data')
        error('objectrelativeprofiles:InvalidSampleOperation', 'Use a function handle and a named field collection.');
    end
    sources = fieldnames(field);
    if isempty(sources)
        error('objectrelativeprofiles:EmptyFields', 'Supply at least one field.');
    end
    fields = struct();
    fieldGrid = struct();
    sourceGrids = struct();
    for i = 1:numel(sources)
        [value, grid] = localField(field.(sources{i}));
        if i == 1
            data = value;
            fieldGrid = grid;
        elseif ~isequal(size(value), size(data))
            error('objectrelativeprofiles:GridMismatch', 'Combined fields must have matching dimensions.');
        end
        fields.(sources{i}) = value;
        sourceGrids.(sources{i}) = grid;
    end
end
if ~isempty(options.Grid)
    fieldGrid = options.Grid;
end
sz = [size(data, 1) size(data, 2) size(data, 3)];
if isfield(fieldGrid, 'Size')
    localMatch(fieldGrid.Size, sz);
end
% Sampling Locations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare one set of selected indices for each identified object/component.
support = farmPrepareSupport(inputSupport, sz, options.Support);
n = numel(support.Records);
results = table(repmat(string(support.DatasetID), n, 1), repmat(support.Frame, n, 1), ...
                reshape([support.Records.ObjectID], [], 1), reshape([support.Records.ComponentID], [], 1), ...
                'VariableNames', {'DatasetID', 'Frame', 'ObjectID', 'ComponentID'});
flagNames = {'SelectedCount', 'FiniteCount', 'NaNCount', 'PositiveInfCount', 'NegativeInfCount', ...
             'SelectionEmpty', 'GeometryEmpty', 'EmptyGeometryCount', 'UsedFallback', 'FallbackCount'};
for i = 1:numel(flagNames)
    results.([name '_' flagNames{i}]) = zeros(n, 1);
end
for i = 1:numel(requested)
    stat = requested{i};
    if strcmp(stat, 'Histogram')
        results.([name '_' stat]) = cell(n, 1);
    elseif strcmp(stat, 'Quantiles')
        results.([name '_' stat]) = nan(n, numel(options.Quantiles));
    else
        results.([name '_' stat]) = nan(n, 1);
    end
end
for i = 1:numel(custom)
    results.([name '_' custom{i}]) = cell(n, 1);
end
% Field Sampling and Statistics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read each group's values and retain finite/nonfinite counts separately.
% Read single-voxel selections together, retaining one output row per group.
% Custom operations and histograms retain the general calculation below.
rowsToCalculate = 1:n;
if n > 0 && isempty(options.SampleOperation) && isempty(custom) && ...
        ~ismember('Histogram', requested) && all(arrayfun(@(r) numel(r.Indices) == 1, support.Records))
    indices = vertcat(support.Records.Indices);
    values = double(data(indices));
    values = values(:);
    finite = isfinite(values);
    results.([name '_SelectedCount']) = ones(n, 1);
    results.([name '_FiniteCount']) = double(finite);
    results.([name '_NaNCount']) = double(isnan(values));
    results.([name '_PositiveInfCount']) = double(values == Inf);
    results.([name '_NegativeInfCount']) = double(values == -Inf);
    for j = 7:10
        results.([name '_' flagNames{j}]) = double(reshape([support.Records.(flagNames{j})], [], 1));
    end
    finiteValues = values;
    finiteValues(~finite) = NaN;
    for j = 1:numel(requested)
        stat = requested{j};
        switch stat
            case 'Count'
                output = double(finite);
            case 'Sum'
                output = values;
                output(~finite) = 0;
            case {'Variance', 'Std'}
                output = nan(n, 1);
                output(finite) = 0;
            case 'Quantiles'
                output = repmat(finiteValues, 1, numel(options.Quantiles));
            otherwise
                % Mean, Median, Min and Max equal the single finite value.
                output = finiteValues;
        end
        results.([name '_' stat]) = output;
    end
    rowsToCalculate = [];
end
for row = rowsToCalculate
    record = support.Records(row);
    indices = record.Indices;
    if isempty(options.SampleOperation)
        values = double(data(indices));
    else
        samples = struct();
        for j = 1:numel(sources)
            source = fields.(sources{j});
            samples.(sources{j}) = double(source(indices));
        end
        values = options.SampleOperation(samples);
        if ~isnumeric(values) || ~isreal(values) || numel(values) ~= numel(indices) || (~isempty(values) && ~isvector(values))
            error('objectrelativeprofiles:SampleShape', 'SampleOperation must return one real value per selected index.');
        end
    end
    values = double(values(:));
    finite = values(isfinite(values));
    counts = [numel(values) numel(finite) nnz(isnan(values)) nnz(values == Inf) nnz(values == -Inf)];
    for j = 1:5
        results.([name '_' flagNames{j}])(row) = counts(j);
    end
    results.([name '_SelectionEmpty'])(row) = isempty(indices);
    for j = 7:10
        results.([name '_' flagNames{j}])(row) = record.(flagNames{j});
    end
    for j = 1:numel(requested)
        stat = requested{j};
        column = [name '_' stat];
        switch stat
            case 'Count'
                output = numel(finite);
            case 'Sum'
                output = sum(finite);
            case 'Histogram'
                if ~isempty(options.BinEdges)
                    [counts, edges] = histcounts(finite, options.BinEdges);
                elseif ~isempty(options.NumBins)
                    [counts, edges] = histcounts(finite, options.NumBins);
                else
                    [counts, edges] = histcounts(finite);
                end
                results.(column){row} = struct('Counts', counts, 'Edges', edges);
                continue
            otherwise
                if isempty(finite)
                    continue
                end
                switch stat
                    case 'Mean'
                        output = mean(finite);
                    case 'Median'
                        output = median(finite);
                    case 'Variance'
                        output = var(finite, options.VarianceNormalization);
                    case 'Std'
                        output = std(finite, options.VarianceNormalization);
                    case 'Min'
                        output = min(finite);
                    case 'Max'
                        output = max(finite);
                    case 'Quantiles'
                        output = quantile(finite, options.Quantiles);
                end
        end
        results.(column)(row, :) = output(:).';
    end
    for j = 1:numel(custom)
        results.([name '_' custom{j}]){row} = options.CustomOperations.(custom{j})(finite);
    end
end
for flag = {'SelectionEmpty', 'GeometryEmpty', 'UsedFallback'}
    column = [name '_' flag{1}];
    results.(column) = logical(results.(column));
end
differences = struct();
sourceGrids.EffectiveGrid = fieldGrid;
gridNames = fieldnames(sourceGrids);
for g = 1:numel(gridNames)
    grid = sourceGrids.(gridNames{g});
    if isfield(grid, 'Size')
        localMatch(grid.Size, sz);
    end
    for key = {'Spacing', 'SpacingUnit', 'Axes', 'Origin', 'GridID', 'Transform'}
        k = key{1};
        if isfield(grid, k) && isfield(support.Grid, k) && ~isequal(grid.(k), support.Grid.(k))
            differences.(gridNames{g}).(k) = struct('Field', grid.(k), 'Support', support.Grid.(k));
        end
    end
end
results.Properties.UserData = struct('FieldName', name, 'SupportName', support.Name, ...
                                     'FieldGrid', fieldGrid, 'SourceGrids', sourceGrids, 'SupportGrid', support.Grid, 'MetadataDifferences', differences, ...
                                     'CorrespondenceVerified', false, 'Options', options, 'FiniteSamplesOnly', true);
end

function [data, grid] = localField(input)
% Internal helper.
grid = struct();
if isstruct(input) && isscalar(input) && isfield(input, 'Data')
    data = input.Data;
    if isfield(input, 'Grid')
        grid = input.Grid;
    end
else
    data = input;
end
validateattributes(data, {'numeric', 'logical'}, {'real', 'nonempty', 'nonsparse'});
if ndims(data) > 3
    error('objectrelativeprofiles:InvalidDimensions', 'Load one XYZ scalar/component field, not XYZT data.');
end
end

function localMatch(actual, expected)
% Internal helper.
actual = double(actual(:).');
if numel(actual) == 2
    actual(3) = 1;
end
if ~isequal(actual, expected)
    error('objectrelativeprofiles:GridMismatch', 'Grid metadata dimensions must match the field.');
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMQUERYFIELD Scalar/component statistics at indices, masks or ID groups.
% FIELD is one XYZ numeric array, struct(Data,Grid), or named fields for a
% SampleOperation. Named fields must each be same-frame matching XYZ arrays.
% REQUESTED: Count, Sum, Mean, Median, Variance, Std, Min, Max, Quantiles,
% Histogram, or 'all'. Statistics use FINITE samples only. Always records
% selected/finite counts, NaN/+Inf/-Inf counts and empty/fallback flags.
% OPTIONS.FieldName='Field'; Support=struct() -> prepareSupport options;
% Grid=[]; Quantiles=[.25 .5 .75]; BinEdges=[]; NumBins=[] (MATLAB automatic);
% VarianceNormalization=0 (sample) or 1 (population); SampleOperation=[];
% CustomOperations=struct() of named @(finiteSamples) reducers.
% Raw sample storage is deliberately deferred. Metadata mismatches are
% recorded, never automatically remapped. Dimensions must match.
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% Use DatasetID, Frame, ObjectID and ComponentID when joining sampling rows.
% Review empty/fallback and nonfinite diagnostics before interpreting statistics.
