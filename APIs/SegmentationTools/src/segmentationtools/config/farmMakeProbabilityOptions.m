function options = farmMakeProbabilityOptions(varargin)
%FARMMAKEPROBABILITYOPTIONS Options for binarization.classifyProbabilities.
% This config concerns class resolution/retained results, not morphological
% smoothNChannelProbabilities options or input channel precedence.
options = farmParseOptions(struct('EnsureDisjoint',true, ...
    'AssignUnclassified',false,'ReturnLabelVolume',true,'ReturnMasks',false, ...
    'ReturnCandidateMasks',false,'ReturnOverlapMask',false, ...
    'ReturnUnclassifiedMask',false,'ReturnChangedVoxelMask',false, ...
    'CountComponents',false,'Connectivity',[]),varargin{:});
names = fieldnames(options);
for k = 1:numel(names)
    if ~strcmp(names{k},'Connectivity'), validateattributes(options.(names{k}),{'logical'},{'scalar'}); end
end
if ~options.EnsureDisjoint&&(options.ReturnLabelVolume||options.AssignUnclassified)
    error('segmentationtools:Config','Label volume/unclassified assignment requires EnsureDisjoint=true.');
end
if ~isempty(options.Connectivity)&&(~isscalar(options.Connectivity)||~ismember(options.Connectivity,[4 8 6 18 26]))
    error('segmentationtools:Config','Connectivity must be 4, 8, 6, 18 or 26.');
end
end
