function keys=validateKeys(t)
%VALIDATEKEYS Stable object identity; shared validation, domain error IDs.
keys={'DatasetID','Frame','ObjectID'};
sharedutilities.structsAndTables.validateTableKeys(t,keys,struct('ErrorPrefix','objectgeometry'));
end
