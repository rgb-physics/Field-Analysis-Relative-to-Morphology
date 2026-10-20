function experiment = farmMakeExperiment(varargin)
%FARMMAKEEXPERIMENT Collect named sources, identity and acquisition timing.
% Inputs:
%   varargin     Scalar options struct or name/value pairs. DatasetID,
%                Sources and Frames are required. TimeStep defaults to 1;
%                TimeUnit defaults to 'frame', independently of TimeStep.
% Outputs:
%   experiment   Experiment construct with validated named Data sources.
%
% See also farmMakeSource, farmLoadSource

experiment = farmParseOptions(struct('DatasetID','', ...
    'Sources',struct(),'Frames',[],'TimeStep',[],'TimeUnit','', ...
    'TimeStepSeconds',[]),varargin{:});
id = string(experiment.DatasetID);
if ~isscalar(id) || ismissing(id) || strlength(id) == 0
    error('memoworkflow:ExperimentConfig', ...
        'Specify a nonempty DatasetID. See glossary entry Experiment.');
end

experiment.DatasetID = char(id);
validateattributes(experiment.Frames,{'numeric'},{'vector','nonempty','integer','nonnegative','finite'});
experiment.Frames = unique(double(experiment.Frames(:).'),'stable');
unit = string(experiment.TimeUnit);
if ~isscalar(unit) || ismissing(unit)
    error('memoworkflow:ExperimentConfig','TimeUnit must be scalar text.');
end
experiment.TimeUnit = char(unit);
if ~isempty(experiment.TimeStepSeconds)
    validateattributes(experiment.TimeStepSeconds,{'numeric'},{'scalar','positive','finite','real'});
    if (~isempty(experiment.TimeStep)&&~isequal(double(experiment.TimeStep),double(experiment.TimeStepSeconds))) ...
            ||(~isempty(experiment.TimeUnit)&&~strcmp(experiment.TimeUnit,'s'))
        error('memoworkflow:ExperimentConfig','TimeStepSeconds conflicts with TimeStep/TimeUnit.');
    end
    experiment.TimeStep = experiment.TimeStepSeconds;
    experiment.TimeUnit = 's';
end
experiment = rmfield(experiment,'TimeStepSeconds');
% Empty sentinels above distinguish omitted values from explicit legacy-alias
% conflicts; resolved output always contains the independent defaults.
if isempty(experiment.TimeStep)
    experiment.TimeStep = 1;
end

if isempty(strtrim(experiment.TimeUnit))
    experiment.TimeUnit = 'frame';
end

validateattributes(experiment.TimeStep,{'numeric'},{'scalar','positive','finite','real'});
if ~isstruct(experiment.Sources)||~isscalar(experiment.Sources)||isempty(fieldnames(experiment.Sources))
    error('memoworkflow:ExperimentConfig', ...
        'Provide named Sources built with farmMakeSource. See glossary entry Experiment.');
end
names = fieldnames(experiment.Sources);
for srcInd = 1:numel(names)
    experiment.Sources.(names{srcInd}) = farmMakeSource(experiment.Sources.(names{srcInd}));
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Does not inspect files or load images. Repeated Frames are removed while
% retaining their first occurrence and the supplied order.
% TimeStepSeconds remains an input alias for TimeStep with TimeUnit='s'.
% Conflicting old/new settings are rejected; output uses TimeStep/TimeUnit.
%
% EXAMPLE
% -------------------------------------------------------------------------
% src = farmMakeSource('Format', 'custom', 'Loader', @(frame) ones(8, 8));
% exp = farmMakeExperiment('DatasetID', 'example', 'Frames', [10 12], ...
%     'Sources', struct('Intensity', src), 'TimeStep', 0.5, 'TimeUnit', 'min');
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% TimeStep describes original acquisition-frame increments: frames 10 and 12
% in this example are separated by (12 - 10) * 0.5 = 1 minute.
% No unit conversion or spatial registration is inferred.
