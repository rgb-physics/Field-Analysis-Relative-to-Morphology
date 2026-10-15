function result = farmClassifyProbabilities(probabilities, classes, options)
%FARMCLASSIFYPROBABILITIES Convert [Y X Z C] probabilities into class masks.
%   RESULT = CLASSIFYPROBABILITIES(PROBABILITIES, CLASSES, OPTIONS) uses
%   class definitions from segmentationtools.config.makeClasses. Comparisons are
%   strict. Inputs are not normalized internally.
%
%   Default behavior is disjoint but not exhaustive: overlapping candidate
%   classes are assigned to the class with the greatest aggregate score;
%   exact ties go to the class appearing first in CLASSES. Voxels passing
%   no threshold remain zero/unclassified. Set AssignUnclassified=true to
%   assign them by maximum aggregate score.
%
%   OPTIONS fields:
%     EnsureDisjoint          true
%     AssignUnclassified      false
%     ReturnLabelVolume       true
%     ReturnMasks             false
%     ReturnCandidateMasks    false
%     ReturnOverlapMask       false
%     ReturnUnclassifiedMask  false
%     ReturnChangedVoxelMask  false
%     CountComponents         false
%     Connectivity            26 for 3-D, 8 for 2-D
%
%   Full-size representations are constructed in RESULT only when their
%   corresponding return option is true. Candidate masks and scores are
%   still used internally to resolve classes.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', ...
        'options must be a scalar struct.');
end
if ~(isnumeric(probabilities) && isreal(probabilities) && ...
        ~issparse(probabilities) && ~isempty(probabilities) && ...
        ndims(probabilities) <= 4)
    error('segmentationtools:InvalidProbabilities', ...
        'probabilities must be a nonempty real [Y X Z C] numeric array.');
end
localValidateClasses(classes, size(probabilities, 4));

defaults = farmMakeProbabilityOptions();
optionNames = fieldnames(defaults);
for index = 1:numel(optionNames)
    name = optionNames{index};
    if ~isfield(options, name)
        options.(name) = defaults.(name);
    end
end
logicalNames = {'EnsureDisjoint','AssignUnclassified','ReturnLabelVolume', ...
    'ReturnMasks','ReturnCandidateMasks','ReturnOverlapMask', ...
    'ReturnUnclassifiedMask','ReturnChangedVoxelMask','CountComponents'};
for index = 1:numel(logicalNames)
    value = options.(logicalNames{index});
    if ~(islogical(value) && isscalar(value))
        error('segmentationtools:InvalidOption', ...
            'options.%s must be a logical scalar.', logicalNames{index});
    end
end
if ~options.EnsureDisjoint && options.ReturnLabelVolume
    error('segmentationtools:LabelsRequireDisjointClasses', ...
        ['A single label volume cannot preserve overlapping classes. ' ...
         'Set ReturnLabelVolume=false and ReturnMasks=true.']);
end
if options.AssignUnclassified && ~options.EnsureDisjoint
    error('segmentationtools:InvalidClassPolicy', ...
        'AssignUnclassified requires EnsureDisjoint=true.');
end

numClasses = numel(classes);
spatialSize = [size(probabilities,1), size(probabilities,2), ...
    size(probabilities,3)];
candidateMasks = false([spatialSize numClasses]);
scores = zeros([spatialSize numClasses]);
thresholdInfo = repmat(struct('Channels', [], 'ThresholdsUsed', [], ...
    'CombineMethod', '', 'StrictThreshold', true), 1, numClasses);
for classIndex = 1:numClasses
    thresholdOptions = struct('CombineMethod', ...
        classes(classIndex).CombineMethod, 'ReturnScore', true);
    [candidateMasks(:,:,:,classIndex), groupInfo] = ...
        farmThresholdProbabilityGroup( ...
        probabilities, classes(classIndex).Channels, ...
        classes(classIndex).Thresholds, thresholdOptions);
    scores(:,:,:,classIndex) = groupInfo.Score;
    groupInfo = rmfield(groupInfo, 'Score');
    thresholdInfo(classIndex) = groupInfo;
end

candidateCount = sum(candidateMasks, 4);
overlapMask = candidateCount > 1;
unclassifiedMask = candidateCount == 0;
changedMask = overlapMask;

result = struct();
result.Classes = classes;
result.ThresholdInfo = thresholdInfo;
result.IsDisjoint = options.EnsureDisjoint;
result.IsExhaustive = options.AssignUnclassified;

if options.EnsureDisjoint
    eligibleScores = scores;
    if ~options.AssignUnclassified
        eligibleScores(~candidateMasks) = -Inf;
    else
        changedMask = changedMask | unclassifiedMask;
    end
    [bestScores, bestClass] = max(eligibleScores, [], 4);
    assigned = isfinite(bestScores);
    classIndexVolume = zeros(spatialSize, 'uint32');
    classIndexVolume(assigned) = uint32(bestClass(assigned));

    if options.ReturnLabelVolume
        maxID = max([classes.ID]);
        labelType = localUnsignedType(maxID);
        labels = zeros(spatialSize, labelType);
        for classIndex = 1:numClasses
            labels(classIndexVolume == classIndex) = ...
                cast(classes(classIndex).ID, labelType);
        end
        result.LabelVolume = labels;
    end
    if options.ReturnMasks
        masks = false([spatialSize numClasses]);
        for classIndex = 1:numClasses
            masks(:,:,:,classIndex) = classIndexVolume == classIndex;
        end
        result.Masks = masks;
    end
else
    if options.ReturnMasks
        result.Masks = candidateMasks;
    end
end

if options.ReturnCandidateMasks
    result.CandidateMasks = candidateMasks;
end
if options.ReturnOverlapMask
    result.OverlapMask = overlapMask;
end
if options.ReturnUnclassifiedMask
    result.UnclassifiedMask = unclassifiedMask;
end
if options.ReturnChangedVoxelMask
    result.ChangedVoxelMask = changedMask;
end

result.VoxelCounts = zeros(1, numClasses);
if options.EnsureDisjoint
    for classIndex = 1:numClasses
        result.VoxelCounts(classIndex) = ...
            nnz(classIndexVolume == classIndex);
    end
else
    result.VoxelCounts = reshape(sum(candidateMasks, [1 2 3]), 1, []);
end
result.OverlapVoxelCount = nnz(overlapMask);
result.UnclassifiedVoxelCountBeforeResolution = nnz(unclassifiedMask);

if options.CountComponents
    connectivity = options.Connectivity;
    if isempty(connectivity)
        if spatialSize(3) == 1
            connectivity = 8;
        else
            connectivity = 26;
        end
    end
    result.Connectivity = connectivity;
    result.ComponentCounts = zeros(1, numClasses);
    for classIndex = 1:numClasses
        if options.EnsureDisjoint
            classMask = classIndexVolume == classIndex;
        else
            classMask = candidateMasks(:,:,:,classIndex);
        end
        if spatialSize(3) == 1
            components = bwconncomp(classMask(:,:,1), connectivity);
        else
            components = bwconncomp(classMask, connectivity);
        end
        result.ComponentCounts(classIndex) = components.NumObjects;
    end
end
end

function localValidateClasses(classes, numChannels)
required = {'Name','Channels','Thresholds','CombineMethod','ID'};
if ~(isstruct(classes) && ~isempty(classes))
    error('segmentationtools:InvalidClasses', ...
        'classes must be a nonempty struct array.');
end
for index = 1:numel(required)
    if ~isfield(classes, required{index})
        error('segmentationtools:InvalidClasses', ...
            'classes is missing the %s field.', required{index});
    end
end
allIDs = [classes.ID];
validateattributes(allIDs, {'numeric'}, ...
    {'real','finite','vector','integer','positive','<=',double(intmax('uint32'))}, ...
    mfilename, 'classes.ID');
if numel(unique(allIDs)) ~= numel(allIDs)
    error('segmentationtools:DuplicateClassIDs', ...
        'Every class ID must be unique.');
end
for index = 1:numel(classes)
    validateattributes(classes(index).Channels, {'numeric'}, ...
        {'real','finite','vector','integer','positive','nonempty'}, ...
        mfilename, sprintf('classes(%d).Channels', index));
    if any(classes(index).Channels > numChannels)
        error('segmentationtools:ChannelOutOfRange', ...
            'Class %s requests a channel beyond channel %d.', ...
            classes(index).Name, numChannels);
    end
end
end

function typeName = localUnsignedType(maxValue)
if maxValue <= intmax('uint8')
    typeName = 'uint8';
elseif maxValue <= intmax('uint16')
    typeName = 'uint16';
else
    typeName = 'uint32';
end
end
