function [objects,mask]=objects(c,frame,targetSize)
%OBJECTS Optional supplied mask/IDs or summed foreground probabilities.
if ~isempty(c.ObjectLoader)
    mask=c.ObjectLoader(frame);
    if ~isequal(size(mask),targetSize), error('memoworkflow:Dimensions','Supplied object grid must match intensity.'); end
else
    im=imagestackio.readH5(fullfile(c.ProbabilityDirectory,sprintf(c.ProbabilityPattern,frame)), ...
        c.H5Dataset,struct('SourceAxes',c.H5SourceAxes,'Spacing',c.ProbabilitySpacing,'SpacingUnit','um'));
    p=im.Data(:,:,:,:,1);
    extent=abs(double(size(p,1:3)).*c.ProbabilitySpacing-double(targetSize).*c.Spacing);
    if any(extent>2*c.ProbabilitySpacing), error('memoworkflow:Registration','Verify probability/image axes and shared crop.'); end
    mask=sum(p(:,:,:,c.ForegroundChannels),4)>c.ForegroundThreshold;
    if c.ObjectSmoothSigma>0
        mask=segmentationtools.cleanup.returnSmoothBlobsBW(mask,0,0,c.ObjectSmoothSigma);
    end
    mask=imresize3(mask,targetSize,'nearest');
end
objects=objectgeometry.objects.prepareObjects(mask,struct('DatasetID',c.DatasetID, ...
    'Frame',frame,'Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit,'InputType',c.ObjectInputType));
end
