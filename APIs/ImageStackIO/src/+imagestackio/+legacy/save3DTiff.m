function [] = save3DTiff(tiffIn,savePath)
%SAVE3DTIFF Saves a 3D tiff TIFFIN at the designated path SAVEPATH

% Write first 2D tif
imwrite(tiffIn(:,:,1),savePath);
% Append 2D stacks along third dimension
for currSlice = 2:size(tiffIn,3)        
    imwrite(tiffIn(:,:,currSlice),savePath,'WriteMode','append');
end

end

