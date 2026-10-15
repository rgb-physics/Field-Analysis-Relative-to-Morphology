function tests = testCanonicalUtilities

%TESTCANONICALUTILITIES Canonical utilities preserve numerical and graphics behavior.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

tests = functiontests(localfunctions);
end
function testNumericUtilities(t)
verifyEqual(t, farmLogAB(2, [4 8]), [2 3]);
[x, y] = farmLoglogBin([1 2 4 8], [2 4 8 16], 10);
verifyEqual(t, y, x + log(2), 'AbsTol', 1e-12);
end
function testViolinGraphicsAndStatistics(t)
before = findall(groot, 'Type', 'figure');
cleanup = onCleanup(@() localCloseNew(before));
figure('Visible', 'off');
[m, d] = farmManVlnPlot(1, [1 2 3], 0:4, .4);
patches = findobj(gca, 'Type', 'patch');
verifyEqual(t, [m d], [2 2]);
verifyEqual(t, numel(patches), 1);
verifyTrue(t, all(isfinite(patches.XData(:))));
verifyTrue(t, all(isfinite(patches.YData(:))));
clear cleanup
end
function testGroupedViolin(t)
before = findall(groot, 'Type', 'figure');
visibility = get(groot, 'DefaultFigureVisible');
cleanup = onCleanup(@() localRestore(before, visibility));
set(groot, 'DefaultFigureVisible', 'off');
[m, d] = farmPlotVlns([1 1 3 3], [1 2 2 3], [0 2 4], 0:4, .4);
verifyEqual(t, m(:), [1.5; 2.5]);
verifyEqual(t, d(:), [1.5; 2.5]);
verifyEqual(t, numel(findobj(gcf, 'Type', 'patch')), 2);
clear cleanup
end
function testFigureExport(t)
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder, 's'));
f = figure('Visible', 'off'); figureCleanup = onCleanup(@() close(f));
plot(1:3, [2 1 3]);
farmFigSaves(f, folder, 'export', {'png', 'fig'}, true);
verifyTrue(t, isfile(fullfile(folder, 'export.fig')));
verifyTrue(t, isfile(fullfile(folder, 'export.png')));
verifyNotEmpty(t, imread(fullfile(folder, 'export.png')));
farmFigSaves(f, folder, 'disabled', 'png', false);
verifyFalse(t, isfile(fullfile(folder, 'disabled.png')));
clear figureCleanup cleanup
end
function localCloseNew(before)
after = findall(groot,'Type','figure');
for k = 1:numel(after)
    if ~any(after(k)==before)&&isgraphics(after(k)), close(after(k)); end
end
end
function localRestore(before,visibility)
localCloseNew(before); set(groot,'DefaultFigureVisible',visibility);
end
