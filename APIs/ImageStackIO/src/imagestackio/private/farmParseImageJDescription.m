function metadata = farmParseImageJDescription(description)
%FARMPARSEIMAGEJDESCRIPTION Parse the channel/slice/frame fields in ImageJ tags.

metadata = struct('IsImageJ', false, 'IsHyperstack', false, ...
    'Channels', [], 'Slices', [], 'Frames', [], 'Mode', '', ...
    'Spacing', [], 'Unit', '');
if isstring(description) && isscalar(description)
    description = char(description);
end
if ~ischar(description) || isempty(description)
    return
end

metadata.IsImageJ = ~isempty(regexp(description, ...
    '(?m)^ImageJ=', 'once'));
if ~metadata.IsImageJ
    return
end
metadata.Channels = localReadPositiveInteger(description, 'channels');
metadata.Slices = localReadPositiveInteger(description, 'slices');
metadata.Frames = localReadPositiveInteger(description, 'frames');
metadata.IsHyperstack = ~isempty(regexp(description, ...
    '(?m)^hyperstack=true\s*$', 'once')) && ...
    ~isempty(metadata.Channels) && ~isempty(metadata.Slices) && ...
    ~isempty(metadata.Frames);
modeToken = regexp(description, '(?m)^mode=([^\r\n]+)', 'tokens', 'once');
if ~isempty(modeToken)
    metadata.Mode = modeToken{1};
end
metadata.Spacing = localReadPositiveScalar(description, 'spacing');
unitToken = regexp(description, '(?m)^unit=([^\r\n]+)', 'tokens', 'once');
if ~isempty(unitToken)
    metadata.Unit = strtrim(unitToken{1});
end
end

function value = localReadPositiveInteger(description, fieldName)
pattern = ['(?m)^' fieldName '=(\d+)\s*$'];
token = regexp(description, pattern, 'tokens', 'once');
value = [];
if ~isempty(token)
    parsed = str2double(token{1});
    if isfinite(parsed) && parsed >= 1 && parsed == fix(parsed)
        value = parsed;
    end
end
end

function value = localReadPositiveScalar(description, fieldName)
numberPattern = '([+]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)';
token = regexp(description, ...
    ['(?m)^' fieldName '=' numberPattern '\s*$'], 'tokens', 'once');
value = [];
if ~isempty(token)
    parsed = str2double(token{1});
    if isfinite(parsed) && parsed > 0
        value = parsed;
    end
end
end
