function options = farmMakeIntensityOptions(varargin)
%FARMMAKEINTENSITYOPTIONS Options for binarization.segmentIntensity.
% Fixed Threshold uses original intensity units; no per-frame normalization.
options = farmParseOptions(struct('Method','otsu','Threshold',[], ...
    'Foreground','bright','IntensityRange',[],'EstimationMask',[], ...
    'FillHoles',false,'MinObjectSize',0,'KeepLargest',[], ...
    'Connectivity',[],'ReturnLabels',false),varargin{:});
options.Method = validatestring(options.Method,{'fixed','otsu'});
options.Foreground = validatestring(options.Foreground,{'bright','dark'});
if strcmp(options.Method,'fixed')||~isempty(options.Threshold)
    validateattributes(options.Threshold,{'numeric'},{'scalar','real','finite'});
end
for name = {'FillHoles','ReturnLabels'}, validateattributes(options.(name{1}),{'logical'},{'scalar'}); end
validateattributes(options.MinObjectSize,{'numeric'},{'scalar','integer','nonnegative','finite'});
if ~isempty(options.KeepLargest), validateattributes(options.KeepLargest,{'numeric'},{'scalar','integer','nonnegative','finite'}); end
if ~isempty(options.IntensityRange)
    validateattributes(options.IntensityRange,{'numeric'},{'vector','numel',2,'real','finite','increasing'});
end
if ~isempty(options.Connectivity)&&(~isscalar(options.Connectivity)||~ismember(options.Connectivity,[4 8 6 18 26]))
    error('segmentationtools:Config','Connectivity must be 4, 8, 6, 18 or 26.');
end
if ~isempty(options.EstimationMask)&&~islogical(options.EstimationMask), error('segmentationtools:Config','EstimationMask must be logical.'); end
end
