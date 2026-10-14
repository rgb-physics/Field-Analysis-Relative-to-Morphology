function combined = concatenateMeasurements(tables)
%CONCATENATEMEASUREMENTS Stack per-frame tables without discarding grid metadata.
% TABLES is a nonempty cell array with matching schemas. Order is retained;
% duplicate DatasetID/Frame/ObjectID is an error. Different property schemas
% must be aligned explicitly before concatenation. No implicit ID renumbering.
if ~iscell(tables)||isempty(tables), error('objectgeometry:InvalidTables','Supply a nonempty cell of tables.'); end
metadata=cell(size(tables));
for i=1:numel(tables)
    objectgeometry.internal.validateKeys(tables{i});
    metadata{i}=tables{i}.Properties.UserData;
end
combined=vertcat(tables{:});
objectgeometry.internal.validateKeys(combined);
combined.Properties.UserData=struct('FrameMetadata',{metadata});
end
