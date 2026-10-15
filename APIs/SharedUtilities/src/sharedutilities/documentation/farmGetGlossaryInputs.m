function inputs = farmGetGlossaryInputs(term, varargin)
%FARMGETGLOSSARYINPUTS Return the Inputs layout, or exactly "Inputs: {''}".
% Some layouts describe generated fields. See farmGetGlossaryEntry(term).Notes
% for scope and conditional requirements; this is not function validation.
entry = farmGetGlossaryEntry(term, varargin{:});
inputs = entry.Inputs;
end
