function combined=concatenateMeasurements(tables)
%CONCATENATEMEASUREMENTS Append matching schemas with unique object identities.
combined=sharedutilities.structsAndTables.concatenateByKeys(tables, ...
    {'DatasetID','Frame','ObjectID'},struct('ErrorPrefix','objectgeometry'));
end
