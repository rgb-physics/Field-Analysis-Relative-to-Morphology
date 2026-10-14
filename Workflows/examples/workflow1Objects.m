function manifest=workflow1Objects(c)
%WORKFLOW1OBJECTS Compatibility entry for setupWorkflow1's local workflow.
% Editable setup and implementation now live together in setupWorkflow1.m.
if nargin<1, c=experiment4Config; end
workflowInput=c; % script dispatch skips manual setup/preview
run(fullfile(fileparts(mfilename('fullpath')),'setupWorkflow1.m'));
manifest=result;
end
