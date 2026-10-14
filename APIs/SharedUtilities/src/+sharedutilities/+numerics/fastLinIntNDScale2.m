function imageInterp=fastLinIntNDScale2(inputStack)
%FASTLININTNDSCALE2 Historical factor-2 interpolation between odd-index centers.
% 2D/3D; interpolate halfway between samples and extend final edges.
% Not MATLAB imresize pixel-center mapping; calibration remains caller-owned.
validateattributes(inputStack,{'numeric','logical'},{'real','nonempty'});
if ndims(inputStack)>3, error('sharedutilities:Dimensions','Supply a 2D or 3D array.'); end
imageInterp=single(inputStack); nD=ndims(inputStack);
for d=1:nD
    old=imageInterp; dims=size(old); outDims=dims; outDims(d)=2*dims(d);
    imageInterp=zeros(outDims,'single');
    odd=repmat({':'},1,nD); odd{d}=1:2:outDims(d); imageInterp(odd{:})=old;
    even=odd; even{d}=2:2:outDims(d)-2;
    left=odd; left{d}=1:dims(d)-1; right=left; right{d}=2:dims(d);
    imageInterp(even{:})=(old(left{:})+old(right{:}))/2;
    final=odd; final{d}=outDims(d); last=odd; last{d}=dims(d);
    imageInterp(final{:})=old(last{:});
end
end
