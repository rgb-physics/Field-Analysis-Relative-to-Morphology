function manifest=workflow5Profiles(c,varargin)
%WORKFLOW5PROFILES Compatibility entry for setupWorkflow5's local workflow.
% Editable setup and implementation now live together in setupWorkflow5.m.
if nargin<1, c=experiment4Config; end
workflowInput=c; % script dispatch skips manual setup/preview
workflowExtra=varargin;
run(fullfile(fileparts(mfilename('fullpath')),'setupWorkflow5.m'));
manifest=result;
end
