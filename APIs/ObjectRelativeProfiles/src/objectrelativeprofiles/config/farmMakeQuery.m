function query = farmMakeQuery(varargin)
%FARMMAKEQUERY One queryFrame request; outputs can be concatenated into an array.
% Required Name/Support/Statistics plus Field for scalar queries; Kind='vector'
% uses Fields (2/3 components); Operation handle instead uses Mode=field/samples.
% Options passed to queryField/queryVectorField; input fields are not loaded.
% Statistics default Mean for scalar, MeanVector/MeanMagnitude for vector.
% All outputs have the same fields, allowing scalar/vector/custom concatenation.
query = farmParseOptions(struct('Name','','Support','', ...
    'Statistics',{{}},'Field','','Kind','scalar','Fields',{{}}, ...
    'Operation',[],'Mode','field','Options',struct()),varargin{:});
for name = {'Name','Support'}
    v = string(query.(name{1}));
    if ~isscalar(v)||ismissing(v)||~isvarname(char(v)), error('objectrelativeprofiles:QueryConfig','%s must be a valid nonempty name.',name{1}); end
    query.(name{1}) = char(v);
end
query.Kind = validatestring(query.Kind,{'scalar','vector'});
query.Mode = validatestring(query.Mode,{'field','samples'});
if ~isstruct(query.Options)||~isscalar(query.Options), error('objectrelativeprofiles:QueryConfig','Options must be a scalar struct.'); end
if isempty(query.Statistics)
    if strcmp(query.Kind,'vector'), query.Statistics = {'MeanVector','MeanMagnitude'};
    else, query.Statistics = {'Mean'}; end
end
query.Statistics = cellstr(string(query.Statistics)); query.Statistics = query.Statistics(:).';
if isempty(query.Statistics)||any(strlength(string(query.Statistics))==0), error('objectrelativeprofiles:QueryConfig','Specify Statistics.'); end
query.Fields = cellstr(string(query.Fields)); query.Fields = query.Fields(:).';
field = string(query.Field);
if ~isscalar(field)||ismissing(field), error('objectrelativeprofiles:QueryConfig','Field must be scalar text.'); end
query.Field = char(field);
if strcmp(query.Kind,'vector')
    if ~isempty(query.Operation)||~isempty(query.Field)||~ismember(numel(query.Fields),[2 3])
        error('objectrelativeprofiles:QueryConfig','Vector query requires 2/3 Fields and no Field/Operation.');
    end
elseif ~isempty(query.Operation)
    if ~isa(query.Operation,'function_handle')||~isempty(query.Field), error('objectrelativeprofiles:QueryConfig','Use Operation handle or Field, not both.'); end
elseif isempty(query.Field)||~isvarname(query.Field)
    error('objectrelativeprofiles:QueryConfig','Scalar query requires Field or Operation.');
elseif ~isempty(query.Fields)
    error('objectrelativeprofiles:QueryConfig','Fields is for vector or operation queries.');
end
if any(~cellfun(@isvarname,query.Fields)), error('objectrelativeprofiles:QueryConfig','Fields must contain valid names.'); end
end
