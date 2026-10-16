function results = farmQueryVectorField(fields, inputSupport, requested, options)
%FARMQUERYVECTORFIELD Same-frame vectors with independent component validity.
% Inputs:
%   fields          Struct of named field arrays or Data/Grid structs.
%   inputSupport    Sampling indices, mask, labels, index groups or prepared geometry/support.
%   requested       Names of the properties or statistics to calculate.
%   options         Operation settings struct.
% Outputs:
%   results         Requested component/vector statistics with validity and identity columns.

if nargin < 3 || isempty(requested)
    requested = {'MeanVector', 'MeanMagnitude'};
end
if nargin < 4
    options = struct();
end
options = farmOGOptions(options, struct('ComponentNames', [], ...
                                       'FieldName', 'Vector', 'Support', struct(), 'Grid', [], 'VarianceNormalization', 0));
names = cellstr(string(options.ComponentNames));
names = names(:).';
if ~ismember(numel(names), [2 3]) || numel(unique(names)) ~= numel(names)
    error('objectrelativeprofiles:ComponentNames', 'Provide two or three distinct component names in coordinate order.');
end
if ~isstruct(fields) || ~isscalar(fields) || ~all(isfield(fields, names))
    error('objectrelativeprofiles:VectorFields', 'Supply named scalar fields matching ComponentNames.');
end
prefix = char(string(options.FieldName));
if ~isvarname(prefix)
    error('objectrelativeprofiles:InvalidFieldName', 'Use a valid MATLAB identifier.');
end
validateattributes(options.VarianceNormalization, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 1});
allowed = {'ComponentMean', 'ComponentVariance', 'ComponentStd', 'ComponentMin', 'ComponentMax', ...
           'MeanVector', 'MagnitudeOfMean', 'MeanMagnitude', 'MagnitudeStd', 'MinMagnitude', ...
           'MaxMagnitude', 'RMSMagnitude', 'Covariance'};
requested = cellstr(string(requested));
requested = requested(:).';
if any(strcmpi(requested, 'all'))
    requested = allowed;
end
for i = 1:numel(requested)
    requested{i} = validatestring(requested{i}, allowed);
end
requested = unique(requested, 'stable');
data = cell(size(names));
for i = 1:numel(names)
    value = fields.(names{i});
    if isstruct(value) && isfield(value, 'Data')
        value = value.Data;
    end
    validateattributes(value, {'numeric', 'logical'}, {'real', 'nonempty', 'nonsparse'});
    if ndims(value) > 3
        error('objectrelativeprofiles:InvalidDimensions', 'Select one XYZ field per vector component.');
    end
    if i > 1 && ~isequal(size(value), size(data{1}))
        error('objectrelativeprofiles:GridMismatch', 'Vector components must have matching spatial dimensions.');
    end
    data{i} = value;
end
sz = [size(data{1}, 1) size(data{1}, 2) size(data{1}, 3)];
support = farmPrepareSupport(inputSupport, sz, options.Support);
count = numel(support.Records);
dims = numel(names);
means = nan(count, dims);
results = table();
nativeStats = {'Mean', 'Variance', 'Std', 'Min', 'Max'};
wantMeans = any(ismember(requested, {'MeanVector', 'MagnitudeOfMean', 'ComponentMean'}));
for component = 1:dims
    selected = {'Count'};
    for stat = nativeStats
        if ismember(['Component' stat{1}], requested)
            selected{end + 1} = stat{1};
        end %#ok<AGROW>
    end
    if wantMeans
        selected = unique([selected {'Mean'}], 'stable');
    end
    componentPrefix = [prefix '_' names{component}];
    scalarOptions = struct('FieldName', componentPrefix, 'VarianceNormalization', options.VarianceNormalization);
    if ~isempty(options.Grid)
        scalarOptions.Grid = options.Grid;
    end
    t = farmQueryField(fields.(names{component}), support, selected, scalarOptions);
    if wantMeans
        means(:, component) = t.([componentPrefix '_Mean']);
    end
    if wantMeans && ~ismember('ComponentMean', requested)
        t = removevars(t, [componentPrefix '_Mean']);
    end
    if component == 1
        results = t;
    else
        results = farmAttachResults(results, t);
    end
end
if ismember('MeanVector', requested)
    results.([prefix '_MeanVector']) = means;
end
if ismember('MagnitudeOfMean', requested)
    magnitude = zeros(count, 1);
    for i = 1:dims
        magnitude = hypot(magnitude, means(:, i));
    end
    results.([prefix '_MagnitudeOfMean']) = magnitude;
end
completeCounts = zeros(count, 1);
covariance = cell(count, 1);
pairCounts = cell(count, 1);
magnitudeStats = {'MeanMagnitude', 'MagnitudeStd', 'MinMagnitude', 'MaxMagnitude', 'RMSMagnitude'};
for stat = magnitudeStats
    if ismember(stat{1}, requested)
        results.([prefix '_' stat{1}]) = nan(count, 1);
    end
end
for row = 1:count
    indices = support.Records(row).Indices;
    values = zeros(numel(indices), dims);
    for i = 1:dims
        values(:, i) = double(data{i}(indices));
    end
    valid = isfinite(values);
    complete = all(valid, 2);
    completeCounts(row) = nnz(complete);
    magnitudes = zeros(nnz(complete), 1);
    for i = 1:dims
        magnitudes = hypot(magnitudes, values(complete, i));
    end
    if ~isempty(magnitudes)
        if ismember('MeanMagnitude', requested)
            results.([prefix '_MeanMagnitude'])(row) = mean(magnitudes);
        end
        if ismember('MagnitudeStd', requested)
            results.([prefix '_MagnitudeStd'])(row) = std(magnitudes, options.VarianceNormalization);
        end
        if ismember('MinMagnitude', requested)
            results.([prefix '_MinMagnitude'])(row) = min(magnitudes);
        end
        if ismember('MaxMagnitude', requested)
            results.([prefix '_MaxMagnitude'])(row) = max(magnitudes);
        end
        if ismember('RMSMagnitude', requested)
            scale = max(magnitudes);
            if scale == 0
                rms = 0;
            else
                rms = scale * sqrt(mean((magnitudes / scale).^2));
            end
            results.([prefix '_RMSMagnitude'])(row) = rms;
        end
    end
    if ismember('Covariance', requested)
        matrix = nan(dims);
        counts = zeros(dims);
        for i = 1:dims
            for j = i:dims
                paired = valid(:, i) & valid(:, j);
                n = nnz(paired);
                counts(i, j) = n;
                counts(j, i) = n;
                if n == 0
                    continue
                end
                a = values(paired, i);
                b = values(paired, j);
                denominator = max(1, n - 1 + options.VarianceNormalization);
                c = sum((a - mean(a)) .* (b - mean(b))) / denominator;
                matrix(i, j) = c;
                matrix(j, i) = c;
            end
        end
        covariance{row} = matrix;
        pairCounts{row} = counts;
    end
end
results.([prefix '_CompleteVectorCount']) = completeCounts;
results.([prefix '_IncompleteVectorCount']) = results.([prefix '_' names{1} '_SelectedCount']) - completeCounts;
if ismember('Covariance', requested)
    results.([prefix '_Covariance']) = covariance;
    results.([prefix '_CovariancePairCounts']) = pairCounts;
end
results.Properties.UserData = struct('ComponentMetadata', results.Properties.UserData, ...
                                     'ComponentNames', {names}, 'Options', options, 'MeanVectorValidity', 'independent components', ...
                                     'MagnitudeValidity', 'complete finite vectors at each voxel', 'CovarianceValidity', 'pairwise finite');
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMQUERYVECTORFIELD Same-frame vectors with independent component validity.
% FIELDS: named XYZ scalar components, each array or struct(Data,Grid).
% OPTIONS.ComponentNames is REQUIRED, in explicit coordinate order (2 or 3).
% FieldName='Vector'; Support=struct(); Grid=[]; VarianceNormalization=0.
% Requested: ComponentMean/Variance/Std/Min/Max, MeanVector, MagnitudeOfMean,
% MeanMagnitude, MagnitudeStd, MinMagnitude, MaxMagnitude, RMSMagnitude,
% Covariance, or 'all'. No director/nematic or circular statistics implied.
%
% Component statistics use each component's finite values independently.
% MeanVector contains those independent means, with per-component counts.
% MagnitudeOfMean is the norm of that vector, NOT mean magnitude.
% Magnitudes require every component finite AT THAT VOXEL. Covariance uses
% pairwise-finite samples with a separate count per pair, not whole-selection
% exclusion. Pairwise covariance may not be positive semidefinite when pairs
% have different valid samples. Pair means are recomputed for each pair.
% RMSMagnitude uses complete finite vectors. Zero vectors are valid.
% NaN/+Inf/-Inf counts are preserved separately for EACH component.
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% ComponentNames gives component order explicitly. Ordinary vector statistics
% do not replace axial/nematic statistics. No spatial registration is inferred.
