function fastWriteTiff(currTif,file_path,bit,compressionMethod)
%%method: 'Deflate': slower but save space; "None": fast and large space
oldWarnState = warning('off', 'all');
switch nargin
    case 2
        bit = 16;
        compressionMethod = 'Deflate';
    case 3
        compressionMethod = 'Deflate';
end


t = Tiff(file_path,'w');
tagstruct.ImageLength = size(currTif,1);
tagstruct.ImageWidth  = size(currTif,2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = bit;
tagstruct.SamplesPerPixel = 1;
tagstruct.RowsPerStrip = size(currTif,1);
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
if strcmp(compressionMethod,'Deflate')
    tagstruct.Compression = Tiff.Compression.Deflate;
else
    tagstruct.Compression = Tiff.Compression.None;
end
for k = 1:size(currTif,3)
    t.setTag(tagstruct);
    t.write(currTif(:,:,k));
    if k < size(currTif,3)
        t.writeDirectory();
    end
end
t.close();
warning(oldWarnState);
end