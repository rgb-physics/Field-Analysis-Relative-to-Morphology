function inputs = farmGetGlossaryInputs(term, varargin)
%FARMGETGLOSSARYINPUTS Return the Inputs layout, or exactly "Inputs: {''}".
% Inputs:
%   term            One glossary or Data Dictionary entry name.
%   varargin        Optional Section filter as name/value pairs.
% Outputs:
%   inputs          Documented Inputs layout, or exactly Inputs: {''}.

entry = farmGetGlossaryEntry(term, varargin{:});
inputs = entry.Inputs;
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGETGLOSSARYINPUTS Return the Inputs layout, or exactly "Inputs: {''}".
% Some layouts describe generated fields. See farmGetGlossaryEntry(term).Notes
% for scope and conditional requirements; this is not function validation.
