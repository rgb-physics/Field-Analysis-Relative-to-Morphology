function options = farmMakeIntensityOptions(varargin)
%FARMMAKEINTENSITYOPTIONS Describe intensity segmentation settings.
% Inputs:
%   varargin        Optional scalar struct or name/value pairs with the fields:
%                   Method = character vector or string scalar;
%                   Threshold = numeric scalar or [];
%                   Foreground = character vector or string scalar;
%                   IntensityRange = numeric two-element vector or [];
%                   EstimationMask = logical array or [];
%                   FillHoles = logical scalar;
%                   MinObjectSize = nonnegative integer scalar;
%                   KeepLargest = nonnegative integer scalar or [];
%                   Connectivity = numeric scalar or [];
%                   ReturnLabels = logical scalar;
% Outputs:
%   options    Editable settings accepted by farmSegmentIntensity.
%
% See also farmSegmentIntensity

options = farmParseOptions(struct('Method','otsu','Threshold',[], ...
    'Foreground','bright','IntensityRange',[],'EstimationMask',[], ...
    'FillHoles',false,'MinObjectSize',0,'KeepLargest',[], ...
    'Connectivity',[],'ReturnLabels',false),varargin{:});
options.Method = validatestring(options.Method,{'fixed','otsu'});
options.Foreground = validatestring(options.Foreground,{'bright','dark'});
if strcmp(options.Method,'fixed')||~isempty(options.Threshold)
    validateattributes(options.Threshold,{'numeric'},{'scalar','real','finite'});
end
for name = {'FillHoles', 'ReturnLabels'}
    validateattributes(options.(name{1}), {'logical'}, {'scalar'});
end

validateattributes(options.MinObjectSize,{'numeric'},{'scalar','integer','nonnegative','finite'});
if ~isempty(options.KeepLargest)
    validateattributes(options.KeepLargest, {'numeric'}, {'scalar', 'integer', 'nonnegative', 'finite'});
end

if ~isempty(options.IntensityRange)
    validateattributes(options.IntensityRange,{'numeric'},{'vector','numel',2,'real','finite','increasing'});
end
if ~isempty(options.Connectivity)&&(~isscalar(options.Connectivity)||~ismember(options.Connectivity,[4 8 6 18 26]))
    error('segmentationtools:Config','Connectivity must be 4, 8, 6, 18 or 26.');
end
if ~isempty(options.EstimationMask) && ~islogical(options.EstimationMask)
    error('segmentationtools:Config', 'EstimationMask must be logical. See glossary entry Foreground mask.');
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Does not load or segment images. Cleanup settings are passed to the consumer;
% FillHoles=false, MinObjectSize=0 and KeepLargest=[] leave cleanup disabled.
% Fixed Threshold uses original intensity units; no per-frame normalization
% is introduced. Data-dependent checks occur in farmSegmentIntensity.
%
% EXAMPLES
% -------------------------------------------------------------------------
% opts = farmMakeIntensityOptions('Method', 'fixed', 'Threshold', 20);
% opts = farmMakeIntensityOptions('Method', 'otsu', 'Foreground', 'dark');
