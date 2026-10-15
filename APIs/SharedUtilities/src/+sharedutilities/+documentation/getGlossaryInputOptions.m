function options = getGlossaryInputOptions(term, varargin)
%GETGLOSSARYINPUTOPTIONS Return a Name/Type/Required table of documented fields.
% Required reflects the written asterisk. Conditions remain in Type and entry
% Notes; generated layouts do not imply required user-entered arguments.
% An existing entry without a layout returns a typed, zero-row table.
inputs = sharedutilities.documentation.getGlossaryInputs(term, varargin{:});
options = table(strings(0, 1), strings(0, 1), false(0, 1), ...
    'VariableNames', {'Name', 'Type', 'Required'});
if inputs == "Inputs: {''}", return; end
body = regexp(char(inputs), '^Inputs:\s*\{(.*)\}\s*$', 'tokens', 'once');
if isempty(body)
    error('sharedutilities:GlossarySource', 'Malformed Inputs layout for %s.', string(term));
end
parts = split(string(body{1}), ';');
for k = 1:numel(parts)
    text = strtrim(parts(k));
    if strlength(text) == 0, continue; end
    field = regexp(char(text), '^(.+?)\s*=\s*(.+)$', 'tokens', 'once');
    if isempty(field)
        error('sharedutilities:GlossarySource', 'Malformed input field for %s: %s', string(term), text);
    end
    name = strtrim(string(field{1}));
    required = endsWith(name, '*');
    if required, name = strtrim(extractBefore(name, strlength(name))); end
    options(end + 1, :) = {name, strtrim(string(field{2})), required}; %#ok<AGROW>
end
end
