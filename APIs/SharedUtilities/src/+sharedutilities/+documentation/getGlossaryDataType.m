function dataType = getGlossaryDataType(term, varargin)
%GETGLOSSARYDATATYPE Return the documented representation as a string scalar.
entry = sharedutilities.documentation.getGlossaryEntry(term, varargin{:});
dataType = entry.DataType;
end
