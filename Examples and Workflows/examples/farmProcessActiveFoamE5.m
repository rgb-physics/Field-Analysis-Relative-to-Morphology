function workflow2 = farmProcessActiveFoamE5(c)
%FARMPROCESSACTIVEFOAME5 Run workflow 2 on confirmed E5 frames, logging progress.
% Inputs:
%   c           Configuration from farmActiveFoamE5Config.
% Outputs:
%   workflow2   Workflow 2 Filaments table, output Directory and provenance.
% All O:\Session 88 inputs are read only. Each frame/result uses new local files.

out = farmWorkflowNewRun(c, 'active-foam-E5');
logFile = fullfile(out, 'processing.log');
diary(logFile);
diaryCleanup = onCleanup(@() diary('off'));
fprintf('Active Foam E5 output directory: %s\n', out);
fprintf('Read-only source root: %s\n', c.ReadOnlySourceRoot);
fprintf('Frames: %s; YXZ image spacing %s um; probability spacing [1.5 1.5 1.5] um.\n', ...
    mat2str(c.Frames), mat2str(c.Spacing));
fprintf('Elapsed seconds = (Frame - %g) * %g.\n', c.TimeReferenceFrame, c.TimeStep);

% Verify the complete requested input list before starting any image processing.
rows = cell(numel(c.Frames) * 2, 3);
for index = 1:numel(c.Frames)
    frame = c.Frames(index);
    for sourceIndex = 1:2
        names = {'Intensity647', 'Probabilities'};
        source = c.Experiment.Sources.(names{sourceIndex});
        path = fullfile(source.Folder, sprintf(source.NamePattern, frame));
        if ~isfile(path)
            error('memoworkflow:MissingInput', 'Input not found: %s', path);
        end
        rows{2 * (index - 1) + sourceIndex, 1} = frame;
        rows{2 * (index - 1) + sourceIndex, 2} = names{sourceIndex};
        rows{2 * (index - 1) + sourceIndex, 3} = path;
    end
end
inputFiles = cell2table(rows, 'VariableNames', {'Frame', 'Source', 'Path'});
writetable(inputFiles, fullfile(out, 'input-files.csv'));

tables = cell(numel(c.Frames), 1);
directories = strings(numel(c.Frames), 1);
for index = 1:numel(c.Frames)
    frame = c.Frames(index);
    fprintf('\n%s: starting frame %g (%d/%d).\n', char(datetime('now')), frame, index, numel(c.Frames));
    started = tic;
    current = c;
    current.Frames = frame;
    current.OutputRoot = out;

    % EXPLICIT WORKFLOW 2 EXECUTION: its measured rod table is retained below.
    frameResult = farmWorkflow2Filaments(current);
    tables{index} = frameResult.Filaments;
    directories(index) = string(frameResult.Directory);
    fprintf('%s: frame %g complete, %d detections, %d selected, %.1f seconds.\n', ...
        char(datetime('now')), frame, height(tables{index}), nnz(tables{index}.Selected), toc(started));
    partial = struct('Directory', out, 'Filaments', farmConcatenateMeasurements(tables(1:index)), ...
        'CompletedFrames', c.Frames(1:index), 'FrameDirectories', directories(1:index));
    farmWorkflowSaveNew(fullfile(out, sprintf('completed-through-frame%03i.mat', frame)), partial);
end

workflow2 = struct('Directory', out, 'Filaments', farmConcatenateMeasurements(tables), ...
    'Frames', c.Frames, 'FrameDirectories', directories, 'InputFiles', inputFiles, ...
    'SpacingYXZ', c.Spacing, 'ProbabilitySpacingYXZ', c.Experiment.Sources.Probabilities.Spacing, ...
    'SpacingUnit', c.SpacingUnit, 'TimeStepSeconds', c.TimeStep, ...
    'TimeReferenceFrame', c.TimeReferenceFrame);
farmWorkflowSaveNew(fullfile(out, 'workflow2-output.mat'), workflow2);
writetable(workflow2.Filaments, fullfile(out, 'workflow2-filaments.csv'));
fprintf('All requested E5 frames complete. Workflow 2 output: %s\n', out);
end
