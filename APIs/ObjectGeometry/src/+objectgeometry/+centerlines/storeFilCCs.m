function [rp3D,rp2D] = storeFilCCs(bwObjs)
%STOREFILCCS Historical 3-D filament table and per-slice 2-D structures.
% Empty masks return typed empty outputs; no SharedUtilities path needed.
req={'Centroid','Volume','PrincipalAxisLength','EigenVectors','Directors','Lengths','AspectRatios'};
rp3D=objectgeometry.centerlines.measureFilaments(bwObjs,req);
rp3D=removevars(rp3D,{'DatasetID','Frame','ObjectID'});
fields={'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation'};
rp2D=struct('Centroid',{},'Area',{},'MinorAxisLength',{},'MajorAxisLength',{},'Orientation',{},'Slice_Index',{});
for z=1:size(bwObjs,3)
    current=regionprops(logical(bwObjs(:,:,z)),fields);
    for i=1:numel(current), current(i).Slice_Index=z; end
    if ~isempty(current), rp2D=[rp2D;current(:)]; end %#ok<AGROW>
end
end
