function keys = farmOGValidateKeys(t)
%FARMOGVALIDATEKEYS Stable object identity; shared validation, domain error IDs.
keys = {'DatasetID','Frame','ObjectID'};
farmValidateTableKeys(t,keys,struct('ErrorPrefix','objectgeometry'));
end
