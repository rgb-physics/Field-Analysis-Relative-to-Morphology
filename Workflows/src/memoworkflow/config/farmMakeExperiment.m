function experiment = farmMakeExperiment(varargin)
%FARMMAKEEXPERIMENT Collect named sources, identity and acquisition timing.
% DatasetID required; Sources required scalar struct of makeSource outputs;
% Frames required nonnegative integer vector (duplicates removed stably);
% TimeStep=1 and TimeUnit='frame' are independent defaults.
% Either may be supplied without the other; no unit conversion is inferred.
% TimeStepSeconds is a legacy alias for TimeStep with TimeUnit='s'.
% Does not inspect/load files; output contains only canonical time fields.
experiment = farmParseOptions(struct('DatasetID','', ...
    'Sources',struct(),'Frames',[],'TimeStep',[],'TimeUnit','', ...
    'TimeStepSeconds',[]),varargin{:});
id = string(experiment.DatasetID);
if ~isscalar(id)||ismissing(id)||strlength(id)==0, error('memoworkflow:ExperimentConfig','Specify a nonempty DatasetID.'); end
experiment.DatasetID = char(id);
validateattributes(experiment.Frames,{'numeric'},{'vector','nonempty','integer','nonnegative','finite'});
experiment.Frames = unique(double(experiment.Frames(:).'),'stable');
unit = string(experiment.TimeUnit);
if ~isscalar(unit)||ismissing(unit)
    error('memoworkflow:ExperimentConfig','TimeUnit must be scalar text.');
end
experiment.TimeUnit = char(unit);
if ~isempty(experiment.TimeStepSeconds)
    validateattributes(experiment.TimeStepSeconds,{'numeric'},{'scalar','positive','finite','real'});
    if (~isempty(experiment.TimeStep)&&~isequal(double(experiment.TimeStep),double(experiment.TimeStepSeconds))) ...
            ||(~isempty(experiment.TimeUnit)&&~strcmp(experiment.TimeUnit,'s'))
        error('memoworkflow:ExperimentConfig','TimeStepSeconds conflicts with TimeStep/TimeUnit.');
    end
    experiment.TimeStep = experiment.TimeStepSeconds; experiment.TimeUnit = 's';
end
experiment = rmfield(experiment,'TimeStepSeconds');
% Empty sentinels above distinguish omitted values from explicit legacy-alias
% conflicts; resolved output always contains the independent defaults.
if isempty(experiment.TimeStep), experiment.TimeStep = 1; end
if isempty(strtrim(experiment.TimeUnit)), experiment.TimeUnit = 'frame'; end
validateattributes(experiment.TimeStep,{'numeric'},{'scalar','positive','finite','real'});
if ~isstruct(experiment.Sources)||~isscalar(experiment.Sources)||isempty(fieldnames(experiment.Sources))
    error('memoworkflow:ExperimentConfig','Provide named Sources built with imagestackio.config.makeSource.');
end
names = fieldnames(experiment.Sources);
for k = 1:numel(names)
    experiment.Sources.(names{k}) = farmMakeSource(experiment.Sources.(names{k}));
end
end
