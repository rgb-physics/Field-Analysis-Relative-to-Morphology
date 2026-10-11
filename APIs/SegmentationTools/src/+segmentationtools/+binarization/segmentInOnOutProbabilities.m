function result = segmentInOnOutProbabilities(probabilities, channels, thresholds, options)
%SEGMENTINONOUTPROBABILITIES Segment inside, wall, and outside classes.
%   RESULT = SEGMENTINONOUTPROBABILITIES(P, CHANNELS, THRESHOLDS, OPTIONS)
%   uses the semantic order [inside, wall, outside], corresponding to the
%   historical shorthand [in, on, out]. P is [Y X Z C]. CHANNELS may be a
%   three-element numeric vector or a three-cell array of grouped channels.
%
%   OPTIONS.CombineMethods defaults to "sum" for each class.
%   OPTIONS.ClassifyOptions is passed to classifyProbabilities. The default
%   result is disjoint, is not necessarily exhaustive, and contains one
%   label volume with IDs [1 2 3] for [inside wall outside].

if nargin < 4 || isempty(options)
    options = struct();
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', ...
        'options must be a scalar struct.');
end
classOptions = struct('Names', ["inside" "wall" "outside"], ...
    'IDs', [1 2 3]);
if isfield(options, 'CombineMethods')
    classOptions.CombineMethods = options.CombineMethods;
end
classes = segmentationtools.binarization.makeClassConfig( ...
    channels, thresholds, classOptions);
if isfield(options, 'ClassifyOptions')
    classifyOptions = options.ClassifyOptions;
else
    classifyOptions = struct();
end
result = segmentationtools.binarization.classifyProbabilities( ...
    probabilities, classes, classifyOptions);
result.SemanticOrder = {'inside','wall','outside'};
result.HistoricalAliases = {'in','on','out'};
end
