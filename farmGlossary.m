function value = farmGlossary(varargin)
%FARMGLOSSARY Browse FARM's glossary and data dictionary from MATLAB.
% farmGlossary                         Display all terms, types and headings.
% entries = farmGlossary;              Return the complete table of string columns.
% entry = farmGlossary("Experiment");  Return one entry as a struct of strings.
% type = farmGlossary("Experiment", "DataType");
% inputs = farmGlossary("Matrix", "Inputs"); % "Inputs: {''}" when no layout exists
% options = farmGlossary("Experiment", "InputOptions"); % Name/Type/Required table
% matches = farmGlossary("search", "geometry", "SearchIn", ["Term", "Definition"]);
% matches = farmGlossary("search", "Count", "Section", "DataDictionary");
% terms = farmGlossary("list", "Section", ["Glossary", "DataDictionary"]);
% entries = farmGlossary("catalog", "Section", "Glossary");
%
% Section and SearchIn are optional; both default to all. Section accepts
% Glossary or DataDictionary (one name or a string vector). SearchIn accepts
% Term, Section, Group, DataType, Definition, Inputs, Notes (one or several).
% Group holds topical headings within a section; Section holds the document
% division. SearchIn is for search only. All searches ignore case.
% Direct lookups prefer exact spelling: Geometry and geometry remain distinct.
% A Section filter is applied before lookup. Omit it to include both sections.
%
% The document GLOSSARY-CAPABILITIES-MOCKUP.md is the single source of entries.
% Some layouts describe generated fields rather than constructor arguments;
% read Notes for scope/conditions. With no output argument, display the result.
% Explicit getters include farmGetGlossaryEntry and farmGetGlossaryInputOptions.

root = fileparts(mfilename('fullpath'));
if isempty(which('farmGlossaryEntries'))
    farmSetup();
end

if isempty(varargin)
    value = farmGlossaryEntries();
else
    validateattributes(varargin{1}, {'char', 'string'}, {'nonempty'});
    term = string(varargin{1});
    if ~isscalar(term) || ismissing(term) || strlength(strtrim(term)) == 0
        error('sharedutilities:GlossaryTerm', 'Supply one nonempty glossary term.');
    end
    term = strtrim(term);
    remaining = varargin(2:end);
    if strcmpi(term, 'search')
        if isempty(remaining)
            error('sharedutilities:GlossarySearch', 'Supply search text: glossary("search", "distance").');
        end
        value = farmSearchGlossary(remaining{1}, remaining{2:end});
    elseif strcmpi(term, 'list') || strcmpi(term, 'catalog')
        value = farmGlossaryEntries(remaining{:});
        if strcmpi(term, 'list'), value = value.Term; end
    else
        property = "";
        if ~isempty(remaining)
            candidate = string(remaining{1});
            isSectionOption = isscalar(candidate) && strcmpi(candidate, 'Section') ...
                && mod(numel(remaining), 2) == 0;
            if isscalar(candidate) && ~ismissing(candidate) && ~isSectionOption
                property = candidate;
                remaining = remaining(2:end);
            end
        end
        entry = farmGetGlossaryEntry(term, remaining{:});
        if strlength(property) == 0
            value = entry;
        elseif strcmpi(property, 'InputOptions')
            value = farmGetGlossaryInputOptions(term, remaining{:});
        else
            names = fieldnames(entry);
            selected = find(strcmpi(property, names), 1);
            if isempty(selected)
                error('sharedutilities:GlossaryProperty', ...
                    'Use Term, Section, Group, DataType, Definition, Inputs, Notes or InputOptions.');
            end
            value = entry.(names{selected});
        end
    end
end

if nargout == 0
    if isstruct(value)
        fprintf('%s [%s]\n%s / %s\n\n%s\n%s\n', ...
            value.Term, value.DataType, value.Section, value.Group, value.Definition, value.Inputs);
        if strlength(value.Notes) > 0, fprintf('\n%s\n', value.Notes); end
    elseif istable(value)
        if width(value) > 4, disp(value(:, {'Term', 'DataType', 'Section', 'Group'}));
        else, disp(value); end
    elseif isstring(value) && isscalar(value)
        fprintf('%s\n', value);
    else
        disp(value);
    end
    clear value
end
end
