function options = farmMakeObjectOptions(varargin)
%FARMMAKEOBJECTOPTIONS Describe object preparation without loading data.
% Inputs:
%   varargin        Optional scalar struct or name/value pairs with the fields:
%                   InputType = character vector or string scalar;
%                   ImageSize = numeric vector or [];
%                   ObjectIDs = numeric vector or [];
%                   Connectivity = numeric scalar or [];
%                   DatasetID = character vector or string scalar;
%                   Frame = nonnegative integer scalar;
%                   Spacing = positive numeric three-element vector;
%                   SpacingUnit = character vector or string scalar;
%                   SourceGrid = any MATLAB value (metadata only);
%                   Transform = any MATLAB value (metadata only);
%                   Channel = positive integer scalar;
%                   TimeIndex = positive integer scalar;
% Outputs:
%   options    Editable options accepted by farmPrepareObjects.
%
% See also farmPrepareObjects, farmMeasureObjects, farmGenerateGeometry

options = farmParseOptions(struct('InputType','auto', ...
    'ImageSize',[],'ObjectIDs',[],'Connectivity',[],'DatasetID','default', ...
    'Frame',1,'Spacing',[1 1 1],'SpacingUnit','pixel','SourceGrid',[], ...
    'Transform',[],'Channel',1,'TimeIndex',1),varargin{:});
options.InputType = validatestring(options.InputType,{'auto','mask','labels','indices','components'});
validateattributes(options.Spacing,{'numeric'},{'vector','numel',3,'real','positive','finite'});
options.Spacing = double(options.Spacing(:).');
validateattributes(options.Frame,{'numeric'},{'scalar','integer','finite','nonnegative'});
for name = {'Channel','TimeIndex'}
    validateattributes(options.(name{1}),{'numeric'},{'scalar','integer','finite','positive'});
end
for name = {'DatasetID', 'SpacingUnit'}
    value = string(options.(name{1}));

    if ~isscalar(value) || ismissing(value) || strlength(value) == 0
        error('objectgeometry:Config', ...
            '%s must be nonempty scalar text. See glossary entry Prepared geometry collection.', name{1});
    end

    options.(name{1}) = char(value);
end

if ~isempty(options.ImageSize)
    validateattributes(options.ImageSize, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
end

if strcmp(options.InputType, 'indices') && isempty(options.ImageSize)
    error('objectgeometry:Config', ...
        'Indices require ImageSize. See glossary entry Linear voxel indices.');
end

if ~isempty(options.ObjectIDs)
    validateattributes(options.ObjectIDs,{'numeric'},{'vector','integer','positive','finite','<=',flintmax});
    if numel(unique(options.ObjectIDs)) ~= numel(options.ObjectIDs)
        error('objectgeometry:Config', 'ObjectIDs must be unique. See glossary entry ID group.');
    end
end

if ~isempty(options.Connectivity)
    validateattributes(options.Connectivity, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'});
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Settings are validated without preparing objects. Data-dependent checks
% remain the responsibility of farmPrepareObjects. Replace DatasetID, Frame
% and grid metadata with the actual values before analysis.
% farmMeasureObjects accepts these options directly. farmGenerateGeometry,
% farmMeasureFilaments and farmTrackOverlaps accept them under Identity.
%
% EXAMPLES
% -------------------------------------------------------------------------
% opts = farmMakeObjectOptions('InputType', 'labels', 'DatasetID', 'example');
% opts = farmMakeObjectOptions('InputType', 'indices', 'ImageSize', [20 30 10]);
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Spacing defaults to [1 1 1] in YXZ order and SpacingUnit to 'pixel'.
% ImageSize and linear indices refer to the current array grid.
