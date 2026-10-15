function [outNum] = farmMod1b(queryNums,baseNum)
%FARMMOD1B Returns queryNum modulo baseNum in a range between 1 and baseNum
%rather than 0 and baseNum-1. Useful for 1-indexed systems

outNum = mod(queryNums - 1, baseNum) + 1;

end

