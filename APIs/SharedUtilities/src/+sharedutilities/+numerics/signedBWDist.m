function [outMat] = signedBWDist(inMat)
%SIGNEDBWDIST Takes in a binarized stack inMat and returns the signed
%distance transform, that is dist(inMat) - dist(~inMat)
% 2026-04-28 - Rémi Boros

posMat = bwdist(inMat);
negMatPre = bwdist(~inMat);
% Enforce zero layer by shifting negMat by 1
negMat = sharedutilities.arrays.consMatLnB(negMatPre - 1,inMat);
% Combine matrices 
outMat = posMat - negMat;

end

