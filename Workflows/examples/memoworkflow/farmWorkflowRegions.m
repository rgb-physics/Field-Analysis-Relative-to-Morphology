function [labels,info] = farmWorkflowRegions(c,frame,targetSize)

%FARMWORKFLOWREGIONS Explicit channel semantics and shared-FOV resampling.
if isfield(c,'Experiment')
    im = farmLoadSource(c.Experiment,'Probabilities',frame);
    probabilitySpacing = im.Spacing;
    if ~strcmp(im.SpacingUnit,c.SpacingUnit), error('memoworkflow:Units','Probability/intensity units must match.'); end
else
    im = farmReadH5(fullfile(c.ProbabilityDirectory,sprintf(c.ProbabilityPattern,frame)), ...
        c.H5Dataset,struct('SourceAxes',c.H5SourceAxes,'Spacing',c.ProbabilitySpacing,'SpacingUnit',c.SpacingUnit));
    probabilitySpacing = c.ProbabilitySpacing;
end
p = im.Data(:,:,:,:,1);
physicalError = abs(double(size(p,1:3)).*probabilitySpacing-double(targetSize).*c.Spacing);
if any(physicalError>2*probabilitySpacing)
    error('memoworkflow:Registration','H5/image extents disagree. Check SourceAxes, crop and spacing before resampling.');
end
[masks,info] = farmSmoothNChannelProbabilities(p,c.SemanticChannels, ...
    c.Thresholds,struct('OpeningRadius',c.OpeningRadius));
labels = zeros(size(p,1),size(p,2),size(p,3),'uint8');
for k = 1:3, current = masks(:,:,:,k); labels(current) = k; end
labels = imresize3(labels,targetSize,'nearest');
if isfield(im,'SourceAxes'), info.SourceAxes = im.SourceAxes;
else, info.SourceAxes = im.Axes; end
info.SourceGridSize = size(p,1:3);
info.PhysicalExtentError = physicalError; info.SemanticOrder = {'inside','wall','outside'};
end
