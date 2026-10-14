function options=makeObjectOptions(varargin)
%MAKEOBJECTOPTIONS Preparation options accepted by prepareObjects/measureObjects.
% Defaults match prepareObjects; Spacing YXZ describes CURRENT indices.
% For generateGeometry/measureFilaments/trackOverlaps put this under Identity.
% At execution replace DatasetID, Frame and grid metadata with actual values.
options=sharedutilities.config.parseOptions(struct('InputType','auto', ...
    'ImageSize',[],'ObjectIDs',[],'Connectivity',[],'DatasetID','default', ...
    'Frame',1,'Spacing',[1 1 1],'SpacingUnit','pixel','SourceGrid',[], ...
    'Transform',[],'Channel',1,'TimeIndex',1),varargin{:});
options.InputType=validatestring(options.InputType,{'auto','mask','labels','indices','components'});
validateattributes(options.Spacing,{'numeric'},{'vector','numel',3,'real','positive','finite'});
options.Spacing=double(options.Spacing(:).');
validateattributes(options.Frame,{'numeric'},{'scalar','integer','finite','nonnegative'});
for name={'Channel','TimeIndex'}
    validateattributes(options.(name{1}),{'numeric'},{'scalar','integer','finite','positive'});
end
for name={'DatasetID','SpacingUnit'}
    v=string(options.(name{1}));
    if ~isscalar(v)||ismissing(v)||strlength(v)==0, error('objectgeometry:Config','%s must be nonempty scalar text.',name{1}); end
    options.(name{1})=char(v);
end
if ~isempty(options.ImageSize), validateattributes(options.ImageSize,{'numeric'},{'vector','integer','positive','finite'}); end
if strcmp(options.InputType,'indices')&&isempty(options.ImageSize), error('objectgeometry:Config','Indices require ImageSize.'); end
if ~isempty(options.ObjectIDs)
    validateattributes(options.ObjectIDs,{'numeric'},{'vector','integer','positive','finite','<=',flintmax});
    if numel(unique(options.ObjectIDs))~=numel(options.ObjectIDs), error('objectgeometry:Config','ObjectIDs must be unique.'); end
end
if ~isempty(options.Connectivity), validateattributes(options.Connectivity,{'numeric'},{'scalar','integer','positive','finite'}); end
end
