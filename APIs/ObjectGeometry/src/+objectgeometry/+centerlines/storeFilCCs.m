function [rp3D,rp2D] = storeFilCCs(bwObjs)
%STOREFILCCS Take in a binarized image, return a structure with selected
%fields stored in tables
% 2025-04-17 - Rémi Boros

selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation'};
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};

 % Get regionprops for 3D, store in .mat file
rp3D = regionprops3(bwObjs, selFields3D);
% Make filament properties calculated from regionprops
catEVecs = [rp3D.EigenVectors{:}];
   
% EVecs are returned in (row,col,page) form; swap x,y
% Isolate every third column. Each evec is a column. 1st col is dir.
catEVecs1 = catEVecs([2 1 3],1:3:end); 
filDirs = catEVecs1';                   % Convert to rows
% Store lengths and aspect ratios
filLens = [rp3D.PrincipalAxisLength(:,1)];
filOffLens = [rp3D.PrincipalAxisLength(:,2:3)];
filARs = filLens./filOffLens(:,1);
% Append properties
rp3D.('Directors') = filDirs;
rp3D.('Lengths') = filLens;
rp3D.('AspectRatios') = filARs;

% Get regionprops for 2D, store in .mat file
% Iterate through each Z slice, get 2D stats, store
newBool = 1;        % Used to define new storage struct in cases where no objects are observed in first z slice
for zInd = 1:size(bwObjs,3)
    curr2D = regionprops(bwObjs(:,:,zInd),selFields2D);
    IndVecCol = repmat(zInd, size(curr2D,1), 1);
    curr2D = addFieldStruct(curr2D,'Slice_Index',IndVecCol);
    if (newBool == 1) && ~isempty(curr2D)
        rp2D = curr2D;
        newBool = 0;
    elseif (newBool == 0) && ~isempty(curr2D)
        rp2D = vertcat(rp2D,curr2D);
    end
end

end

