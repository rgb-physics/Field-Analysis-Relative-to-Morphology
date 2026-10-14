function data=intensity(c,frame,channel)
%INTENSITY Read one quantitative XYZ, preserving its native numerical values.
image=imagestackio.readTiff(fullfile(c.IntensityDirectory,sprintf(c.IntensityPattern,frame,channel)), ...
    struct('SourceAxes','YXZ','Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit));
if size(image.Data,4)~=1||size(image.Data,5)~=1, error('memoworkflow:Dimensions','Expected one XYZ per file.'); end
data=image.Data(:,:,:,1,1);
end
