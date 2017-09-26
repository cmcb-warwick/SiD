function [crop,cropSize]=sidCropImage(imageFileName,zPlane)
%SIDCROPIMAGE Presents image projection for user to crop
%
%  SYNOPSIS crop=sidCropImage(imageFileName)
%
%  INPUT movieFileName: Filename of image to crop.
%        zPlane: Show single z-plane (optional).
%
%  OUTPUT crop: Vector of crop coordinates as [xmin,ymin,xmax,ymax]
%
% Copyright (c) 2012 Jonathan W. Armond

if nargin<2
  zPlane=[];
end

try
  [f,rgbImg,zPlanes] = sidImageProj(imageFileName,zPlane);
catch me
  errordlg(sprintf('Error opening file %s: %s',imageFileName,me.message));
  crop = []; cropSize = [];
  return
end
fax  = f.CurrentAxes;

% Show image with crop tool.
crop = [];
p = [];
title(fax,'Draw ROI rectangles. Double click to record each.');
figpos = get(f,'Position');
y = 2.5; x = 2.5;
btnw = 15; btnh = 2;
finBtn = button(f,'Finish',[x y btnw btnh],@(hObj,event) close(f),14);
x = x+(btnw+1);
addBtn = button(f,'Add ROI',[x y btnw btnh],@addROI_cb,14);
fcn = makeConstrainToRectFcn('imrect',get(fax,'XLim'),get(fax,'YLim'));
while ishghandle(f)
  uiwait(f);
  if ~isempty(p) && ishghandle(f)
    rectangle('Parent',fax,'Position',p,'LineWidth',2,'EdgeColor','y');
    crop = [crop; p];
    p = [];
  end
end

crop = round(crop);

% Process ROIs into crop rectangles.
sz = size(rgbImg);
if isempty(crop)
  % If no ROI selected use whole image.
  crop = [1 1 sz(1:2)];
end

for i=1:size(crop,1)
  cropImg = imcrop(rgbImg,crop(i,:));
  sz = size(cropImg);
  cropSize(i,:) = [sz(1:2) zPlanes];
end

function addROI_cb(hObj,eventdata,handles)
  set(addBtn,'Enable','off');
  set(finBtn,'Enable','off');
  h = imrect(fax,'PositionConstraintFcn',fcn);
  p = wait(h);
  delete(h);
  set(addBtn,'Enable','on');
  set(finBtn,'Enable','on');
  uiresume(f);
end

end
