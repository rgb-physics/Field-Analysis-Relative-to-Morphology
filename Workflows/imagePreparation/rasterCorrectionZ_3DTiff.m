function [scaledImg] = rasterCorrectionZ_3DTiff(inImg, polyDeg, saveBool,savePath)
%RASTERCORRECTIONZ_3DTIFF This function takes in a 3D image INIMG with
%dimensions [x y z]. It calculates the average intensity for each z value,
%then corrects by subtracting a polynomial of degree POLYDEG fit to 
%current z vs average intensity to find rastering intensity. Finally, the
%tif is scaled by this adjusted value to remove rastering. SAVEBOOL is a
%boolean between 0 and 1 determining whether or not to save the generated
%matrix as a tif in SAVEPATH (directory + save name with file ending)

if nargin < 3
    saveBool = 0;
end

%Calculate mean and median vals for each z
medianVals = double(squeeze(median(inImg,[1 2])));

%Correct rastering
%Polynomial fit to shift rastering
zVals = 1:numel(medianVals);
pMedian = polyfit(zVals, medianVals, polyDeg);
medianPlot = polyval(pMedian,zVals);
%Convert rastering to scaling values around 1
isolatedRast = (medianVals' - medianPlot) + mean(medianVals);
rescaledRast = isolatedRast/mean(medianVals);
%Apply to current image
rastMat = permute(repmat(rescaledRast, [size(inImg,2) 1 size(inImg,1)]),[3 1 2]);
scaledImg = uint16(double(inImg)./rastMat);

%Save tif
if saveBool == 1
    save3DTiff(scaledImg, savePath);
end

end

