function manifest = runFieldBatch(frames, fieldSpecs, supportLoader, queries, options)
%RUNFIELDBATCH Stream frames, allowing multiple XYZ fields within ONE frame.
% FIELDSPECS: struct array with Name and Loader=@(frame) -> XYZ or Data/Grid.
% SUPPORTLOADER=@(frame,fields) -> named supports (user injection point).
% QUERIES: queryFrame specifications. OPTIONS.OutputDirectory is REQUIRED;
% DatasetID='default'; Overwrite=false; RetainTables=false. Saves each completed
% frame immediately as MAT. Manifest contains frame/path/count; optional Tables
% retains SMALL result tables only. No XYZT fields/masks are preloaded.
% Failures stop execution; previously saved frames remain available.
if nargin<5, options=struct(); end
options=objectgeometry.internal.options(options,struct('OutputDirectory','', ...
    'DatasetID','default','Overwrite',false,'RetainTables',false));
validateattributes(frames,{'numeric'},{'vector','integer','nonnegative','finite','nonempty'});
if numel(unique(frames))~=numel(frames), error('objectrelativeprofiles:DuplicateFrames','Frames must be unique.'); end
if ~isa(supportLoader,'function_handle')||~isstruct(fieldSpecs)||isempty(fieldSpecs)
    error('objectrelativeprofiles:InvalidLoaders','Supply field specs and a support loader.');
end
validateattributes(options.Overwrite,{'logical'},{'scalar'});
validateattributes(options.RetainTables,{'logical'},{'scalar'});
folder=char(string(options.OutputDirectory));
if isempty(folder), error('objectrelativeprofiles:OutputDirectory','Specify an output directory for incremental results.'); end
if ~isfolder(folder), mkdir(folder); end
fieldNames=string({fieldSpecs.Name});
if numel(unique(fieldNames))~=numel(fieldNames), error('objectrelativeprofiles:DuplicateFields','Field names must be unique.'); end
manifest=struct('Frames',frames(:),'Files',strings(numel(frames),1),'RowCounts',zeros(numel(frames),1),'Tables',{{}});
if options.RetainTables, manifest.Tables=cell(numel(frames),1); end
for i=1:numel(frames)
    frame=frames(i); filename=fullfile(folder,sprintf('field_queries_frame_%09d.mat',frame));
    if isfile(filename)&&~options.Overwrite, error('objectrelativeprofiles:ExistingOutput','Output already exists: %s',filename); end
    % Scope of this helper releases all fields/supports before the next frame.
    results=localFrame(frame,fieldSpecs,supportLoader,queries,options.DatasetID);
    save(filename,'results','frame','-v7.3');
    manifest.Files(i)=string(filename); manifest.RowCounts(i)=height(results);
    if options.RetainTables, manifest.Tables{i}=results; end
    clear results
end
end
function results=localFrame(frame,specs,loader,queries,dataset)
fields=struct();
for i=1:numel(specs)
    name=char(string(specs(i).Name));
    if ~isvarname(name)||~isa(specs(i).Loader,'function_handle'), error('objectrelativeprofiles:InvalidLoader','Use valid field names and loader handles.'); end
    value=specs(i).Loader(frame); check=value;
    if isstruct(value)&&isfield(value,'Data'), check=value.Data; end
    if ~isnumeric(check)&&~islogical(check), error('objectrelativeprofiles:InvalidField','Loader must return an XYZ field.'); end
    if ndims(check)>3, error('objectrelativeprofiles:InvalidDimensions','Loader returned stacks of stacks; select one frame/component.'); end
    fields.(name)=value;
end
supports=loader(frame,fields);
for i=1:numel(queries)
    if ~isfield(queries,'Options')||isempty(queries(i).Options), queries(i).Options=struct(); end
    if ~isfield(queries(i).Options,'Support'), queries(i).Options.Support=struct(); end
    queries(i).Options.Support.Frame=frame;
    queries(i).Options.Support.DatasetID=dataset;
end
results=objectrelativeprofiles.fieldSampling.queryFrame(fields,supports,queries);
if any(results.Frame~=frame)||any(results.DatasetID~=string(dataset))
    error('objectrelativeprofiles:BatchIdentity','Prepared supports must match the current dataset/frame.');
end
end
