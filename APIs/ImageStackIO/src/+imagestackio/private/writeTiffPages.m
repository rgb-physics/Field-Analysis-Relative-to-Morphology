function writeTiffPages(pageData, filePath, imageDescription, compression, calibration)
%WRITETIFFPAGES Write grayscale pages with a shared TIFF tag structure.

if nargin < 5
    calibration = struct();
end

if isa(pageData, 'uint8')
    bitsPerSample = 8;
elseif isa(pageData, 'uint16')
    bitsPerSample = 16;
else
    error('imagestackio:UnsupportedPixelType', ...
        'TIFF page data must be uint8 or uint16.');
end

switch lower(compression)
    case 'lzw'
        compressionTag = Tiff.Compression.LZW;
    case 'deflate'
        compressionTag = Tiff.Compression.Deflate;
    case 'none'
        compressionTag = Tiff.Compression.None;
end

tiffFile = Tiff(filePath, 'w');
try
    for pageIndex = 1:size(pageData, 3)
        tags = struct();
        tags.ImageLength = size(pageData, 1);
        tags.ImageWidth = size(pageData, 2);
        tags.Photometric = Tiff.Photometric.MinIsBlack;
        tags.BitsPerSample = bitsPerSample;
        tags.SamplesPerPixel = 1;
        tags.RowsPerStrip = size(pageData, 1);
        tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tags.Compression = compressionTag;
        tags.SampleFormat = Tiff.SampleFormat.UInt;
        if isfield(calibration, 'XResolution')
            tags.XResolution = calibration.XResolution;
        end
        if isfield(calibration, 'YResolution')
            tags.YResolution = calibration.YResolution;
        end
        if isfield(calibration, 'XResolution') || ...
                isfield(calibration, 'YResolution')
            tags.ResolutionUnit = Tiff.ResolutionUnit.None;
        end
        if pageIndex == 1 && ~isempty(imageDescription)
            tags.ImageDescription = imageDescription;
        end
        tiffFile.setTag(tags);
        tiffFile.write(pageData(:, :, pageIndex));
        if pageIndex < size(pageData, 3)
            tiffFile.writeDirectory();
        end
    end
    tiffFile.close();
catch exception
    try
        tiffFile.close();
    catch
    end
    rethrow(exception);
end
end
