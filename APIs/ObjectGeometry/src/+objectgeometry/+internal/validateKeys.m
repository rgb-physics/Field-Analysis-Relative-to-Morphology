function keys = validateKeys(t)
%VALIDATEKEYS Stable identity for concatenation and later query attachment.
keys={'DatasetID','Frame','ObjectID'};
if ~istable(t)||~all(ismember(keys,t.Properties.VariableNames))
    error('objectgeometry:MissingKeys','Table must contain DatasetID, Frame and ObjectID.');
end
if ~isstring(t.DatasetID)||size(t.DatasetID,2)~=1||any(ismissing(t.DatasetID))
    error('objectgeometry:InvalidKeys','DatasetID must contain nonmissing scalar strings.');
end
validateattributes(t.Frame,{'numeric'},{'real','finite','integer','nonnegative'});
validateattributes(t.ObjectID,{'numeric'},{'real','finite','integer','positive','<=',flintmax});
if size(t.Frame,2)~=1||size(t.ObjectID,2)~=1
    error('objectgeometry:InvalidKeys','Frame and ObjectID must each be one column.');
end
if height(unique(t(:,keys)))~=height(t)
    error('objectgeometry:DuplicateKeys','Duplicate DatasetID/Frame/ObjectID keys.');
end
end
