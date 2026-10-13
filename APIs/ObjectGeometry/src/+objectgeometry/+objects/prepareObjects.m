function objects = prepareObjects(input, options)
%PREPAREOBJECTS Preserve supplied identities or compute connected components.
% INPUT: logical mask, numeric mask/labels, TIFF path/ImageStackIO image, bwconncomp structure, cell of
% index vectors, or an already prepared structure. No label volume allocated.
% Numeric binary input defaults to mask; InputType='labels' removes ambiguity.
% Nonzero labels define one object each, including disconnected regions.
% OPTIONS: InputType='auto'|'mask'|'labels'|'indices'|'components'; ImageSize=[]
% (required for index cells); ObjectIDs=[] (for masks/components/index cells);
% Connectivity=[] (8/26 default); DatasetID='default'; Frame=1;
% Channel=1 and TimeIndex=1 select TIFF/ImageStackIO data. Image calibration
% is inherited unless Spacing/SpacingUnit are explicitly overridden.
% Spacing=[1 1 1] in YXZ; SpacingUnit='pixel'; SourceGrid=[]; Transform=[].
% Grid metadata describes CURRENT indices. SourceGrid and Transform record
% previous grids/mappings; spacing is recorded, not used to resample input.
if nargin<2, options=struct(); end
if isempty(options), options=struct(); end
if isstruct(input)&&isscalar(input)&&isfield(input,'ObjectGeometryVersion')
    if ~isempty(fieldnames(options))
        error('objectgeometry:PreparedOptions','Prepared objects already contain identity/grid metadata.');
    end
    objects=input; return
end
explicitSpacing=isfield(options,'Spacing'); explicitUnit=isfield(options,'SpacingUnit');
options=objectgeometry.internal.options(options,struct('InputType','auto', ...
    'ImageSize',[],'ObjectIDs',[],'Connectivity',[],'DatasetID','default', ...
    'Frame',1,'Spacing',[1 1 1],'SpacingUnit','pixel','SourceGrid',[], 'Transform',[], ...
    'Channel',1,'TimeIndex',1));
if ischar(input)||(isstring(input)&&isscalar(input))
    input=imagestackio.readTiff(input);
end
if isstruct(input)&&isscalar(input)&&isfield(input,'Data')
    if ~isfield(input,'Axes')||~strcmp(char(input.Axes),'YXZCT')
        error('objectgeometry:ImageAxes','Image structures must use ImageStackIO YXZCT axes.');
    end
    validateattributes(options.Channel,{'numeric'},{'scalar','integer','positive','<=',size(input.Data,4)});
    validateattributes(options.TimeIndex,{'numeric'},{'scalar','integer','positive','<=',size(input.Data,5)});
    if ~explicitSpacing&&isfield(input,'Spacing'), options.Spacing=input.Spacing; end
    if ~explicitUnit&&isfield(input,'SpacingUnit'), options.SpacingUnit=input.SpacingUnit; end
    input=input.Data(:,:,:,options.Channel,options.TimeIndex);
end
type=validatestring(options.InputType,{'auto','mask','labels','indices','components'});
if strcmp(type,'auto')
    if iscell(input)
        type='indices';
    elseif isstruct(input)
        type='components';
    elseif islogical(input)||all(input(:)==0|input(:)==1)
        type='mask';
    else
        type='labels';
    end
end
ids=[]; conn=options.Connectivity;
switch type
    case {'mask','labels'}
        validateattributes(input,{'numeric','logical'},{'real','finite','nonsparse','nonempty'});
        if ndims(input)>3, error('objectgeometry:InvalidDimensions','Select one spatial image/channel/time.'); end
        sz=size(input); dims=ndims(input);
        if strcmp(type,'mask')
            if any(input(:)~=0 & input(:)~=1), error('objectgeometry:InvalidMask','Masks must contain zeros/ones.'); end
            if isempty(conn), if dims==2, conn=8; else, conn=26; end, end
            cc=bwconncomp(logical(input),conn); lists=cc.PixelIdxList;
        else
            validateattributes(input,{'numeric','logical'},{'integer','nonnegative','<=',flintmax});
            ids=double(unique(input(input>0))); lists=cell(1,numel(ids));
            for i=1:numel(ids), lists{i}=find(input==ids(i)); end
        end
    case 'components'
        if ~(isstruct(input)&&isscalar(input)&&all(isfield(input,{'ImageSize','PixelIdxList','NumObjects'})))
            error('objectgeometry:InvalidComponents','Supply a bwconncomp structure.');
        end
        sz=input.ImageSize; lists=input.PixelIdxList; dims=numel(sz);
        if input.NumObjects~=numel(lists), error('objectgeometry:InvalidComponents','Component count does not match index lists.'); end
        if isfield(input,'Connectivity'), conn=input.Connectivity; end
    case 'indices'
        if ~iscell(input), error('objectgeometry:InvalidIndices','Supply a cell array of index vectors.'); end
        sz=options.ImageSize; dims=numel(sz); lists=input;
end
validateattributes(sz,{'numeric'},{'real','finite','vector','integer','positive'});
sz=double(sz(:).');
if ~ismember(dims,[2 3]), error('objectgeometry:InvalidDimensions','ImageSize must contain two or three spatial dimensions.'); end
if isempty(conn), if dims==2, conn=8; else, conn=26; end, end
validateattributes(conn,{'numeric'},{'scalar','integer','real','finite'});
allowed=[6 18 26]; if dims==2, allowed=[4 8]; end
if ~ismember(conn,allowed), error('objectgeometry:InvalidConnectivity','Connectivity must match spatial dimensions.'); end
lists=reshape(lists,1,[]);
for i=1:numel(lists)
    validateattributes(lists{i},{'numeric'},{'real','finite','vector','integer','positive','<=',prod(sz),'nonempty'});
    lists{i}=unique(double(lists{i}(:)),'sorted');
end
if isempty(ids)
    if isempty(options.ObjectIDs), ids=(1:numel(lists)).'; else, ids=double(options.ObjectIDs(:)); end
elseif ~isempty(options.ObjectIDs)
    error('objectgeometry:LabelIDs','Label input already supplies IDs; do not override them.');
end
validateattributes(ids,{'numeric'},{'real','finite','integer','positive','<=',flintmax});
if numel(ids)~=numel(lists)||numel(unique(ids))~=numel(ids)
    error('objectgeometry:InvalidObjectIDs','Supply one unique positive ID per index group.');
end
validateattributes(options.Frame,{'numeric'},{'scalar','real','finite','integer','nonnegative'});
dataset=string(options.DatasetID); unit=string(options.SpacingUnit);
if ~isscalar(dataset)||ismissing(dataset)||strlength(dataset)==0||~isscalar(unit)||ismissing(unit)||strlength(unit)==0
    error('objectgeometry:InvalidMetadata','DatasetID and SpacingUnit must be nonempty scalar text.');
end
spacing=double(options.Spacing(:).');
validateattributes(spacing,{'numeric'},{'vector','numel',3,'real','finite','positive'});
cc=struct('Connectivity',conn,'ImageSize',sz,'NumObjects',numel(lists),'PixelIdxList',{lists});
grid=struct('Size',sz,'Axes','YX','Spacing',spacing,'SpacingUnit',unit);
if dims==3, grid.Axes='YXZ'; end
objects=struct('ObjectGeometryVersion',1,'ObjectIDs',ids(:),'DatasetID',dataset, ...
    'Frame',double(options.Frame),'Components',cc,'Grid',grid, ...
    'SourceGrid',options.SourceGrid,'Transform',options.Transform,'InputType',type);
end
