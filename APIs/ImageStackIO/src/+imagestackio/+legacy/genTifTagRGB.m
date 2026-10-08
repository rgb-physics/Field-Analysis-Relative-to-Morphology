function [tagstruct] = genTifTagRGB(inMat)
%GENTIFTAGRGB Generate the tag structure required to generate an RGB tif

tagstruct.ImageLength = size(inMat,1); 
tagstruct.ImageWidth = size(inMat,2);
tagstruct.Photometric = Tiff.Photometric.RGB;
tagstruct.BitsPerSample = 8;
tagstruct.SamplesPerPixel = 3;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; 
tagstruct.Software = 'MATLAB'; 

end

