function axes = farmParseTiffAxisOrder(description)
%FARMPARSETIFFAXISORDER Parse Image Stack I/O's axis marker from a TIFF comment.

axes = '';
if isstring(description) && isscalar(description)
    description = char(description);
end
if ~ischar(description) || isempty(description)
    return
end
token = regexp(description, ...
    '(?m)^MATLAB_AXIS_ORDER=([YXZCT]+)\s*$', 'tokens', 'once');
if isempty(token)
    return
end
candidate = upper(token{1});
if numel(unique(candidate)) == numel(candidate) && ...
        all(ismember('YX', candidate))
    axes = candidate;
end
end
