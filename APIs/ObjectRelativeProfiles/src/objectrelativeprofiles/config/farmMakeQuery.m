function query = farmMakeQuery(varargin)
%FARMMAKEQUERY Describe one field query without loading or sampling data.
% Inputs:
%   varargin   Scalar options struct or name/value pairs. Name and Support
%              are required. Select Field, vector Fields, or Operation.
% Outputs:
%   query      Query construct accepted by farmQueryFrame.
%
% See also farmQueryFrame, farmQueryField, farmQueryVectorField

query = farmParseOptions(struct('Name','','Support','', ...
    'Statistics',{{}},'Field','','Kind','scalar','Fields',{{}}, ...
    'Operation',[],'Mode','field','Options',struct()),varargin{:});
% Validate the output name and the name of the sampling support.
for name = {'Name', 'Support'}
    value = string(query.(name{1}));

    if ~isscalar(value) || ismissing(value) || ~isvarname(char(value))
        error('objectrelativeprofiles:QueryConfig', ...
            '%s must be a valid nonempty name. See glossary entry Query.', name{1});
    end

    query.(name{1}) = char(value);
end

query.Kind = validatestring(query.Kind, {'scalar', 'vector'});
query.Mode = validatestring(query.Mode, {'field', 'samples'});

if ~isstruct(query.Options) || ~isscalar(query.Options)
    error('objectrelativeprofiles:QueryConfig', ...
        'Options must be a scalar struct. See glossary entry Query.');
end

if isempty(query.Statistics)
    if strcmp(query.Kind, 'vector')
        query.Statistics = {'MeanVector', 'MeanMagnitude'};
    else
        query.Statistics = {'Mean'};
    end
end

query.Statistics = cellstr(string(query.Statistics));
query.Statistics = query.Statistics(:).';

if isempty(query.Statistics) || any(strlength(string(query.Statistics)) == 0)
    error('objectrelativeprofiles:QueryConfig', 'Specify Statistics. See glossary entry Query.');
end

query.Fields = cellstr(string(query.Fields));
query.Fields = query.Fields(:).';
field = string(query.Field);

if ~isscalar(field) || ismissing(field)
    error('objectrelativeprofiles:QueryConfig', 'Field must be scalar text. See glossary entry Query.');
end

query.Field = char(field);

% Keep scalar, vector and derived-field requests explicit.
if strcmp(query.Kind, 'vector')
    if ~isempty(query.Operation) || ~isempty(query.Field) || ~ismember(numel(query.Fields), [2 3])
        error('objectrelativeprofiles:QueryConfig', ...
            'A vector Query requires two or three Fields and empty Field/Operation.');
    end
elseif ~isempty(query.Operation)
    if ~isa(query.Operation, 'function_handle') || ~isempty(query.Field)
        error('objectrelativeprofiles:QueryConfig', ...
            'Use an Operation handle or Field, not both. See glossary entry Query.');
    end
elseif isempty(query.Field) || ~isvarname(query.Field)
    error('objectrelativeprofiles:QueryConfig', ...
        'A scalar Query requires a valid Field name or an Operation handle.');
elseif ~isempty(query.Fields)
    error('objectrelativeprofiles:QueryConfig', 'Fields is for vector or operation queries. See glossary entry Query.');
end

if any(~cellfun(@isvarname, query.Fields))
    error('objectrelativeprofiles:QueryConfig', 'Fields must contain valid names. See glossary entry Query.');
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Scalar statistics default to Mean; vector statistics default to MeanVector
% and MeanMagnitude. Options are passed to the sampling operation. Requested
% statistic names are validated by that operation, not by this builder.
% All queries have the same field layout and can be concatenated into an array.
%
% EXAMPLES
% -------------------------------------------------------------------------
% q = farmMakeQuery('Name', 'BoundaryIntensity', 'Support', 'boundary', ...
%     'Field', 'Intensity', 'Statistics', {'Mean', 'Std'});
% v = farmMakeQuery('Name', 'Velocity', 'Support', 'objects', ...
%     'Kind', 'vector', 'Fields', {'VX', 'VY', 'VZ'});
% d = farmMakeQuery('Name', 'Difference', 'Support', 'objects', ...
%     'Fields', {'A', 'B'}, 'Operation', @(f) double(f.A) - double(f.B));
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% Name supplies the result-column prefix; Support names the sampling locations.
% Geometry identity is supplied to farmQueryFrame independently of this Query.
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Fields for a vector Query are in the intended component order. This builder
% does not establish spatial registration or convert units.
