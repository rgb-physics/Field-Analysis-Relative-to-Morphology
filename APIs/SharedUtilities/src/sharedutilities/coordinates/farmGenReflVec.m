function [reflVec] = farmGenReflVec(inLength)
%FARMGENREFLVEC This function takes in a positive definite integer INLENGTH and
% Inputs:
%   inLength        Length of the reflected integer vector.
% Outputs:
%   reflVec         Reflected integer sequence with inLength entries.

halfVec = 1:ceil(inLength / 2);
if mod(inLength, 2) == 0
    reflVec = [halfVec fliplr(halfVec)];
else
    reflVec = [halfVec fliplr(halfVec(1:end - 1))];
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGENREFLVEC This function takes in a positive definite integer INLENGTH and
% returns a vector of consecutive integers from 1, up to max value, and
% back down to 1. This is vector is coined reflVec for "reflected vector"
% max value is defined as the ceiling of INLENGTH/2
% reflVec is defined to have INLENGTH elements
