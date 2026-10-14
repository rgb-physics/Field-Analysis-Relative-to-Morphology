function combined = attachMeasurements(base, additional, options)
%ATTACHMEASUREMENTS Attach new columns by identity, never by row position.
% Default requires every BASE row to match. Additional rows not in BASE are
% allowed (e.g. BASE was filtered). MissingPolicy='missing' fills unmatched
% rows with typed MATLAB missing values (integer/logical columns become double
% with NaN). Existing columns require Overwrite=true. BASE order is preserved.
% Grid compatibility must be checked during querying; this joins keyed tables.
if nargin<3, options=struct(); end
options=objectgeometry.internal.options(options,struct('MissingPolicy','error','Overwrite',false));
policy=validatestring(options.MissingPolicy,{'error','missing'});
validateattributes(options.Overwrite,{'logical'},{'scalar'});
keys=objectgeometry.internal.validateKeys(base);
objectgeometry.internal.validateKeys(additional);
[present,position]=ismember(base(:,keys),additional(:,keys));
if any(~present)&&strcmp(policy,'error')
    error('objectgeometry:MissingMeasurements','%d destination identities have no query result.',nnz(~present));
end
columns=setdiff(additional.Properties.VariableNames,keys,'stable');
combined=base;
for i=1:numel(columns)
    name=columns{i};
    if ismember(name,base.Properties.VariableNames)&&~options.Overwrite
        error('objectgeometry:ExistingProperty','Column %s already exists; explicitly enable Overwrite.',name);
    end
    if all(present)
        combined.(name)=additional.(name)(position,:);
    else
        values=additional.(name);
        if isinteger(values)||islogical(values), values=double(values); end
        % Explicit numeric/cell/text handling avoids default zeros for missing.
        if isnumeric(values)
            fill=nan(height(base),size(values,2),'like',values);
        elseif isstring(values)
            fill=strings(height(base),size(values,2)); fill(:)=missing;
        elseif iscell(values)
            fill=cell(height(base),size(values,2));
        else
            error('objectgeometry:MissingColumnType','Missing results currently support numeric, string and cell columns.');
        end
        fill(present,:)=values(position(present),:); combined.(name)=fill;
    end
end
old=base.Properties.UserData;
combined.Properties.UserData=struct('BaseMetadata',old,'AdditionalMetadata',additional.Properties.UserData);
end
