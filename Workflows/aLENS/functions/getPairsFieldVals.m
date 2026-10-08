function [selFieldPairs] = getPairsFieldVals(GRIns,IDLUT,allPropsKey,sampleField)
%GETPAIRSFIELDVALS Under the hood calculations: from Global/Repl IDs, get
%[L,T] ID pairs. Find those [L,T] pairs in allIDProps object, then use
%indices to sample a field with equal number of rows stored in sampleField.
%Return the sampledField in the same format as GRIns.
% Rémi Boros - 2024-11-18

% Convert GR to [L,T] IDs
[stitchedLTs,GRIDs] = globRepl2LT(IDLUT, GRIns(:));
% From [L,T] pairs, get property values
selFieldVals = mapWrap(stitchedLTs,allPropsKey,sampleField,'rows');
% Map filament number back into [src,pred] pair order
selFieldPairs = mapWrap(GRIns,GRIDs,selFieldVals);

end

