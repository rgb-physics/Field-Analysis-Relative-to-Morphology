function out=newRun(c,name)
%NEWRUN All outputs go to a new directory under package test-data.
if isfield(c,'RepositoryRoot')
    repo=char(string(c.RepositoryRoot));
    if ~isfolder(fullfile(repo,'APIs','ImageStackIO','src')) ...
            ||~isfile(fullfile(repo,'Workflows','examples','workflow1Objects.m'))
        error('memoworkflow:RepositoryPath','RepositoryRoot is not a MeMo package root: %s',repo);
    end
else
    here=fileparts(mfilename('fullpath')); repo=fileparts(fileparts(fileparts(here)));
end
allowed=char(java.io.File(fullfile(repo,'test-data')).getCanonicalPath());
destination=char(java.io.File(c.OutputRoot).getCanonicalPath());
if ~startsWith([destination filesep],[allowed filesep],'IgnoreCase',true)
    error('memoworkflow:OutputLocation', ...
        'Outputs must be under package test-data.\nRequested: %s\nAllowed root: %s',destination,allowed);
end
if ~isfolder(destination), mkdir(destination); end
out=tempname(destination); [~,tag]=fileparts(out); out=fullfile(destination,[name '_' tag]);
if isfolder(out), error('memoworkflow:Exists','Output already exists.'); end
mkdir(out); memoworkflow.saveNew(fullfile(out,'configuration.mat'),c);
end
