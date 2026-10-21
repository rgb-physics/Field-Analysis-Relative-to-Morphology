function image = farmLoadSource(experiment, name, frame)
%FARMLOADSOURCE Load one named source at one acquisition frame.
% Inputs:
%   experiment   Experiment construct containing Sources, Frames, DatasetID.
%   name         Name of a Data source in experiment.Sources.
%   frame        Acquisition frame number listed in experiment.Frames.
% Outputs:
%   image        Image data with YXZCT axes, calibration, source and identity.
%
% Spacing is supplied in YXZ order and is stored with SpacingUnit.
% Channels and TimeIndex select stored array positions; frame identifies the
% acquisition. Loading does not resample or register data with other sources.
% Enter farmGlossary("Source") for the definition and documented source fields.
%
% See also farmMakeSource, farmMakeExperiment, farmReadTiff, farmReadH5

% Source Selection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Select a named source and acquisition frame from the Experiment.
name = char(string(name));
validateattributes(frame, {'numeric'}, {'scalar', 'integer', 'finite', 'nonnegative'});

if ~isfield(experiment.Sources, name)
    error('memoworkflow:MissingSource', ...
        'Unknown source: %s. Select a name in the Experiment Sources.', name);
end

if ~ismember(frame, experiment.Frames)
    error('memoworkflow:Frame', 'Frame is not listed in the Experiment Frames.');
end

source = farmMakeSource(experiment.Sources.(name));
options = struct('Spacing', source.Spacing, 'SpacingUnit', source.SpacingUnit);

if ~isempty(source.SourceAxes)
    options.SourceAxes = source.SourceAxes;
end

% Data Loading %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load only this acquisition frame. Stored channel/time selection follows.
switch source.Format
    case 'tiff'
        image = farmReadTiff(fullfile(source.Folder, sprintf(source.NamePattern, frame)), options);
    case 'hdf5'
        image = farmReadH5(fullfile(source.Folder, sprintf(source.NamePattern, frame)), source.DatasetPath, options);
    case 'custom'
        image = source.Loader(frame);

        if isnumeric(image) || islogical(image)
            if ndims(image) > 3
                error('memoworkflow:CustomSource', 'Custom arrays must be a single YXZ field.');
            end

            image = struct('Data', image, 'Axes', 'YXZCT', ...
                'Spacing', source.Spacing, 'SpacingUnit', source.SpacingUnit);
        elseif ~isstruct(image) || ~isscalar(image) || ~isfield(image, 'Data') ...
                || ~isfield(image, 'Axes') || ~strcmp(image.Axes, 'YXZCT')
            error('memoworkflow:CustomSource', ...
                'Return a YXZ array or image struct with Data and Axes=YXZCT. See glossary entry Data source.');
        end

        if ~isfield(image, 'Spacing')
            image.Spacing = source.Spacing;
        end

        if ~isfield(image, 'SpacingUnit')
            image.SpacingUnit = source.SpacingUnit;
        end
end

% Spatial Metadata %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Retain the supplied spacing and units without estimating calibration.
validateattributes(image.Spacing, {'numeric'}, {'vector', 'numel', 3, 'real', 'positive', 'finite'});
image.Spacing = double(image.Spacing(:).');
unit = string(image.SpacingUnit);

if ~isscalar(unit) || ismissing(unit) || strlength(unit) == 0
    error('memoworkflow:Calibration', 'SpacingUnit must be nonempty scalar text. See glossary entry Data source.');
end

image.SpacingUnit = char(unit);

% Stored Channel and Time Selection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Select array positions and record which source/frame produced the image.
if source.TimeIndex > size(image.Data, 5)
    error('memoworkflow:TimeIndex', 'TimeIndex exceeds stored time dimension.');
end

channels = source.Channels;

if isempty(channels)
    channels = 1:size(image.Data, 4);
end

if any(channels > size(image.Data, 4))
    error('memoworkflow:Channels', 'Channels exceed stored channel dimension.');
end

image.Data = image.Data(:, :, :, channels, source.TimeIndex);
image.DatasetID = experiment.DatasetID;
image.Frame = frame;
image.SourceName = name;
image.SelectedChannels = channels;
image.SelectedTimeIndex = source.TimeIndex;
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Custom arrays use the source calibration. Custom image structs can supply
% their own current-grid Spacing and SpacingUnit. Source selection does not
% resample data or establish correspondence with other fields.
%
% EXAMPLE
% -------------------------------------------------------------------------
% src = farmMakeSource('Format', 'custom', 'Loader', @(frame) ones(8, 8));
% exp = farmMakeExperiment('DatasetID', 'example', 'Frames', 3, ...
%     'Sources', struct('Intensity', src));
% image = farmLoadSource(exp, 'Intensity', 3);
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% DatasetID, Frame and SourceName identify this loaded source. Channels and
% TimeIndex select stored positions, not the acquisition Frame number.
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Image arrays use YXZCT; Spacing uses YXZ and carries SpacingUnit.
