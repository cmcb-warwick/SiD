function [jobset,applyAll] = sidValidateMetadata(jobset,iMov)
% SIDVALIDATEMETADATA Allows user to check and correct automatically-obtained
% metadata.
%
% Copyright (c) 2017 C. A. Smith

% get movie filepath
movieDirectory = jobset.movieDirectory;
movie = jobset.ROI(iMov).movie;
movieFilePath = fullfile(movieDirectory,movie);

%% GET METADATA FROM MOVIE

% get the metadata from the movie
md = sidOpenMovie(movieFilePath,'init',[],1);
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
  
  colwidth = 35;
  hs.fig = figure('Visible','off','Resize','off','Units','characters','Position',[100 35 colwidth+5 32]);
  hs.fig.DockControls = 'off';
  hs.fig.MenuBar = 'none';
  hs.fig.Name = ['Sid ' sidVersion(1) ' - Check metadata'];
  hs.fig.NumberTitle = 'off';
  hs.fig.IntegerHandle = 'off';
  hs.fig.ToolBar = 'none';

  figpos = hs.fig.Position;
  figw = figpos(3);
  figh = figpos(4);
  headfont = 16;
  medfont = 14;
  smallfont = 12;
  tinyfont = 10;
  
  % Set some standard positions and distances
  h = 1.5; %height
  lh = 1.5*h; %large height
  x = 2.5;
  toplabely = figh-x; %top-most point
  
  % Editable jobset name at top of the screen
  hs.movieNameText = label(hs.fig,'Movie file name',[x toplabely figw-x h],medfont);
  hs.movieNameText.FontWeight = 'bold';
  y = toplabely-lh;
  hs.movieName = label(hs.fig,[],[x+1.25 y figw-2*x lh],smallfont);
  
  % Validate button
  btnw = 10;
  btnx = figw-2.5-btnw;
  hs.validate = button(hs.fig,'Validate',[btnx 1.25 btnw h],@saveCB);
  
  % KiT logo
  hs.logo = uicontrol(hs.fig,'Units','characters','Position',[btnx 3 btnw 3.2]);
  pos = getpixelposition(hs.logo);
  set(hs.logo,'cdata',imresize(imread('private/sidlogo.png'),pos([4 3])));
  
  %% List of metadata for validation
  
  % tab-specific positions and distances
  colwidth = 35;
  x = x+2.5;
  w = colwidth-5;
  labelw = 0.75*w;
  editw = 0.2*w;
  editx = w-editw-1.5;
  
  % dimensions panel
  hs.dimensionsPanel = uipanel(hs.fig,'Units','characters','Position',[x y-6.75*h w 6.25*h],'FontSize',smallfont,'Title','Movie dimensions');
  p = hs.dimensionsPanel;
  y = y-lh;
  labelw = 0.75*w;
  edity = 4.25*h;
  colw = editw;
  colx = [editx+1.5-3*(colw-1.5);
          editx+1.5-2*(colw-1.5);
          editx+1.5-(colw-1.5);
          editx+1.5];
  
  hs.nXYpixelsText = label(p,'Frame size: [x,y]',[1 edity labelw h],smallfont);
  hs.nXYpixels = label(p,[],[editx-0.5*editw edity 2*editw h],tinyfont);
  edity = edity-h;
  hs.is3D = checkbox(p,'3D movies?',[1 edity labelw h],@is3DCB,smallfont);
  edity = edity-h;
  hs.nPlanesText = label(p,'z-slices',[1 edity labelw h],smallfont);
  hs.nPlanes = editbox(p,[],[editx edity editw h],tinyfont);
  edity = edity-h;
  hs.nFramesText = label(p,'Time points',[1 edity labelw h],smallfont);
  hs.nFrames = editbox(p,[],[editx edity editw h],tinyfont);
  edity = edity-h;
  hs.nChannelsText = label(p,'Channels',[1 edity labelw h],smallfont);
  for iChan=1:4
    hs.channelNum{iChan} = uicontrol('Parent',p,'Units','characters','Style','radio','String',num2str(iChan),'Position',[colx(iChan) edity colw h],'Callback',@nChannelsCB);
  end
  hs.channelNum{1}.Value = 1;
  hs.nChannels = 1;
  
  editx = x+w-editw;
  y = y-7.5*h;
  colw = 0.6*editw;
  colx = [colwidth-4*(colw+0.25);
          colwidth-3*(colw+0.25);
          colwidth-2*(colw+0.25);
          colwidth-1*(colw+0.25)];
  
  hs.wavelengthText = label(hs.fig,'Wavelength (nm)',[x y labelw h],smallfont);
  for iChan=1:4
    hs.waveChanText{iChan} = label(hs.fig,['Ch.' num2str(iChan)],[colx(iChan) y+0.75*h colw h],tinyfont);
    hs.waveChanText{iChan}.HorizontalAlignment = 'center';
    hs.waveChanText{iChan}.FontWeight = 'bold';
    hs.wavelength{iChan} = editbox(hs.fig,num2str(iChan),[colx(iChan) y colw h],tinyfont);
  end
  y = y-2*h;
  coordLabel = ['x','y','z'];
  hs.pixelSizeText = label(hs.fig,'Pixel size (nm)',[x y labelw h],smallfont);
  for iCoord=1:3
    hs.pixCoordText{iChan} = label(hs.fig,coordLabel(iCoord),[colx(iCoord+1) y+0.75*h colw h],tinyfont);
    hs.pixCoordText{iChan}.HorizontalAlignment = 'center';
    hs.pixCoordText{iChan}.FontWeight = 'bold';
    hs.pixelSize{iCoord} = editbox(hs.fig,num2str(iCoord),[colx(iCoord+1) y colw h],tinyfont);
  end
  y = y-lh;
  hs.timeLapseText = label(hs.fig,'Time lapse, dt (s)',[x y labelw h],smallfont);
  hs.timeLapse = editbox(hs.fig,[],[editx y editw h],tinyfont);
  y = y-h;
  hs.numAperText = label(hs.fig,'Numerical aperture',[x y labelw h],smallfont);
  hs.numAper = editbox(hs.fig,[],[editx y editw h],tinyfont);
  y = y-h;
  hs.applyAll = checkbox(hs.fig,'Apply to all movies?',[x y labelw h],[],tinyfont);
  
  movegui(hs.fig,'center');
  
end

%% Update control status based on contents of metadata.
function updateControls(md)
  hs = handles;
  
  idx = find(jobset.ROI(1).movie=='/',1,'last');
  if isempty(idx)
    idx=0;
  end
  hs.movieName.String = jobset.ROI(iMov).movie(idx+1:end);
  hs.nXYpixels.String = [num2str(md.frameSize(1)) ' x ' num2str(md.frameSize(1))];
  hs.is3D.Value = md.is3D;
  hs.nPlanes.String = num2str(md.nPlanes/(md.nChannels*md.nFrames));
  hs.nFrames.String = num2str(md.nFrames);
  hs.nChannels = md.nChannels;
  for iChan=1:4
    hs.channelNum{iChan}.Value = (iChan==hs.nChannels);
    hs.wavelength{iChan}.String = num2str(md.wavelength(iChan)*1000);
  end
  for iCoord=1:3
    hs.pixelSize{iCoord}.String = num2str(md.pixelSize(iCoord)*1000);
  end
  if str2double(hs.nFrames.String) == 1
    hs.timeLapse.String = 'N/A';
  else
    hs.timeLapse.String = num2str(md.frameTime(1,2));
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
  if exist('hObj')
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

function is3DCB(hObj,event)
  if handles.is3D.Value
    handles.nPlanes.Enable = 'on';
    handles.pixCoordText{3}.Enable = 'on';
    handles.pixelSize{3}.Enable = 'on';
  else
    handles.nPlanes.String = num2str(1);  
    handles.nPlanes.Enable = 'off';
    handles.pixCoordText{3}.Enable = 'off';
    handles.pixelSize{3}.Enable = 'off';
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

function updateMetadata()

  md = jobset.metadata{iMov};
  
  md.nFrames = str2double(handles.nFrames.String);
  md.nChannels = handles.nChannels;
  md.nPlanes = str2double(handles.nPlanes.String)*md.nFrames*md.nChannels;
  md.frameSize(3) = str2double(handles.nPlanes.String);
  for iChan = 1:3
    md.wavelength(iChan) = str2double(handles.wavelength{iChan}.String)/1000;
  end
  % construct frameTime
  if strcmp(handles.timeLapse.String,'N/A')
    frameTime = zeros(md.frameSize(3),1);
  else
    timeLapse = str2double(handles.timeLapse.String);
    for iTime = 1:md.nFrames
      timeLapsed = (iTime-1)*timeLapse;
      for iFrame = 1:md.frameSize(3)
        frameTime(iFrame,iTime) = timeLapsed;
      end
    end
  end
  md.frameTime = frameTime;
  md.is3D = handles.is3D.Value;
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
