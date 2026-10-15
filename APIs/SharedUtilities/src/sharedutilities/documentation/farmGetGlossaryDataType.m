function dataType = farmGetGlossaryDataType(term, varargin)
%FARMGETGLOSSARYDATATYPE Return the documented representation as a string scalar.
entry = farmGetGlossaryEntry(term, varargin{:});
dataType = entry.DataType;
end
