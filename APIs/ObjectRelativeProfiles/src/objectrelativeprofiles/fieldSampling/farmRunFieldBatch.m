function manifest = farmRunFieldBatch(frames, fieldSpecs, supportLoader, queries, options)
%FARMRUNFIELDBATCH Query and save one acquisition frame at a time.
% Inputs:
%   frames          Unique nonnegative acquisition frame numbers.
%   fieldSpecs      Struct array with Name and Loader=@(frame).
%   supportLoader   Handle @(frame,fields) returning named sampling supports.
%   queries         Query struct array accepted by farmQueryFrame.
%   options         OutputDirectory required; DatasetID='default',
%                   Overwrite=false, RetainTables=false, Verbose=false.
% Outputs:
%   manifest        Frames, Files, RowCounts and optionally small Tables.
%
% See also farmQueryFrame, farmMakeQuery

% FIELDSPECS: struct array with Name and Loader=@(frame) -> XYZ or Data/Grid.
% SUPPORTLOADER=@(frame,fields) -> named supports (user injection point).
% QUERIES: queryFrame specifications. OPTIONS.OutputDirectory is REQUIRED;
% DatasetID='default'; Overwrite=false; RetainTables=false. Saves each completed
% frame immediately as MAT. Manifest contains frame/path/count; optional Tables
% retains SMALL result tables only. No XYZT fields/masks are preloaded.
% Failures stop execution; previously saved frames remain available.
if nargin < 5
    options = struct();
end

options = farmOGOptions(options,struct('OutputDirectory','', ...
    'DatasetID','default','Overwrite',false,'RetainTables',false,'Verbose',false));
validateattributes(frames,{'numeric'},{'vector','integer','nonnegative','finite','nonempty'});
if numel(unique(frames)) ~= numel(frames)
    error('objectrelativeprofiles:DuplicateFrames', 'Frames must be unique.');
end

if ~isa(supportLoader,'function_handle')||~isstruct(fieldSpecs)||isempty(fieldSpecs)
    error('objectrelativeprofiles:InvalidLoaders','Supply field specs and a support loader.');
end
validateattributes(options.Overwrite,{'logical'},{'scalar'});
validateattributes(options.RetainTables,{'logical'},{'scalar'});
validateattributes(options.Verbose, {'logical'}, {'scalar'});
folder = char(string(options.OutputDirectory));

if isempty(folder)
    error('objectrelativeprofiles:OutputDirectory', 'Specify an output directory for incremental results.');
end

if ~isfolder(folder)
    mkdir(folder);
end

fieldNames = string({fieldSpecs.Name});

if numel(unique(fieldNames)) ~= numel(fieldNames)
    error('objectrelativeprofiles:DuplicateFields', 'Field names must be unique.');
end

manifest = struct('Frames',frames(:),'Files',strings(numel(frames),1),'RowCounts',zeros(numel(frames),1),'Tables',{{}});

if options.RetainTables
    manifest.Tables = cell(numel(frames), 1);
end

% Finish and save each frame before loading the next frame.
for tInd = 1:numel(frames)
    frame = frames(tInd);
    filename = fullfile(folder, sprintf('field_queries_frame_%09d.mat', frame));

    if isfile(filename) && ~options.Overwrite
        error('objectrelativeprofiles:ExistingOutput', 'Output already exists: %s', filename);
    end

    if options.Verbose
        fprintf('Processing frame %g (%d of %d): loading and querying.\n', frame, tInd, numel(frames));
    end

    % Scope of this helper releases all fields/supports before the next frame.
    results = localFrame(frame,fieldSpecs,supportLoader,queries,options.DatasetID);

    if options.Verbose
        fprintf('Processing frame %g: saving %d result rows to %s\n', frame, height(results), filename);
    end

    save(filename,'results','frame','-v7.3');
    manifest.Files(tInd) = string(filename);
    manifest.RowCounts(tInd) = height(results);

    if options.RetainTables
        manifest.Tables{tInd} = results;
    end

    clear results

    if options.Verbose
        fprintf('Completed frame %g (%d of %d).\n', frame, tInd, numel(frames));
    end
end
end


function results = localFrame(frame, specs, loader, queries, dataset)
% Internal: keep full fields and supports local to one frame.
fields = struct();

for fldInd = 1:numel(specs)
    name = char(string(specs(fldInd).Name));

    if ~isvarname(name) || ~isa(specs(fldInd).Loader, 'function_handle')
        error('objectrelativeprofiles:InvalidLoader', 'Use valid field names and loader handles.');
    end

    value = specs(fldInd).Loader(frame);
    check = value;

    if isstruct(value) && isfield(value, 'Data')
        check = value.Data;
    end

    if ~isnumeric(check) && ~islogical(check)
        error('objectrelativeprofiles:InvalidField', 'Loader must return an XYZ field.');
    end

    if ndims(check) > 3
        error('objectrelativeprofiles:InvalidDimensions', ...
            'Loader returned more than three dimensions; select one frame/component.');
    end

    fields.(name) = value;
end

supports = loader(frame,fields);

for qryInd = 1:numel(queries)
    if ~isfield(queries, 'Options') || isempty(queries(qryInd).Options)
        queries(qryInd).Options = struct();
    end

    if ~isfield(queries(qryInd).Options, 'Support')
        queries(qryInd).Options.Support = struct();
    end

    queries(qryInd).Options.Support.Frame = frame;
    queries(qryInd).Options.Support.DatasetID = dataset;
end

results = farmQueryFrame(fields,supports,queries);
if any(results.Frame~=frame)||any(results.DatasetID~=string(dataset))
    error('objectrelativeprofiles:BatchIdentity','Prepared supports must match the current dataset/frame.');
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Previously saved frames remain if a later frame fails. Existing files are
% protected unless Overwrite=true. Verbose prints load/query, save and completion
% messages; a long-running user Loader may need its own internal progress output.
% Supports and full fields are released between frames. RetainTables retains
% result tables, not source images. Overwrite and Verbose default to false.
%
% EXAMPLE
% -------------------------------------------------------------------------
% specs = struct('Name', 'Intensity', 'Loader', @(frame) ones(8, 8));
% loader = @(frame, fields) struct('objects', true(8, 8));
% q = farmMakeQuery('Name', 'Intensity', 'Support', 'objects', 'Field', 'Intensity');
% opts = struct('OutputDirectory', tempname, 'Verbose', true);
% manifest = farmRunFieldBatch([2 4], specs, loader, q, opts);
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% Prepared supports must match the requested DatasetID and Frame. No ancestry
% choices or correspondence between different acquisition times are inferred.
