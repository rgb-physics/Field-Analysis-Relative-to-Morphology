function results = queryFrame(fields, supports, queries)
%QUERYFRAME All named queries for one frame; accepts several XYZ fields.
% FIELDS is a struct of named XYZ arrays or struct(Data,Grid).
% SUPPORTS is a struct of named raw/prepared supports. QUERIES is a struct
% array; each query has Name (unique column prefix), Support (support name),
% Statistics, optional Options, and EITHER Field (field name) OR Operation
% Vector queries use Kind='vector', Fields={component names in coordinate
% order}, and Options for queryVectorField. Operations remain scalar queries.
% (@(fields) ...) with Mode='field'|'samples' and optional Fields (names needed).
% Field operations return one matching XYZ field. Sample operations receive
% selected vectors in a named struct and return one value per location.
% Operation handles can call other functions internally. All queries are
% attached by identity. Supports with different ID sets require explicit
% querying/attachment with missing policy rather than silent row expansion.
if ~isstruct(fields)||~isscalar(fields)||~isstruct(supports)||~isscalar(supports)||~isstruct(queries)||isempty(queries)
    error('objectrelativeprofiles:InvalidFrame','Use named field/support structs and a nonempty query struct array.');
end
names=string({queries.Name});
if numel(unique(names))~=numel(names), error('objectrelativeprofiles:DuplicateQueryNames','Query names must be unique.'); end
results=table();
for i=1:numel(queries)
    q=queries(i); opts=struct(); if isfield(q,'Options')&&~isempty(q.Options), opts=q.Options; end
    opts.FieldName=char(string(q.Name)); supportName=char(string(q.Support));
    if ~isfield(supports,supportName), error('objectrelativeprofiles:MissingSupport','Unknown support: %s',supportName); end
    if ~isfield(opts,'Support'), opts.Support=struct(); end
    opts.Support.Name=supportName;
    if isfield(q,'Kind')&&strcmpi(string(q.Kind),'vector')
        if ~isfield(q,'Fields')||isempty(q.Fields)
            error('objectrelativeprofiles:ComponentNames','Vector query Fields must name components in order.');
        end
        opts.ComponentNames=q.Fields;
        t=objectrelativeprofiles.fieldSampling.queryVectorField(fields,supports.(supportName),q.Statistics,opts);
        if i==1, results=t;
        else, results=objectrelativeprofiles.fieldSampling.attachResults(results,t); end
        continue
    end
    if isfield(q,'Operation')&&~isempty(q.Operation)
        if ~isa(q.Operation,'function_handle'), error('objectrelativeprofiles:InvalidOperation','Operation must be a function handle.'); end
        inputs=fields;
        if isfield(q,'Fields')&&~isempty(q.Fields)
            required=cellstr(string(q.Fields)); inputs=struct();
            for j=1:numel(required), inputs.(required{j})=fields.(required{j}); end
        end
        mode='field'; if isfield(q,'Mode')&&~isempty(q.Mode), mode=validatestring(q.Mode,{'field','samples'}); end
        if strcmp(mode,'samples'), data=inputs; opts.SampleOperation=q.Operation;
        else
            plain=struct(); fn=fieldnames(inputs);
            for j=1:numel(fn)
                value=inputs.(fn{j}); if isstruct(value)&&isfield(value,'Data'), value=value.Data; end
                validateattributes(value,{'numeric','logical'},{'real','nonempty','nonsparse'});
                if ndims(value)>3, error('objectrelativeprofiles:InvalidDimensions','Operations accept XYZ fields only.'); end
                if j==1, operationSize=size(value);
                elseif ~isequal(size(value),operationSize)
                    error('objectrelativeprofiles:GridMismatch','Fields combined by an operation must match dimensions.');
                end
                plain.(fn{j})=value;
            end
            data=q.Operation(plain);
        end
    else
        fieldName=char(string(q.Field));
        if ~isfield(fields,fieldName), error('objectrelativeprofiles:MissingField','Unknown field: %s',fieldName); end
        data=fields.(fieldName);
    end
    t=objectrelativeprofiles.fieldSampling.queryField(data,supports.(supportName),q.Statistics,opts);
    if i==1, results=t;
    else, results=objectrelativeprofiles.fieldSampling.attachResults(results,t); end
end
end
