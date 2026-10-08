function [outVec] = genericLenVec(inVec)
%GENERICLENVEC Takes in a vector of positive definite integers and returns
%a vector with repetitions of each element a number of times equal to the
%element. i.e. [3 4 1] yields [3 3 3 4 4 4 4 1]
% 2024-06-04 - Rémi Boros

outVec = genLenVec(inVec,inVec);

end

