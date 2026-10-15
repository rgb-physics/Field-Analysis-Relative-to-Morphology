function matrix = farmOGBroadenRaster(mask,options,grid)
%FARMOGBROADENRASTER Zero-padded Gaussian occupancy, followed by optional strict threshold.
sigma = double(options.Sigma(:).');
dims = numel(grid.Size);
if ~isscalar(sigma)&&numel(sigma)~=dims
    error('objectgeometry:SigmaDimensions','Sigma must be scalar or match the grid dimensions.');
end
matrix = mask;
if any(sigma>0)
    if isscalar(sigma), sigma = repmat(sigma,1,dims); end
    matrix = double(mask);
    % Separable normalized Gaussian, truncated at +/-ceil(2*sigma).
    % convn uses zero exterior padding, including singleton spatial axes.
    for axis = 1:dims
        if sigma(axis)==0, continue; end
        radius = ceil(2*sigma(axis)); x = -radius:radius;
        kernel = exp(-x.^2/(2*sigma(axis)^2)); kernel = kernel/sum(kernel);
        shape = ones(1,max(2,dims)); shape(axis) = numel(kernel);
        matrix = convn(matrix,reshape(kernel,shape),'same');
    end
end
if ~isempty(options.Threshold), matrix = matrix>options.Threshold; end
end
