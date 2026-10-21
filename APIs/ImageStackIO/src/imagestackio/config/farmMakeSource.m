function source = farmMakeSource(varargin)
%FARMMAKESOURCE Describe one named TIFF/HDF5/custom source without loading data.
% Inputs:
%   varargin   Scalar options struct or name/value pairs. Format selects
%              'tiff' (default), 'hdf5' or 'custom'. File sources require
%              Folder and NamePattern; HDF5 also requires DatasetPath.
% Outputs:
%   source     Data source construct accepted by farmMakeExperiment.
%
% For the definition and documented inputs, enter farmGlossary("Source").
% Source and Data source return the same glossary entry.
%
% See also farmMakeExperiment, farmLoadSource, farmReadTiff, farmReadH5

source = farmParseOptions(struct('Format','tiff','Folder','', ...
    'NamePattern','','Pattern','','DatasetPath','','SourceAxes','','Spacing',[1 1 1], ...
    'SpacingUnit','pixel','Channels',[],'TimeIndex',1,'Loader',[]),varargin{:});
source.Format = validatestring(source.Format,{'tiff','hdf5','custom'});
% Convert scalar text settings to the stored character-vector form.
for name = {'Folder', 'NamePattern', 'Pattern', 'DatasetPath', 'SourceAxes', 'SpacingUnit'}
    value = string(source.(name{1}));

    if ~isscalar(value) || ismissing(value)
        error('imagestackio:SourceConfig', ...
            '%s must be scalar text. See glossary entry Data source.', name{1});
    end

    source.(name{1}) = char(value);
end

if ~isempty(source.Pattern)
    if ~isempty(source.NamePattern)&&~strcmp(source.NamePattern,source.Pattern)
        error('imagestackio:SourceConfig','NamePattern and legacy Pattern conflict.');
    end
    source.NamePattern = source.Pattern;
end
source = rmfield(source,'Pattern');
validateattributes(source.Spacing,{'numeric'},{'real','finite','positive','vector','numel',3});
source.Spacing = double(source.Spacing(:).');
if isempty(source.SpacingUnit)
    error('imagestackio:SourceConfig', 'Specify SpacingUnit. See glossary entry Data source.');
end

axes = upper(source.SourceAxes);
if ~isempty(axes) && (any(~ismember(axes,'YXZCT'))||numel(unique(axes))~=numel(axes)||~all(ismember('YX',axes)))
    error('imagestackio:SourceConfig','SourceAxes must contain unique Y/X and optional Z/C/T.');
end
source.SourceAxes = axes;
validateattributes(source.TimeIndex,{'numeric'},{'scalar','integer','finite','positive'});
if ~isempty(source.Channels)
    validateattributes(source.Channels, {'numeric'}, {'vector', 'integer', 'finite', 'positive'});
end

% Validate only the settings needed by the selected loading method.
if strcmp(source.Format, 'custom')
    if ~isa(source.Loader, 'function_handle')
        error('imagestackio:SourceConfig', ...
            'A custom Data source requires Loader=@(frame).');
    end
else
    if ~isempty(source.Loader)
        error('imagestackio:SourceConfig', 'Loader is only for custom Data sources.');
    end

    if isempty(source.Folder) || isempty(source.NamePattern)
        error('imagestackio:SourceConfig', ...
            'Specify Folder and NamePattern. See glossary entry Data source.');
    end

    if strcmp(source.Format, 'hdf5') && isempty(source.DatasetPath)
        error('imagestackio:SourceConfig', 'An HDF5 Data source requires DatasetPath.');
    end
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% No files are read. NamePattern is passed to sprintf with an acquisition
% frame number. Pattern remains an input alias; only NamePattern is returned.
% Channels=[] keeps all stored channels. TimeIndex=1 selects one stored time.
% SourceAxes='' leaves axis interpretation to the reader's metadata/defaults.
% A custom Loader returns one YXZ array or an image struct with Axes='YXZCT'.
%
% EXAMPLES
% -------------------------------------------------------------------------
% src = farmMakeSource('Folder', 'C:/images', 'NamePattern', 't%03i.tif');
% src = farmMakeSource('Format', 'hdf5', 'Folder', 'C:/probabilities', ...
%     'NamePattern', 't%03i.h5', 'DatasetPath', '/exported_data', ...
%     'SourceAxes', 'CXYZ');
% src = farmMakeSource('Format', 'custom', 'Loader', @(frame) ones(8, 8));
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Spacing defaults to [1 1 1] in YXZ order; SpacingUnit defaults to 'pixel'.
% Calibration describes this source. It does not register it to other sources.
% Stored channel/time positions are separate from acquisition Frame identity.
