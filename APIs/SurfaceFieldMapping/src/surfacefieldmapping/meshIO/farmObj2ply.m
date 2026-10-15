function [plyStruct] = farmObj2ply(objStruct, saveBool, outDir, outName)
%FARMOBJ2PLY Takes in an obj file OBJOBJ and returns a structure suitable to be
%saved as a ply with fields f and v representing fields and vertices.
%Optionally, the user can save the resulting .ply object denoted by a
%boolean SAVEBOOL in a directory OUTDIR with name OUTNAME  

 plyStruct = struct();
 plyStruct.v = objStruct.v;   plyStruct.f = objStruct.f;

 if saveBool == 1
     plywrite(fullfile(outDir,outName),plyStruct.f,plyStruct.v);   
 end
 
end

