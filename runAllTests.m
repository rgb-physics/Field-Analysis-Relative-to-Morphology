function report = runAllTests(varargin)

%RUNALLTESTS Run all available automated FARM checks, once per test file.
% From repository root: report=runAllTests;
% Options (struct or name/value): IncludeImageStackIO=true, ThrowOnFailure=false.
% ImageStackIO validation requires local bundled TIFF/HDF5 fixtures; false
% runs synthetic suites only. Missing fixtures are reported as errors, not passes.
% Does not run manual visual validation or benchmarks. Sources remain read-only.
% Results/summary saved in a fresh test-data/workflow-results/all-tests_* folder.
% Report fields: Summary, UnitResults, ImageStackIO, Passed, OutputDirectory.
% Failed/Incomplete counts may overlap under matlab.unittest conventions.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

root = fileparts(mfilename('fullpath'));
apis = {'ImageStackIO','SegmentationTools','ObjectGeometry','ObjectRelativeProfiles', ...
    'ObjectTracking','FieldAnalysis','SharedUtilities','VisualizationTools'};
for k = 1:numel(apis), addpath(fullfile(root,'APIs',apis{k},'src')); end
addpath(fullfile(root,'Workflows','src'));
addpath(fullfile(root,'Workflows','examples'));
addpath(fullfile(root,'tests'));
addpath(fullfile(root,'APIs','ImageStackIO','tests'));
options = farmParseOptions(struct('IncludeImageStackIO',true, ...
    'ThrowOnFailure',false),varargin{:});
validateattributes(options.IncludeImageStackIO,{'logical'},{'scalar'});
validateattributes(options.ThrowOnFailure,{'logical'},{'scalar'});

files = {
    'SegmentationTools','APIs/SegmentationTools/tests/testSegmentationTools.m'
    'ObjectGeometry','APIs/ObjectGeometry/tests/testObjectGeometry.m'
    'FieldSampling','APIs/ObjectRelativeProfiles/tests/testFieldSampling.m'
    'VectorFieldSampling','APIs/ObjectRelativeProfiles/tests/testVectorFieldSampling.m'
    'ObjectTracking','APIs/ObjectTracking/tests/testObjectTracking.m'
    'FieldAnalysis','APIs/FieldAnalysis/tests/testFieldAnalysis.m'
    'SharedUtilities','APIs/SharedUtilities/tests/testSharedUtilities.m'
    'CanonicalUtilities','APIs/SharedUtilities/tests/testCanonicalUtilities.m'
    'FARMLayout','APIs/SharedUtilities/tests/testFarmLayout.m'
    'WorkflowExamples','Workflows/examples/testWorkflowExamples.m'
    'ConfigBuilders','Workflows/examples/testConfigBuilders.m'
    };
% Invoke TestSuite directly: individual runners throw after failures and the
% SharedUtilities runner includes regression files already listed above.
n = size(files,1);
names = strings(n,1); passed = zeros(n,1); failed = zeros(n,1);
incomplete = zeros(n,1); seconds = zeros(n,1); errors = strings(n,1);
unitCells = cell(n,1);
runner = matlab.unittest.TestRunner.withTextOutput;
for k = 1:n
    names(k) = files{k,1}; started = tic;
    fprintf('\n===== %s =====\n',names(k));
    try
        suite = matlab.unittest.TestSuite.fromFile(fullfile(root,files{k,2}));
        if isempty(suite), error('memo:EmptySuite','No tests discovered in %s',files{k,2}); end
        unitCells{k} = runner.run(suite);
        passed(k) = nnz([unitCells{k}.Passed]);
        failed(k) = nnz([unitCells{k}.Failed]);
        incomplete(k) = nnz([unitCells{k}.Incomplete]);
    catch exception
        errors(k) = string(getReport(exception,'extended','hyperlinks','off'));
        fprintf(2,'%s\n',errors(k));
    end
    seconds(k) = toc(started);
end
summary = table(names,passed,failed,incomplete,seconds,errors, ...
    'VariableNames',{'Suite','Passed','Failed','Incomplete','Seconds','Error'});
imageResults = table();
if options.IncludeImageStackIO
    fprintf('\n===== ImageStackIO validation =====\n'); started = tic;
    errorText = ""; imagePassed = 0; imageFailed = 0;
    try
        imageResults = runImageStackIOValidation(false);
        imagePassed = nnz(imageResults.Passed);
        imageFailed = nnz(~imageResults.Passed);
    catch exception
        errorText = string(getReport(exception,'extended','hyperlinks','off'));
        fprintf(2,'%s\n',errorText);
    end
    imageSummary = table("ImageStackIO",imagePassed,imageFailed,0,toc(started),errorText, ...
        'VariableNames',summary.Properties.VariableNames);
    summary = [summary;imageSummary];
end
% Avoid constructing TestResult from [] (MATLAB class concatenation pitfalls).
unitResults = [];
for k = 1:n
    if isempty(unitCells{k}), continue; end
    if isempty(unitResults), unitResults = unitCells{k};
    else, unitResults = [unitResults,unitCells{k}]; end %#ok<AGROW>
end
allPassed = all(summary.Failed==0 & summary.Incomplete==0 & strlength(summary.Error)==0);
outputRoot = fullfile(root,'test-data','workflow-results');
if ~isfolder(outputRoot), mkdir(outputRoot); end
[~,suffix] = fileparts(tempname(outputRoot));
outputDirectory = fullfile(outputRoot,['all-tests_' suffix]); mkdir(outputDirectory);
report = struct('Summary',summary,'UnitResults',unitResults, ...
    'ImageStackIO',imageResults,'Passed',allPassed,'OutputDirectory',outputDirectory);
save(fullfile(outputDirectory,'report.mat'),'report');
writetable(summary,fullfile(outputDirectory,'summary.csv'));
if ~isempty(imageResults), writetable(imageResults,fullfile(outputDirectory,'imagestackio.csv')); end
fprintf('\n===== MeMo combined test summary =====\n');
disp(summary(:,{'Suite','Passed','Failed','Incomplete','Seconds'}));
fprintf('%d passed, %d failed, %d incomplete; %d suite execution errors.\n', ...
    sum(summary.Passed),sum(summary.Failed),sum(summary.Incomplete),nnz(strlength(summary.Error)>0));
fprintf('Reports: %s\n',outputDirectory);
if ~options.IncludeImageStackIO, fprintf('ImageStackIO fixture validation excluded by request.\n'); end
fprintf('SurfaceFieldMapping and full VisualizationTools suites do not yet exist.\n');
fprintf('Manual visual validations and scalability benchmarks are not included.\n');
if ~allPassed && options.ThrowOnFailure
    error('memo:TestsFailed','Checks failed or could not run. Reports saved to %s',outputDirectory);
end
end

