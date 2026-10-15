function value = farmOGOptions(value, defaults)
%FARMOGOPTIONS Validate and complete a scalar options struct.
if isempty(value), value = struct(); end
if ~(isstruct(value)&&isscalar(value))
    error('objectgeometry:InvalidOptions','Options must be a scalar struct.');
end
unknown = setdiff(fieldnames(value),fieldnames(defaults));
if ~isempty(unknown), error('objectgeometry:UnknownOption','Unknown option: %s',unknown{1}); end
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(value,names{i}), value.(names{i}) = defaults.(names{i}); end
end
end
