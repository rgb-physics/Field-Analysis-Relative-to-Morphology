function [newLog] = logAB(A,B)
%LOGAB Returns the log of B in the basis of A use the quotient rule of
%logarithms

newLog = log(A)./log(B);

end

