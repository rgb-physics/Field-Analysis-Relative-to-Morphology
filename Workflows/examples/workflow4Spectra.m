function manifest=workflow4Spectra(c)
%WORKFLOW4SPECTRA Compatibility entry for setupWorkflow4's local workflow.
% Editable setup and implementation now live together in setupWorkflow4.m.
if nargin<1, c=experiment4Config; end
workflowInput=c; % script dispatch skips manual setup/preview
run(fullfile(fileparts(mfilename('fullpath')),'setupWorkflow4.m'));
manifest=result;
end
