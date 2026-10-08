function gaussMat = generate3DGaussians(gsize, centers, sigmas)
 %GENERATE2DGAUSSIANS Takes in matrix size GSIZE and gaussian parameters and
 %returns 3D gaussians centered at XC, YC, ZC with width sigmax, sigmay, 
 %sigmaz for x, y, z, respectively.
    
%Do some cleanup
if numel(sigmas) < numel(centers)
    if size(sigmas,2) == 1
        sigmas = sigmas*ones(size(centers));
    elseif size(sigmas,2) == size(centers, 2)
        sigmas = repmat(sigmas, size(centers,1), 1);
    end
end

%Generate matrix boundaries and vectors
xiBegin = -round(gsize / 2);
xiVec   = xiBegin+1:xiBegin+gsize;

% Calculate for each gaussian
gaussMat = zeros(gsize);
for currCen = 1:size(centers,1)
    % Generate matrices for each gaussian at diff centers
    [xm, ym, zm] = meshgrid((xiVec-centers(currCen,1))', ...
     (xiVec - centers(currCen,2))', (xiVec - centers(currCen,3))');
    
    %%calculating guassian
    u  = (xm/sigmas(currCen,1)).^2 + (ym/sigmas(currCen,2)).^2 + (zm/sigmas(currCen,3)).^2;
    gaussMat = gaussMat + exp(-u/2);
end

end
