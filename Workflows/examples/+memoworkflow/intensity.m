function data=intensity(c,frame,channel)
%INTENSITY Read one quantitative XYZ, preserving its native numerical values.
if isfield(c,'Experiment')
    sourceName=['Intensity' char(string(channel))];
    image=memoworkflow.loadSource(c.Experiment,sourceName,frame);
    if ~isequal(image.Spacing(:),c.Spacing(:))||~strcmp(image.SpacingUnit,c.SpacingUnit)
        error('memoworkflow:Calibration','Intensity source %s must use the configured analysis grid calibration.',sourceName);
    end
else
    image=imagestackio.readTiff(fullfile(c.IntensityDirectory,sprintf(c.IntensityPattern,frame,channel)), ...
        struct('SourceAxes','YXZ','Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit));
end
if size(image.Data,4)~=1||size(image.Data,5)~=1, error('memoworkflow:Dimensions','Expected one XYZ per file.'); end
data=image.Data(:,:,:,1,1);
end
