function [csVec] = farmArrayCumSum(inVec)
%FARMARRAYCUMSUM Returns a vector containing the sum of all prior input vector
% Inputs:
%   inVec           Input numeric vector.
% Outputs:
%   csVec           Cumulative sums including the current input element.

csVec = arrayfun(@(x) sum(inVec(1:x)), 1:numel(inVec));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMARRAYCUMSUM Returns a vector containing the sum of all prior input vector
% indices up to the current index
% 2023-11-30
