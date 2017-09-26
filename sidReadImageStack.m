function stack=sidReadImageStack(imageReader,metadata,c,crop,normalize)
% SIDREADIMAGESTACK Read a single image frame stack from an image file.
%
%    STACK = SIDREADIMAGESTACK(IMAGEREADER,METADATA,C,CROP,NORMALIZE) Read
%    a single image frame stack (i.e. all z-planes) at time T in channel C from
%    IMAGEREADER described by METADATA.
%
%    CROP Optional, vector of [XMIN,YMIN,WIDTH,HEIGHT] for cropping stack.
%
%    NORMALIZE Optional, 0, 1 or -1. Normalize by maximum pixel value. Defaults
%    to 1. If -1, no normalization is performed and image is returned in
%    original datatype, otherwise it is converted to double.
%
% Copyright (c) 2013 Jonathan W. Armond

if nargin<4
  crop = [];
end

if nargin<5
  normalize = 0;
end

if normalize == -1
  dataType = metadata.dataType;
else
  dataType = 'double';
end

stackSize = sidComputeStackSize(crop,metadata.frameSize);

stack = zeros(stackSize, dataType);
for z = 1:metadata.frameSize(3)
  stack(:,:,z) = sidReadImagePlane(imageReader, metadata, c, z, crop, normalize);
end

