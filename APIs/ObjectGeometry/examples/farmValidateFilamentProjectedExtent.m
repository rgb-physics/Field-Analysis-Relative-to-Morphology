function report = farmValidateFilamentProjectedExtent

%FARMVALIDATEFILAMENTPROJECTEDEXTENT Expected vs measured length over tilt/spacing.
% Run from MATLAB with this examples folder on the path.
% Returns all 42 cases; writes CSV/MAT/PNG under package tests/data/workflow-results.
% No experimental data is loaded. Native ExtentInVoxels is voxel-unit ellipsoid-axis
% length and is NOT expected to equal physical centerline length.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', false);

expectedLengthUm = 7; % USER INPUT: ideal filament center-to-center length in um

here = fileparts(mfilename('fullpath')); repo = fileparts(fileparts(fileparts(here)));
for api = {'ObjectGeometry','ImageStackIO','SharedUtilities'}
    addpath(fullfile(repo,'APIs',api{1},'src'));
end
addpath(fullfile(repo,'tests'));
small = farmTestFilamentExtentAngleSweep(.25,expectedLengthUm);
large = farmTestFilamentExtentAngleSweep(2,expectedLengthUm);
report = [small;large];
report.WithinDiscretizationTolerance = abs(report.ErrorUm)<=report.LengthToleranceUm & ...
    report.DirectorErrorDegrees<=report.DirectorToleranceDegrees & report.ComponentCount==1;
fprintf('Expected length: %g um between ideal centerline endpoints.\n',expectedLengthUm);
fprintf('Elevation is measured from XY: 0 degrees in-plane, 90 along Z.\n');
fprintf('Full report repeats each elevation at XY azimuths 0, 45 and 90 degrees.\n');
disp(report(report.AzimuthDegrees==0,{'ZSpacingUm','ElevationDegrees', ...
    'ExpectedLengthUm','RoundedEndpointSpanUm','ProjectedExtentUm','ErrorPercent', ...
    'ExtentInVoxels','DirectorErrorDegrees'}));
base = fullfile(repo,'tests', 'data','workflow-results');
if ~isfolder(base), mkdir(base); end
[~,tag] = fileparts(tempname(base)); out = fullfile(base,['filament-extent_' tag]); mkdir(out);
writetable(report,fullfile(out,'expected-versus-reported.csv'));
save(fullfile(out,'report.mat'),'report');
% f=figure('Visible','off');
f = gcf; % initialize the current figure handle if hidden-figure creation is disabled
cleanup = onCleanup(@()close(f));
subplot(1,2,1); hold on;
for z = [.25 2]
    rows = report(report.ZSpacingUm==z & report.AzimuthDegrees==0,:);
    plot(rows.ElevationDegrees,rows.ProjectedExtentUm,'o-','DisplayName',sprintf('Z spacing %.2g um',z));
end
yline(expectedLengthUm,'k--','DisplayName',sprintf('Expected %g um',expectedLengthUm));
xlabel('Elevation from XY (degrees)'); ylabel('Projected extent (um)'); legend('Location','best'); grid on;
subplot(1,2,2); hold on;
for z = [.25 2]
    rows = report(report.ZSpacingUm==z & report.AzimuthDegrees==0,:);
    plot(rows.ElevationDegrees,rows.ExtentInVoxels,'o-','DisplayName',sprintf('Z spacing %.2g um',z));
end
xlabel('Elevation from XY (degrees)'); ylabel('Native ExtentInVoxels (voxels)'); legend('Location','best'); grid on;
print(f,fullfile(out,'length-versus-angle.png'),'-dpng','-r150');
fprintf('Report folder: %s\n',out);
fprintf('%d/%d cases within the stated discretization allowances.\n', ...
    nnz(report.WithinDiscretizationTolerance),height(report));
end
