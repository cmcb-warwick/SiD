function [jobset,applyAll] = sidValidateMetadata(jobset,iMov)
% SIDVALIDATEMETADATA Allows user to check and correct automatically-obtained
% metadata.
%
% Copyright (c) 2017 C. A. Smith

% get movie filepath
imageDirectory = jobset.movieDirectory;
image = jobset.ROI(iMov).movie;
imageFilePath = fullfile(imageDirectory,image);

%% GET METADATA FROM MOVIE

% get the metadata from the movie
md = sidOpenMovie(imageFilePath,'init',[],1);
md.validated = 0;

% back up metadata for now
jobset.metadata{iMov} = md;

%% GUI

% Setup GUI.
handles = createControls();
updateControls(md);
handles.fig.Visible = 'on';
uiwait(gcf);
close(gcf);

%% NESTED FUNCTIONS
function hs = createControls()
  
  figw = 42;
  figh = 29;
  hs.fig = figure('Visible','off','Resize','off','Units','characters','Position',[100 35 figw figh]);
  hs.fig.DockControls = 'off';
  hs.fig.MenuBar = 'none';
  hs.fig.Name = 'Validate metadata';
  hs.fig.NumberTitle = 'off';
  hs.fig.IntegerHandle = 'off';
  hs.fig.ToolBar = 'none';

  medfont = 14;
  smallfont = 12;
  tinyfont = 10;
  
  % Set some standard positions and distances
  h = 1.5; %height
  lh = 1.5*h; %large height
  dx = 2.5;
  ddx = 1.5;
  toplabely = figh-dx; %top-most point
  
  % Editable jobset name at top of the screen
  x = dx;
  w = figw-(2*dx);
  hs.imageNameText = label(hs.fig,'Image file name',[x toplabely w h],medfont);
  hs.imageNameText.FontWeight = 'bold';
  y = toplabely-lh;
  hs.imageName = label(hs.fig,[],[x+ddx y w-ddx lh],smallfont);
  
  %% List of metadata for validation
  
  % Dimensions panel.
  panh = 4.75*h; panx = dx; panw = w;
  y = y-(panh+ddx);
  hs.dimensionsPanel = uipanel(hs.fig,'Units','characters','Position',[panx y panw panh],'FontSize',smallfont,'Title','Image dimensions');
  p = hs.dimensionsPanel;
  
  % Frame size.
  panw = panw-2*ddx;
  pany = panh-2.25*h; labx = ddx;
  labw = 3*panw/4; editw = panw/4;
  hs.nXYpixelsText = label(p,'Frame size: [x,y]',[labx pany labw h],smallfont);
  editx = labx+labw;
  hs.nXYpixels = label(p,[],[editx pany editw h],smallfont);
  
  % Number of z-slices.
  pany = pany-h;
  labw = 3*panw/4; labx = ddx;
  hs.nPlanesText = label(p,'z-slices',[labx pany labw h],smallfont);
  editw = panw/4; editx = labx+labw;
  hs.nPlanes = editbox(p,[],[editx pany editw h],smallfont);
  
  % Number of channels.
  nChans = 4;
  pany = pany-h;
  labw = 2*panw/5; labx = ddx;
  hs.nChannelsText = label(p,'Channels',[labx pany labw h],smallfont);
  radw = (panw-labw)/nChans; radx = labx+labw;
  for iChan=1:nChans
    hs.channelNum{iChan} = uicontrol('Parent',p,'Units','characters','Style','radio','String',num2str(iChan),'Position',[radx pany radw h],'Callback',@nChannelsCB);
    radx = radx+(radw);
  end
  hs.channelNum{1}.Value = 1;
  hs.nChannels = 1;
  
  % Wavelengths of each channel.
  y = y-(lh+h);
  labw = 2*w/5; labx = dx;
  hs.wavelengthText = label(hs.fig,'Wavelength (nm)',[labx y labw h],smallfont);
  editw = (w-labw)/nChans; editx = labx+labw;
  for iChan=1:nChans
    hs.waveChanText{iChan} = label(hs.fig,['Ch.' num2str(iChan)],[editx y+0.75*h editw h],tinyfont);
    hs.waveChanText{iChan}.HorizontalAlignment = 'center';
    hs.wavelength{iChan} = editbox(hs.fig,num2str(iChan),[editx y editw h],smallfont);
    editx = editx+(editw);
  end
  
  % Pixel sizes.
  nCoords = 3;
  y = y-2*h;
  labw = 2*w/5; labx = dx;
  hs.pixelSizeText = label(hs.fig,'Pixel size (nm)',[labx y labw h],smallfont);
  editw = (w-labw)/nChans; editx = labx+labw;
  coordLabel = ['x','y','z'];
  for iCoord=1:nCoords
    editx = editx+(editw); %at the start to ensure alignment with wavelengths
    hs.pixCoordText{iCoord} = label(hs.fig,coordLabel(iCoord),[editx y+0.75*h editw h],tinyfont);
    hs.pixCoordText{iCoord}.HorizontalAlignment = 'center';
    hs.pixelSize{iCoord} = editbox(hs.fig,'',[editx y editw h],smallfont);
  end
  
  % Numerical aperture.
  y = y-h;
  labw = 0.8*w; labx = dx;
  hs.numAperText = label(hs.fig,'Numerical aperture',[labx y labw h],smallfont);
  editw = w-labw; editx = labx+labw;
  hs.numAper = editbox(hs.fig,[],[editx y editw h],smallfont);
  
  % Apply to all movies.
  y = y-(lh+h);
  labw = 3*w/4; labx = dx;
  hs.applyAll = checkbox(hs.fig,'Apply to all images?',[labx y labw h],[],smallfont);
  
  % Validate button
  btnw = 10; btnh = 2;
  btnx = figw-(btnw+dx);
  hs.validate = button(hs.fig,'Validate',[btnx y btnw btnh],@saveCB);
  
  % Cancel button
  y = y-btnh;
  btnw = 10; btnh = 2;
  btnx = figw-(btnw+dx);
  hs.cancel = button(hs.fig,'Cancel',[btnx y btnw btnh],@cancelCB);
  
  movegui(hs.fig,'center');
  
end

%% Update control status based on contents of metadata.
function updateControls(md)
  hs = handles;
  
  idx = find(jobset.ROI(1).movie=='/',1,'last');
  if isempty(idx)
    idx=0;
  end
  hs.imageName.String = jobset.ROI(iMov).movie(idx+1:end);
  hs.nXYpixels.String = [num2str(md.frameSize(1)) ' x ' num2str(md.frameSize(1))];
  hs.nPlanes.String = num2str(md.nPlanes/md.nChannels);
  hs.nChannels = md.nChannels;
  for iChan=1:4
    hs.channelNum{iChan}.Value = (iChan==hs.nChannels);
    hs.wavelength{iChan}.String = num2str(md.wavelength(iChan)*1000);
  end
  for iCoord=1:3
    hs.pixelSize{iCoord}.String = num2str(md.pixelSize(iCoord)*1000);
  end
  hs.numAper.String = num2str(md.na);
  
  handles = hs;
  
  nChannelsCB();
  
end

% Check controls for consistent input.
function tf=checkControls()
  hs = handles;
  
  v = str2double(hs.autoRadiidt.String);
  if (hs.autoRadii.Value == 1) && (~isfinite(v) || v<=0)
    errorbox('Invalid value for frame dt. Should be a positive number.')
    tf = false;
    return
  end

  v = str2double(hs.autoRadiiAvgDisp.String);
  if (hs.autoRadii.Value == 1) && (~isfinite(v) || v<0)
    errorbox('Invalid value for avg. disp. of spots. Should be a positive number.')
    tf = false;
    return
  end

  v1 = str2double(hs.minSearchRadius.String);
  v2 = str2double(hs.maxSearchRadius.String);
  if (hs.autoRadii.Value ~= 1) && (~isfinite(v1) || v1 > v2 || v1 < 0)
    errorbox('Invalid value min search radius. Should be a positive number less than max search radius.')
    tf = false;
    return
  end
  if (hs.autoRadii.Value ~= 1) && (~isfinite(v2) || v2 < v1 || v2 < 0)
    errorbox('Invalid value max search radius. Should be a positive number less than min search radius.')
    tf = false;
    return
  end

  v = str2double(hs.maxSisterAlignmentAngle.String);
  if (hs.useSisterAlignment.Value == 1) && (~isfinite(v) || v < 0 || v > 180)
    errorbox('Invalid value for max angle between sisters and plate normal. Should be a positive number.')
    tf = false;
    return
  end

  v = str2double(hs.maxSisterDist.String);
  if ~isfinite(v) || v < 0
    errorbox('Invalid value for max intersister distance. Should be a positive number.')
    tf = false;
    return
  end

  v = str2double(hs.minSisterTrackOverlap.String);
  if ~isfinite(v) || v < 0
    errorbox('Invalid value for min overlap between sister tracks. Should be a positive number.')
    tf = false;
    return
  end

  v = str2double(hs.minSpotsPerFrame.String);
  if ~isfinite(v) || v < 0
    errorbox('Invalid value for min spots per frame. Should be a positive number.')
    tf = false;
    return
  end

  v = str2double(hs.adaptiveLambda.String);
  if (~isfinite(v) || v < 0)
    errorbox('Invalid value for spot weight. Should be a positive number or zero.')
    tf = false;
    return
  end

  v = str2double(hs.maxMmfTime.String);
  if (hs.mmfAddSpots.Value == 1) && (~isfinite(v) || v < 0)
    errorbox('Invalid value for min spots per frame. Should be a positive number or zero.')
    tf = false;
    return
  end

  tf = true;
end

function nChannelsCB(hObj,event)
  if exist('hObj','var')
    nChans = str2double(hObj.String);
    handles.nChannels = nChans;
    for notChan = setdiff(1:4,nChans)
      handles.channelNum{notChan}.Value = 0;
    end
  end
  for iChan = 1:4
    if iChan > handles.nChannels
      handles.wavelength{iChan}.Enable = 'off';
      handles.waveChanText{iChan}.Enable = 'off';
    else
      handles.wavelength{iChan}.Enable = 'on';
      handles.waveChanText{iChan}.Enable = 'on';
    end
  end
end

function saveCB(hObj,event)
%   if ~checkControls()
%     return
%   end
  updateMetadata();
  sidSaveJobset(jobset);
  uiresume(gcf);
end

function cancelCB(hObj,event)
  
  jobset.cancel = 1;
  applyAll = [];
  uiresume(gcf);
  
end

function updateMetadata()

  md = jobset.metadata{iMov};
  
  md.nFrames = 1;
  md.nChannels = handles.nChannels;
  md.nPlanes = str2double(handles.nPlanes.String)*md.nChannels;
  md.frameSize(3) = str2double(handles.nPlanes.String);
  for iChan = 1:4
    md.wavelength(iChan) = str2double(handles.wavelength{iChan}.String)/1000;
  end
  md.frameTime = zeros(md.frameSize(3),1);
  md.is3D = (str2double(handles.nPlanes.String) > 1);
  md.na = str2double(handles.numAper.String);
  for iCoord = 1:3
    md.pixelSize(iCoord) = str2double(handles.pixelSize{iCoord}.String)/1000;
  end
  md.validated = 1;
  jobset.metadata{iMov} = md;
  
  applyAll = handles.applyAll.Value;
  
end

function errorbox(msg)
    h=msgbox(msg,'Error','Error','modal');
    uiwait(h);
end

end % sidValidateMetadata
