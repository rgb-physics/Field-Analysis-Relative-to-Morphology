# Historical frequency helper

genScaledKVec.m is preserved before correction on 2026-10-13.
Original: src/+sharedutilities/+miscellaneous/genScaledKVec.m.
The original omitted zero frequency and depended on an unqualified genReflVec.
Replacement uses (-floor(N/2):ceil(N/2)-1)/(N*spacing), the frequency order of
fftshift for odd and even sample counts. FieldAnalysis tests cover this change.
