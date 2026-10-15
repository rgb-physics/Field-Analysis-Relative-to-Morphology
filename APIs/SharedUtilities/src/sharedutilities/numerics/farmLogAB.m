function newLog = farmLogAB(A,B)
%FARMLOGAB Logarithm of B to base A; elementwise native logarithms.
validateattributes(A,{'numeric'},{'real','finite','positive'});
validateattributes(B,{'numeric'},{'real','finite','positive'});
if any(A(:)==1), error('sharedutilities:LogBase','Logarithm base cannot equal one.'); end
newLog = log(B)./log(A);
end
