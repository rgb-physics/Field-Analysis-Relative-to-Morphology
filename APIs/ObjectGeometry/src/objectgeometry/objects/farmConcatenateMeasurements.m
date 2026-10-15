function combined = farmConcatenateMeasurements(tables)
%FARMCONCATENATEMEASUREMENTS Append matching schemas with unique object identities.
combined = farmConcatenateByKeys(tables, ...
    {'DatasetID','Frame','ObjectID'},struct('ErrorPrefix','objectgeometry'));
end
