function options = farmMakeProbabilityOptions(varargin)
%FARMMAKEPROBABILITYOPTIONS Describe probability-category resolution settings.
% Inputs:
%   varargin   Scalar options struct or name/value pairs. EnsureDisjoint
%              and ReturnLabelVolume default to true; other flags to false.
% Outputs:
%   options    Editable settings accepted by farmClassifyProbabilities.
%
% See also farmClassifyProbabilities, farmMakeClasses

options = farmParseOptions(struct('EnsureDisjoint',true, ...
    'AssignUnclassified',false,'ReturnLabelVolume',true,'ReturnMasks',false, ...
    'ReturnCandidateMasks',false,'ReturnOverlapMask',false, ...
    'ReturnUnclassifiedMask',false,'ReturnChangedVoxelMask',false, ...
    'CountComponents',false,'Connectivity',[]),varargin{:});
names = fieldnames(options);
for optInd = 1:numel(names)
    if ~strcmp(names{optInd}, 'Connectivity')
        validateattributes(options.(names{optInd}), {'logical'}, {'scalar'});
    end
end
if ~options.EnsureDisjoint&&(options.ReturnLabelVolume||options.AssignUnclassified)
    error('segmentationtools:Config','Label volume/unclassified assignment requires EnsureDisjoint=true.');
end
if ~isempty(options.Connectivity)&&(~isscalar(options.Connectivity)||~ismember(options.Connectivity,[4 8 6 18 26]))
    error('segmentationtools:Config','Connectivity must be 4, 8, 6, 18 or 26.');
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Describes overlap resolution and retained classification results without
% loading or classifying probability fields. Label volumes and assignment of
% unclassified locations require disjoint categories. Connectivity=[] uses
% the consumer default when component counting is requested.
% These are not farmSmoothNChannelProbabilities morphology/precedence settings.
%
% EXAMPLES
% -------------------------------------------------------------------------
% opts = farmMakeProbabilityOptions('ReturnMasks', true);
% opts = farmMakeProbabilityOptions('ReturnOverlapMask', true, ...
%     'ReturnUnclassifiedMask', true);
