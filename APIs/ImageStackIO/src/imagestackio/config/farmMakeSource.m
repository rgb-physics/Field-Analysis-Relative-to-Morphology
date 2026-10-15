function source = farmMakeSource(varargin)
%FARMMAKESOURCE Describe one named TIFF/HDF5/custom source without loading data.
% Struct or name/value options: Format='tiff'|'hdf5'|'custom'; Folder='';
% NamePattern='' receiving frame in sprintf; DatasetPath='' (required for HDF5);
% SourceAxes='' (TIFF reader metadata/default applies); Spacing=[1 1 1] YXZ;
% SpacingUnit='pixel'; Channels=[]; TimeIndex=1; Loader=[].
% Custom Loader=@(frame) returns an ImageStackIO image or one YXZ array.
% Calibration here describes this source, not another experiment field.
% Pattern is accepted as a legacy alias; output contains only NamePattern.
source = farmParseOptions(struct('Format','tiff','Folder','', ...
    'NamePattern','','Pattern','','DatasetPath','','SourceAxes','','Spacing',[1 1 1], ...
    'SpacingUnit','pixel','Channels',[],'TimeIndex',1,'Loader',[]),varargin{:});
source.Format = validatestring(source.Format,{'tiff','hdf5','custom'});
for name = {'Folder','NamePattern','Pattern','DatasetPath','SourceAxes','SpacingUnit'}
    v = string(source.(name{1}));
    if ~isscalar(v)||ismissing(v), error('imagestackio:SourceConfig','%s must be scalar text.',name{1}); end
    source.(name{1}) = char(v);
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
if isempty(source.SpacingUnit), error('imagestackio:SourceConfig','Specify SpacingUnit.'); end
axes = upper(source.SourceAxes);
if ~isempty(axes) && (any(~ismember(axes,'YXZCT'))||numel(unique(axes))~=numel(axes)||~all(ismember('YX',axes)))
    error('imagestackio:SourceConfig','SourceAxes must contain unique Y/X and optional Z/C/T.');
end
source.SourceAxes = axes;
validateattributes(source.TimeIndex,{'numeric'},{'scalar','integer','finite','positive'});
if ~isempty(source.Channels), validateattributes(source.Channels,{'numeric'},{'vector','integer','finite','positive'}); end
if strcmp(source.Format,'custom')
    if ~isa(source.Loader,'function_handle'), error('imagestackio:SourceConfig','Custom source requires Loader=@(frame).'); end
else
    if ~isempty(source.Loader), error('imagestackio:SourceConfig','Loader is only for custom sources.'); end
    if isempty(source.Folder)||isempty(source.NamePattern), error('imagestackio:SourceConfig','Specify Folder and NamePattern.'); end
    if strcmp(source.Format,'hdf5')&&isempty(source.DatasetPath), error('imagestackio:SourceConfig','HDF5 requires DatasetPath.'); end
end
end
