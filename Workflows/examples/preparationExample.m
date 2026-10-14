function manifest=preparationExample(c)
%PREPARATIONEXAMPLE Raw reference correction; optional separate Ilastik export.
if nargin<1, c=experiment4Config; end
out=memoworkflow.newRun(c,'preparation');
crop=load(c.CropMetadata,'cropCorner','winSize');
corner=double(crop.cropCorner([2 1 3])); dims=double(crop.winSize([2 1 3]));
loader=@(frame)localRaw(c,frame,corner,dims);
model=fieldanalysis.preprocessing.fitIlluminationCorrection(c.ReferenceFrames,loader, ...
    struct('Spacing',c.Spacing,'FirstSigma',24,'SecondSigma',20));
memoworkflow.saveNew(fullfile(out,'correction-model.mat'),model);
raw=loader(c.PreparationFrame);
[corrected,correctionInfo]=fieldanalysis.preprocessing.applyIlluminationCorrection(raw,model,struct('BleachScale',c.BleachScale));
% Guard quantitative export against saturation instead of silently clipping.
if any(corrected(:)<0)||any(corrected(:)>65535), error('memoworkflow:Range','Corrected values exceed uint16; double model is retained. Choose an explicit export strategy.'); end
file=fullfile(out,sprintf('t%03i_corrected560.tif',c.PreparationFrame));
imagestackio.writeTiff(uint16(corrected),file,struct('Spacing',c.Spacing,'SpacingUnit','um'));
manifest=struct('Directory',out,'CorrectedFile',file,'CorrectionInfo',correctionInfo, ...
    'CropCornerYXZ',corner,'CropSizeYXZ',dims);
if c.ExportIlastik
    % Reload quantitative output, then explicitly convert its fixed range.
    image=imagestackio.readTiff(file); a=double(image.Data(:,:,:,1,1));
    range=c.IlastikRange;
    validateattributes(range,{'numeric'},{'numel',2,'finite','increasing'});
    exportSize=max(2,round(size(a).*c.Spacing./c.IlastikSpacing));
    reduced=imresize3(a,exportSize);
    preview=uint8(255*min(1,max(0,(reduced-range(1))/diff(range))));
    actualSpacing=c.Spacing.*size(a)./exportSize;
    manifest.IlastikFile=fullfile(out,'ilastik-input560.tif');
    imagestackio.writeTiff(preview,manifest.IlastikFile,struct('Spacing',actualSpacing,'SpacingUnit','um'));
    manifest.IlastikRange=range; manifest.IlastikSpacing=actualSpacing;
end
memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Preparation outputs: %s\n',out);
end
function data=localRaw(c,frame,corner,dims)
image=imagestackio.readTiff(fullfile(c.RawDirectory,sprintf(c.RawPattern,frame)),struct('SourceAxes','YXZ'));
a=image.Data(:,:,:,1,1); ending=corner+dims-1;
if any(ending>size(a)), error('memoworkflow:Crop','Crop metadata exceeds raw grid.'); end
data=a(corner(1):ending(1),corner(2):ending(2),corner(3):ending(3));
end
