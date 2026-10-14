function manifest=workflow2Filaments(c)
%WORKFLOW2FILAMENTS Compatibility entry for setupWorkflow2's local workflow.
% Editable setup and implementation now live together in setupWorkflow2.m.
if nargin<1, c=experiment4Config; end
workflowInput=c; % script dispatch skips manual setup/preview
run(fullfile(fileparts(mfilename('fullpath')),'setupWorkflow2.m'));
manifest=result;
end
