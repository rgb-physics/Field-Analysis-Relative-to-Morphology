function dataType = farmGetGlossaryDataType(term, varargin)
%FARMGETGLOSSARYDATATYPE Return the documented representation as a string scalar.
% Inputs:
%   term            One glossary or Data Dictionary entry name.
%   varargin        Optional Section filter as name/value pairs.
% Outputs:
%   dataType        Documented MATLAB representation as a string scalar.

entry = farmGetGlossaryEntry(term, varargin{:});
dataType = entry.DataType;
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGETGLOSSARYDATATYPE Return the documented representation as a string scalar.
