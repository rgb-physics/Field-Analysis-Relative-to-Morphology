function [objects,mask] = farmWorkflowObjects(c,frame,targetSize)

%FARMWORKFLOWOBJECTS Optional supplied mask/IDs or summed foreground probabilities.
if ~isempty(c.ObjectLoader)
    mask = c.ObjectLoader(frame);
    if ~isequal(size(mask),targetSize), error('memoworkflow:Dimensions','Supplied object grid must match intensity.'); end
else
    if isfield(c,'Experiment')
        im = farmLoadSource(c.Experiment,'Probabilities',frame);
        if ~strcmp(im.SpacingUnit,c.SpacingUnit), error('memoworkflow:Units','Probability and intensity spacing units must match.'); end
        probabilitySpacing = im.Spacing;
    else
        im = farmReadH5(fullfile(c.ProbabilityDirectory,sprintf(c.ProbabilityPattern,frame)), ...
            c.H5Dataset,struct('SourceAxes',c.H5SourceAxes,'Spacing',c.ProbabilitySpacing,'SpacingUnit','um'));
        probabilitySpacing = c.ProbabilitySpacing;
    end
    p = im.Data(:,:,:,:,1);
    extent = abs(double(size(p,1:3)).*probabilitySpacing-double(targetSize).*c.Spacing);
    if any(extent>2*probabilitySpacing), error('memoworkflow:Registration','Verify probability/image axes and shared crop.'); end
    mask = sum(p(:,:,:,c.ForegroundChannels),4)>c.ForegroundThreshold;
    if c.ObjectSmoothSigma>0
        mask = farmReturnSmoothBlobsBW(mask,0,0,c.ObjectSmoothSigma);
    end
    mask = imresize3(mask,targetSize,'nearest');
end
identity = farmMakeObjectOptions('DatasetID',c.DatasetID, ...
    'Frame',frame,'Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit,'InputType',c.ObjectInputType);
objects = farmPrepareObjects(mask,identity);
end
