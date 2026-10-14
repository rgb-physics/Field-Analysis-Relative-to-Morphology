function image=loadSource(experiment,name,frame)
%LOADSOURCE Load one named source for a frame; return normalized image metadata.
% Custom arrays use the source calibration. Custom image structs must declare
% Axes='YXZCT' and may carry their own current-grid Spacing/SpacingUnit.
% Channels/TimeIndex select stored positions, not acquisition Frame identity.
name=char(string(name));
validateattributes(frame,{'numeric'},{'scalar','integer','finite','nonnegative'});
if ~isfield(experiment.Sources,name), error('memoworkflow:MissingSource','Unknown source: %s',name); end
if ~ismember(frame,experiment.Frames), error('memoworkflow:Frame','Frame is not listed in the experiment.'); end
s=imagestackio.config.makeSource(experiment.Sources.(name));
options=struct('Spacing',s.Spacing,'SpacingUnit',s.SpacingUnit);
if ~isempty(s.SourceAxes), options.SourceAxes=s.SourceAxes; end
switch s.Format
    case 'tiff'
        image=imagestackio.readTiff(fullfile(s.Folder,sprintf(s.NamePattern,frame)),options);
    case 'hdf5'
        image=imagestackio.readH5(fullfile(s.Folder,sprintf(s.NamePattern,frame)),s.DatasetPath,options);
    case 'custom'
        image=s.Loader(frame);
        if isnumeric(image)||islogical(image)
            if ndims(image)>3, error('memoworkflow:CustomSource','Custom arrays must be a single YXZ field.'); end
            image=struct('Data',image,'Axes','YXZCT','Spacing',s.Spacing,'SpacingUnit',s.SpacingUnit);
        elseif ~isstruct(image)||~isscalar(image)||~isfield(image,'Data')||~isfield(image,'Axes')||~strcmp(image.Axes,'YXZCT')
            error('memoworkflow:CustomSource','Return a YXZ array or image struct with Data and Axes=YXZCT.');
        end
        if ~isfield(image,'Spacing'), image.Spacing=s.Spacing; end
        if ~isfield(image,'SpacingUnit'), image.SpacingUnit=s.SpacingUnit; end
end
validateattributes(image.Spacing,{'numeric'},{'vector','numel',3,'real','positive','finite'});
image.Spacing=double(image.Spacing(:).');
unit=string(image.SpacingUnit);
if ~isscalar(unit)||ismissing(unit)||strlength(unit)==0, error('memoworkflow:Calibration','SpacingUnit must be nonempty scalar text.'); end
image.SpacingUnit=char(unit);
if s.TimeIndex>size(image.Data,5), error('memoworkflow:TimeIndex','TimeIndex exceeds stored time dimension.'); end
channels=s.Channels; if isempty(channels), channels=1:size(image.Data,4); end
if any(channels>size(image.Data,4)), error('memoworkflow:Channels','Channels exceed stored channel dimension.'); end
image.Data=image.Data(:,:,:,channels,s.TimeIndex);
image.DatasetID=experiment.DatasetID; image.Frame=frame; image.SourceName=name;
image.SelectedChannels=channels; image.SelectedTimeIndex=s.TimeIndex;
end
