function [] = saveNDTiffFIJI(inMat,savePath,dimOrder)
%SAVENDTIFFFIJI Saves a matrix tiffIn as a 3D tiff and adds a FIJI-specific
%tag called "ImageDescription" that allows FIJI to parse the tiff as a
%hyperstack. The dimensions of the hyperstack are passed to the function.
%Dimension order is "channels" "slices" "frames" and the value "images"
%must be the product of the aforementioned three properties. For lower
%dimensional tiffs, set the appropriate dimension sizes to 1.
% The dimensions of TiffIn are expected to correspond to [y,x,c,z,t]
% dimOrder is a variable that instructs how to permute [y,x,c,z,t];
% important for permuting channel to z or t data, ie [1 2 4 3 5] or 
% [1 2 5 4 3], respectively
%
% *The FIJI version used can be accessed from the "ImageDescription" of a
% separate tif saved in FIJI: getTag(Tiff(<saved.tif>),'ImageDescription')

% 2026-01-21; 2026-05-26
% Rémi Boros

if nargin == 2
    dimOrder = 1:5;
end

% Store tif dimensions
matDims = size(inMat,1:5);     % [y x c z t]
matDims = matDims(dimOrder);

% Set the FIJI Descriptor
fiji_descr = ['ImageJ=1.54c' newline ...       % *See above 
            'images='   num2str(prod(matDims(3:5))) newline... 
            'channels=' num2str(matDims(3)) newline...
            'slices='   num2str(matDims(4)) newline...
            'frames='   num2str(matDims(5)) newline... 
            'hyperstack=true' newline...
            'mode=composite' newline...  
            'loop=false' newline...  
            sprintf('min=%0.5f',min(matDims(:))) newline...      
            sprintf('max=%0.5f',min(matDims(:)))];

% Reshape the input matrix
inMatRS = reshape(inMat,[matDims(1:2) prod(matDims(3:5))]);
inMatRS = cast(inMatRS,class(inMat));

% Generate MATLAB Tiff tagstruct, append 'ImageDescription' field
t = Tiff(savePath,'w');
tagstruct.ImageLength = matDims(1);
tagstruct.ImageWidth =  matDims(2);
tagstruct.Photometric = Tiff.Photometric.LinearRaw;
tagstruct.BitsPerSample = 16;
tagstruct.SamplesPerPixel = 1;
tagstruct.Compression = Tiff.Compression.LZW;       %Test against 'None'
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
tagstruct.ImageDescription = fiji_descr;

% Append 2D stacks along third dimension
for currSlice = 1:size(inMatRS,3)        
    t.setTag(tagstruct)
    t.write(inMatRS(:,:,currSlice),savePath);
    t.writeDirectory(); % saves a new page in the tiff file
end

% Append tagstruct info
t.close()

end

