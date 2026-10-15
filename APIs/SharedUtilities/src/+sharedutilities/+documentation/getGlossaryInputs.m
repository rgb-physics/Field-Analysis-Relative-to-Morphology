function inputs = getGlossaryInputs(term, varargin)
%GETGLOSSARYINPUTS Return the Inputs layout, or exactly "Inputs: {''}".
% Some layouts describe generated fields. See getGlossaryEntry(term).Notes
% for scope and conditional requirements; this is not function validation.
entry = sharedutilities.documentation.getGlossaryEntry(term, varargin{:});
inputs = entry.Inputs;
end
