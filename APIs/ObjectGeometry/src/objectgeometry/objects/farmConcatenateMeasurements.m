function combined = farmConcatenateMeasurements(tables)
%FARMCONCATENATEMEASUREMENTS Append matching schemas with unique object identities.
% Inputs:
%   tables          Nonempty cell array of tables with matching schemas.
% Outputs:
%   combined        Appended measurement table with unique object identities.

combined = farmConcatenateByKeys(tables, ...
                                 {'DatasetID', 'Frame', 'ObjectID'}, struct('ErrorPrefix', 'objectgeometry'));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMCONCATENATEMEASUREMENTS Append matching schemas with unique object identities.
