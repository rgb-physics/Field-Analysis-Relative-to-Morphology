function [cappedLayers] = capPtCloudFlat(topLayer, botLayer, capDim)
%CAPPTCLOUDFLAT Takes in two sheet layers stored in two matrices and
%returns a the two sheets stitched along one dimension by a flat surface.
%The resulting object is topologically tube-like. 2023-06-28

    endInd = size(topLayer, mod1b(capDim+1,2));
    permuteVec = 1:3; 
    permuteVec(capDim) = 3; permuteVec(3) = 2; permuteVec(mod1b(capDim+1,2)) = 1;
    invVec = [mod1b(capDim+1,2) 3 capDim];

    topLayerPerm = permute(topLayer, permuteVec);
    botLayerPerm = permute(botLayer, permuteVec);
    
    topCaps = topLayerPerm(:,:,[1 endInd]); botCaps = botLayerPerm(:,:,[1 endInd]);
    
    edge1 = inBetweenFill(topCaps(:,:,1), botCaps(:,:,1));
    edge2 = inBetweenFill(topCaps(:,:,2), botCaps(:,:,2));

    cappedLayers = permute(topLayer | botLayer, permuteVec);
    cappedLayers(:,:,1) = edge1; cappedLayers(:,:,end) = edge2;

    cappedLayers = permute(cappedLayers, invVec);

end



