function [labels,info]=regions(c,frame,targetSize)
%REGIONS Explicit channel semantics and shared-FOV resampling.
im=imagestackio.readH5(fullfile(c.ProbabilityDirectory,sprintf(c.ProbabilityPattern,frame)), ...
    c.H5Dataset,struct('SourceAxes',c.H5SourceAxes,'Spacing',c.ProbabilitySpacing,'SpacingUnit','um'));
p=im.Data(:,:,:,:,1);
physicalError=abs(double(size(p,1:3)).*c.ProbabilitySpacing-double(targetSize).*c.Spacing);
if any(physicalError>2*c.ProbabilitySpacing)
    error('memoworkflow:Registration','H5/image extents disagree. Check SourceAxes, crop and spacing before resampling.');
end
[masks,info]=segmentationtools.binarization.smoothNChannelProbabilities(p,c.SemanticChannels, ...
    c.Thresholds,struct('OpeningRadius',c.OpeningRadius));
labels=zeros(size(p,1),size(p,2),size(p,3),'uint8');
for k=1:3, current=masks(:,:,:,k); labels(current)=k; end
labels=imresize3(labels,targetSize,'nearest');
info.SourceAxes=c.H5SourceAxes; info.SourceGridSize=size(p,1:3);
info.PhysicalExtentError=physicalError; info.SemanticOrder={'inside','wall','outside'};
end
