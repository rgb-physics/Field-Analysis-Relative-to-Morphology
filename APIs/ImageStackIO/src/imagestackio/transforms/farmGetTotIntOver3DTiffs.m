function [allInts] = farmGetTotIntOver3DTiffs(dataDir,dataNameForm,selectN)
%FARMGETTOTINTOVER3DTIFFS Takes in a directory and string in sprintf form to
%access tifs defined for some selected values of N. selectN will be taken
%as an argument to sprintf to modify the file being accessed. Returns a
%vector of intensities stored in selected tifs

allInts = zeros(size(selectN));

for nInd = 1:numel(selectN)

    currN = selectN(nInd);
    currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,currN)));
    allInts(nInd) = sum(double(currTif(:)));

end



end

