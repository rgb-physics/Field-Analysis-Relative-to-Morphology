function combined=attachMeasurements(base,additional,options)
%ATTACHMEASUREMENTS Attach properties by DatasetID/Frame/ObjectID, retaining order.
% MissingPolicy='error'|'missing', Overwrite=false. Grid compatibility is separate.
if nargin<3, options=struct(); end
options=objectgeometry.internal.options(options,struct('MissingPolicy','error','Overwrite',false));
options.ErrorPrefix='objectgeometry';
options.ErrorNames=struct('MissingMatches','MissingMeasurements','ExistingColumn','ExistingProperty', ...
    'MissingType','MissingColumnType');
combined=sharedutilities.structsAndTables.attachByKeys(base,additional, ...
    {'DatasetID','Frame','ObjectID'},options);
combined.Properties.UserData=struct('BaseMetadata',{base.Properties.UserData},'AdditionalMetadata',{additional.Properties.UserData});
end
