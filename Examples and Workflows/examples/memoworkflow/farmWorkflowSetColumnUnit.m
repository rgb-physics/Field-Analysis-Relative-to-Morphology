function t = farmWorkflowSetColumnUnit(t,name,unit)

%FARMWORKFLOWSETCOLUMNUNIT Populate empty MATLAB table units and address columns by name.
units = t.Properties.VariableUnits;
if isempty(units), units = repmat({''},1,width(t)); end
index = find(strcmp(t.Properties.VariableNames,name),1);
if isempty(index), error('memoworkflow:Column','Unknown column: %s.',name); end
units{index} = unit;
t.Properties.VariableUnits = units;
end
