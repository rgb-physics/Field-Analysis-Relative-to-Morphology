function [currTiff] = extend2DTiffAlongZ(tiffData,repNum,saveDir)
%EXTEND2DTIFFALONGZ Takes in a 2D tif TIFFDATA and a scalar REPNUM and
%returns + saves a 3D tiff of the 2D repeated REPNUM times along z in
%SAVEDIR

if nargin == 2
    saveBool = 0;
else
    saveBool = 1;
end

currTiff = repmat(tiffData,[1 1 repNum]);

%Save tiff
if saveBool == 1
    save3DTiff(currTiff, saveDir);
end

end

