function combined = concatenateResults(tables)
%CONCATENATERESULTS Append frame results, retaining metadata and checking keys.
% Same column schema required. Use attachResults for new fields, not vertcat.
if ~iscell(tables)||isempty(tables), error('objectrelativeprofiles:InvalidTables','Supply a nonempty cell of tables.'); end
metadata=cell(size(tables));
for i=1:numel(tables)
    metadata{i}=tables{i}.Properties.UserData;
    % Joining to an empty schema validates keys without altering the data.
    objectrelativeprofiles.fieldSampling.attachResults(tables{i},tables{i}(:, ...
        intersect({'DatasetID','Frame','ObjectID','ComponentID'},tables{i}.Properties.VariableNames,'stable')));
end
combined=vertcat(tables{:});
keys={'DatasetID','Frame','ObjectID'};
if ismember('ComponentID',combined.Properties.VariableNames), keys{end+1}='ComponentID'; end
if height(unique(combined(:,keys)))~=height(combined), error('objectrelativeprofiles:DuplicateKeys','Repeated frame/object keys.'); end
combined.Properties.UserData=struct('FrameMetadata',{metadata});
end
