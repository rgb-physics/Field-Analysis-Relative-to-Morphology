function manifest=workflow3Lineage(c)
%WORKFLOW3LINEAGE Compatibility entry for setupWorkflow3's local workflow.
% Editable setup and implementation now live together in setupWorkflow3.m.
if nargin<1, c=experiment4Config; end
workflowInput=c; % script dispatch skips manual setup/preview
run(fullfile(fileparts(mfilename('fullpath')),'setupWorkflow3.m'));
manifest=result;
end
