function [csVec] = farmArrayCumSum(inVec)
%FARMARRAYCUMSUM Returns a vector containing the sum of all prior input vector
%indices up to the current index
% 2023-11-30
csVec = arrayfun(@(x) sum(inVec(1:x)), 1:numel(inVec));
end

