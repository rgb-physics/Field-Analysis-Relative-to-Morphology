function combined=attachResults(base,additional,options)
%ATTACHRESULTS Component-aware keyed join; absent ComponentID means parent (0).
% MissingPolicy='error'|'missing', Overwrite=false. Spatial alignment is separate.
if nargin<3, options=struct(); end
options=objectgeometry.internal.options(options,struct('MissingPolicy','error','Overwrite',false));
primary={'DatasetID','Frame','ObjectID'};
v=struct('AllowRepeated',true,'ErrorPrefix','objectrelativeprofiles');
sharedutilities.structsAndTables.validateTableKeys(base,primary,v);
sharedutilities.structsAndTables.validateTableKeys(additional,primary,v);
hadComponent=ismember('ComponentID',base.Properties.VariableNames);
if ~hadComponent, base.ComponentID=zeros(height(base),1); end
if ~ismember('ComponentID',additional.Properties.VariableNames), additional.ComponentID=zeros(height(additional),1); end
options.ErrorPrefix='objectrelativeprofiles';
options.ErrorNames=struct('MissingMatches','MissingResults','MissingType','MissingType');
combined=sharedutilities.structsAndTables.attachByKeys(base,additional, ...
    [primary,{'ComponentID'}],options);
if ~hadComponent&&all(combined.ComponentID==0), combined=removevars(combined,'ComponentID'); end
end
