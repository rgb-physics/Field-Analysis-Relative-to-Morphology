function [properties, objects] = measureObjects(input, requested, options)
%MEASUREOBJECTS User-selected native regionprops/regionprops3 properties.
% [TABLE,OBJECTS]=measureObjects(INPUT,PROPERTIES,OPTIONS). PROPERTIES is a
% cell/string array of native property names, or 'all'. Identity options go
% to prepareObjects; OPTIONS.Intensity=[] supplies matching grayscale data
% for native 2-D intensity properties. MATLAB determines property availability
% for the installed release. No custom properties computed silently.
% Table keys are DatasetID/Frame/ObjectID. Native geometric values are in
% pixel/voxel units. Centroid/BoundingBox/VoxelList use MATLAB XYZ ordering;
% raw 3-D EigenVectors retain MATLAB ordering (see measureFilaments).
% Optional large native properties are included only when requested.
if nargin<2||isempty(requested), requested={'Centroid'}; end
if nargin<3, options=struct(); end
intensity=[];
if isfield(options,'Intensity'), intensity=options.Intensity; options=rmfield(options,'Intensity'); end
objects=objectgeometry.objects.prepareObjects(input,options);
cc=objects.Components;
if ~isempty(intensity)&&~isequal(size(intensity),cc.ImageSize)
    error('objectgeometry:GridMismatch','Intensity dimensions must match the current object grid.');
end
names=cellstr(string(requested)); names=names(:).';
if numel(cc.ImageSize)==3
    if ~isempty(intensity), error('objectgeometry:NativeIntensity3D','regionprops3 does not accept intensity input. Use the separate field-query API.'); end
    native=regionprops3(cc,names);
else
    if isempty(intensity), native=regionprops('table',cc,names);
    else, native=regionprops('table',cc,intensity,names); end
end
if height(native)~=numel(objects.ObjectIDs)
    error('objectgeometry:PropertyRowMismatch','Native measurements did not preserve component count.');
end
keys=table(repmat(objects.DatasetID,height(native),1), ...
    repmat(objects.Frame,height(native),1),objects.ObjectIDs, ...
    'VariableNames',{'DatasetID','Frame','ObjectID'});
properties=[keys native];
properties.Properties.UserData=struct('Grid',objects.Grid,'SourceGrid',objects.SourceGrid, ...
    'Transform',objects.Transform,'Units','voxel','InputType',objects.InputType, ...
    'DatasetID',objects.DatasetID,'Frame',objects.Frame);
objectgeometry.internal.validateKeys(properties);
end
