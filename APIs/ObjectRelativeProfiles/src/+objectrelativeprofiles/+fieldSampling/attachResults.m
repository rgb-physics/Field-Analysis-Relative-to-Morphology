function combined = attachResults(base, additional, options)
%ATTACHRESULTS Join queried columns by identity, preserving destination order.
% Works with ObjectGeometry tables or query results. ComponentID defaults to
% zero for parent-level measurements. MissingPolicy='error'|'missing';
% Overwrite=false. Metadata from both tables is retained. Extra incoming rows
% are allowed; duplicate keys are rejected. No automatic spatial alignment.
if nargin<3, options=struct(); end
options=objectgeometry.internal.options(options,struct('MissingPolicy','error','Overwrite',false));
policy=validatestring(options.MissingPolicy,{'error','missing'});
validateattributes(options.Overwrite,{'logical'},{'scalar'});
hadComponent=ismember('ComponentID',base.Properties.VariableNames);
if ~hadComponent, base.ComponentID=zeros(height(base),1); end
if ~ismember('ComponentID',additional.Properties.VariableNames), additional.ComponentID=zeros(height(additional),1); end
keys={'DatasetID','Frame','ObjectID','ComponentID'};
localKeys(base,keys); localKeys(additional,keys);
[present,position]=ismember(base(:,keys),additional(:,keys));
if any(~present)&&strcmp(policy,'error')
    error('objectrelativeprofiles:MissingResults','%d destination keys have no incoming result.',nnz(~present));
end
combined=base; names=setdiff(additional.Properties.VariableNames,keys,'stable');
for i=1:numel(names)
    name=names{i};
    if ismember(name,base.Properties.VariableNames)&&~options.Overwrite
        error('objectrelativeprofiles:ExistingColumn','Column %s already exists.',name);
    end
    values=additional.(name);
    if all(present), combined.(name)=values(position,:); continue; end
    if isinteger(values)||islogical(values), values=double(values); end
    if isnumeric(values)
        fill=nan(height(base),size(values,2),'like',values);
    elseif iscell(values)
        fill=cell(height(base),size(values,2));
    elseif isstring(values)
        fill=strings(height(base),size(values,2)); fill(:)=missing;
    else
        error('objectrelativeprofiles:MissingType','Missing results support numeric, string and cell columns.');
    end
    fill(present,:)=values(position(present),:); combined.(name)=fill;
end
if ~hadComponent && all(combined.ComponentID==0), combined=removevars(combined,'ComponentID'); end
combined.Properties.UserData=struct('Base',base.Properties.UserData,'Added',additional.Properties.UserData);
end
function localKeys(t,keys)
if ~istable(t)||~all(ismember(keys,t.Properties.VariableNames))
    error('objectrelativeprofiles:MissingKeys','Results require DatasetID/Frame/ObjectID and optional ComponentID.');
end
validateattributes(t.Frame,{'numeric'},{'real','finite','integer','nonnegative'});
validateattributes(t.ObjectID,{'numeric'},{'real','finite','integer','positive','<=',flintmax});
validateattributes(t.ComponentID,{'numeric'},{'real','finite','integer','nonnegative'});
if ~isstring(t.DatasetID)||any(ismissing(t.DatasetID))
    error('objectrelativeprofiles:InvalidKeys','DatasetID must be nonmissing strings.');
end
if height(unique(t(:,keys)))~=height(t), error('objectrelativeprofiles:DuplicateKeys','Duplicate identity keys.'); end
end
