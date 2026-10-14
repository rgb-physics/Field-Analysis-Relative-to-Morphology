function classes=makeClassConfig(channels,thresholds,options)
%MAKECLASSCONFIG Compatibility alias for segmentationtools.config.makeClasses.
if nargin<3||isempty(options), options=struct(); end
classes=segmentationtools.config.makeClasses(channels,thresholds,options);
end
