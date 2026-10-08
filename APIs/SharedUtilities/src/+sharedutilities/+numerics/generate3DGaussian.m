function gaussMat = generate3DGaussian(gsize, centers, sigmas, coordMode)
 %GENERATE2DGAUSSIAN Takes in matrix size GSIZE and gaussian parameters and
 %returns a 3D gaussian centered at XC, YC, ZC with width sigmax, sigmay, 
 %sigmaz for x, y, z, respectively. COORDMODE is an integer of 0,1,2 that
 %indiicates
 %  - 0: (0,0,0) is defined at the center of the matrix
 %  - 1: (0,0,0) is defined in the bottom left corner of the martix
 %  - 2: (0,0,0) is defined as in an image, with the direction of y flipped
    
%Do some cleanup
if numel(sigmas) < numel(centers)
    sigmas = repmat(sigmas(1), numel(centers), 1);
end

%Generate matrix boundaries and vectors
if coordMode == 0
    xiBegin = -round(gsize / 2);
elseif coordMode == 1
    xiBegin = [0 0 0];
elseif coordMode == 2
    xiBegin = [0 gsize(2) 0];
end
%Define length of array along each dimension    
xiVec   = xiBegin(1)+1:xiBegin(1)+gsize(1);
yiVec   = xiBegin(2)+1:xiBegin(2)+gsize(2);
ziVec   = xiBegin(3)+1:xiBegin(3)+gsize(3);
%Flip y if mode 2
if coordMode == 2
    yiVec = flip(yiVec);
end

% Generate matrix
[xm, ym, zm] = meshgrid(xiVec-centers(1), ...
 yiVec - centers(2), ziVec - centers(3));

%%calculating guassian
u  = (xm/sigmas(1)).^2 + (ym/sigmas(2)).^2 + (zm/sigmas(3)).^2;
gaussMat = exp(-u/2);
    
end
