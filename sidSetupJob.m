function jobset=sidSetupJob(jobset)
% SIDSETUPJOBSET Display GUI to setup and run spot finding.
%
% Copyright (c) 2017 C. A. Smith

% Download BioFormats, if necessary.
sidDownloadBioFormats();

if nargin<1 || isempty(jobset)
  jobset = sidDefaultOptions();
end

% Upgrade jobset, if required.
if ~isfield(jobset,'jobsetVersion') || ...
    jobset.jobsetVersion < sidVersion(2)
  jobset = sidJobset(jobset);
end

% Setup GUI.
dockStatus = get(0,'DefaultFigureWindowStyle');
set(0,'DefaultFigureWindowStyle','normal');
handles = createControls();
updateControls(jobset);
handles.fig.Visible = 'on';
uiwait(gcf);
close(gcf);
set(0,'DefaultFigureWindowStyle',dockStatus);

%% NESTED FUNCTIONS
function hs = createControls()
  
  % Create figure.
  colw = [55 40];
  figw = sum(colw);
  figh = 42;
  hs.fig = figure('Visible','off','Resize','off','Units','characters','Position',[100 35 figw figh]);
  hs.fig.DockControls = 'off';
  hs.fig.MenuBar = 'none';
  hs.fig.Name = 'Set up new job';
  hs.fig.NumberTitle = 'off';
  hs.fig.IntegerHandle = 'off';
  hs.fig.ToolBar = 'none';

  % Define font sizes.
  largefont = 16;
  medfont = 14;
  smallfont = 12;
  tinyfont = 10;
  
  % Set some standard positions and distances.
  h = 1.5; %height
  lh = 1.5*h; %large height
  dx = 2.5; %horizontal shift
  ddx = 1; %small horizontal shift
  toplabely = figh; %top-most point
  
  % Start first column.
  x = dx;
  w = colw(1)-2*dx;
  y = toplabely-lh;
  
  % Movie selection title.
  labw = 30;
  t = label(hs.fig,'1. Image selection',[x y labw h],largefont);
  t.FontWeight = 'bold';
  y = y-lh;
  
  % Movie directory selection.
  btnw = 15; btnh = 2;
  hs.selectDirectory = button(hs.fig,'Select directory',[x y btnw btnh],@selectDirectoryCB);
  x = x+btnw+ddx;
  hs.movieDirectory = editbox(hs.fig,'',[x y w-(x-dx) h]);
  hs.movieDirectory.Enable = 'inactive';
  x = dx; y = y-lh; labw = 20;
  label(hs.fig,'All available images:',[x y labw h]);
  panh = 10*h;
  y = y-panh;
  hs.movies = uicontrol(hs.fig,'Style','listbox','Units','characters',...
      'Position',[x y w panh],'Max',Inf,'Min',0,'FontSize',smallfont);
  jScrollPane = findjobj(hs.movies); % undocumentedmatlab.com hack to add horizontal scrollbars
  jScrollPane.setHorizontalScrollBarPolicy(32);

  % ROI selection.
  y = y-lh; labw = 20;
  label(hs.fig,'Selected images:',[x y labw h]);
  y = y-btnh; btnx = x; btnw = (w-3*ddx)/4;
  hs.fullROI = button(hs.fig,'Add',[btnx y btnw btnh],@addROICB);
  btnx = btnx+btnw+ddx;
  hs.cropROI = button(hs.fig,'Add & crop',[btnx y btnw btnh],@cropROICB);
  btnx = btnx+btnw+ddx;
  hs.deleteROI = button(hs.fig,'Delete',[btnx y btnw btnh],@deleteROICB);
  btnx = btnx+btnw+ddx;
  hs.viewROI = button(hs.fig,'View ROI',[btnx y btnw btnh],@viewROICB);
  panh = 10*h;
  y = y - panh;
  hs.ROIs = uicontrol(hs.fig,'Style','listbox','Units','characters',...
      'Position',[x y w panh],'Max',1,'Callback',@roisCB);
  jScrollPane = findjobj(hs.ROIs); % undocumentedmatlab.com hack to add horizontal scrollbars
  jScrollPane.setHorizontalScrollBarPolicy(32);

  %% Options column.
  
  % Start first column.
  x = colw(1)+dx;
  w = colw(2)-2*dx;
  y = toplabely-lh;
  
  % Options title.
  labw = 30;
  t = label(hs.fig,'2. Options',[x y labw h],largefont);
  t.FontWeight = 'bold';
  y = y-lh;
  
  % Process sub-title.
  labw = 30;
  t = label(hs.fig,'Channels',[x y labw h],medfont);
  t.FontWeight = 'bold';
  y = y-h;
  
  % Spot detection channel selection.
  labw = 35;
  label(hs.fig,'Detect spots in channel...',[x y labw h]);
  y = y-h;
  radx = x; radw = 5.5;
  for i=1:4
    hs.spotDetectCh{i} = uicontrol('Parent',hs.fig,'Units','characters','Style','radio',...
        'String',num2str(i),'Position',[radx y radw h],'Callback',@spotDetectChCB);
    radx = radx+radw+ddx;
  end
  hs.spotDetectCh{1}.Value = 1;
  hs.spotDetectChNum = 1;
  
  % Intensity measurement channels.
  y = y-h;
  labw = 35;
  label(hs.fig,'Measure intensities in channel(s)...',[x y labw h]);
  y = y-h;
  tickx = x; tickw = 5.5;
  for i=1:4
    hs.measCh{i} = checkbox(hs.fig,num2str(i),[tickx y tickw h],[],smallfont);
    tickx = tickx+tickw+ddx;
  end
  hs.measCh{1}.Value = 1;
  hs.measCh{1}.Enable = 'off';
  
  % Spot detection sub-title.
  y = y-lh;
  labw = 30;
  t = label(hs.fig,'Spot detection',[x y labw h],medfont);
  t.FontWeight = 'bold';
  
  % Spots per frame.
  y = y-2*h;
  labw = 15;
  label(hs.fig,'Spots per frame',[x y labw h],smallfont);
  editw = (w-(labw+2*dx))/2;
  editx = x+labw+dx;
  hs.minSpots = editbox(hs.fig,[],[editx y editw h],tinyfont);
  t = label(hs.fig,'min',[editx y+h editw h],smallfont);
  t.HorizontalAlignment = 'center';
  editx = editx+editw+dx;
  hs.maxSpots = editbox(hs.fig,[],[editx y editw h],tinyfont);
  t = label(hs.fig,'max',[editx y+h editw h],smallfont);
  t.HorizontalAlignment = 'center';
  
  % Detection sensitivity.
  y = y-h;
  labw = 25;
  t = label(hs.fig,'Detection sensitivity',[x y labw h],smallfont);
  t.TooltipString = 'A value between 0 and 1. Decreasing this value ignores dimmer spots.';
  editx = x+labw+ddx;
  editw = w-(labw+ddx);
  hs.alphaA = editbox(hs.fig,[],[editx y editw h],tinyfont);
  
  % Intensities sub-title.
  y = y-lh;
  labw = 30;
  t = label(hs.fig,'Intensity measurement',[x y labw h],medfont);
  t.FontWeight = 'bold';
  
  y = y-h;
  labw = 25; editx = x+labw+ddx;
  editw = w-(labw+ddx);
  label(hs.fig,'Mask radius (nm)',[x y labw h],smallfont);
  hs.maskRadius = editbox(hs.fig,[],[editx y editw h],tinyfont);
  y = y-lh;
  
  % Final checks title.
  labw = 30;
  t = label(hs.fig,'3. Final checks',[x y labw h],largefont);
  t.FontWeight = 'bold';
  y = y-lh;
  
  % Jobset name.
  labw = 10; 
  t = label(hs.fig,'Filename',[x y labw h],medfont);
  t.FontWeight = 'bold';
  y = y-h; labw = 15;
  label(hs.fig,['sidjobset_' datestr(now,'yymmdd') '_'],[x+ddx y labw h],smallfont);
  hs.filename = editbox(hs.fig,'filename',[x+(labw+ddx) y w-(labw+ddx) h]);
  y = y-lh;
  btnw = w/2; btnx = x+w/4; btnh = 2;
  hs.validateMetadata = button(hs.fig,'Validate metadata',[btnx y btnw btnh],@validateCB);
  y = y-btnh;
  hs.save = button(hs.fig,'Save jobset',[btnx y btnw btnh],@saveCB);
  
  % Cancel button.
  btnw = 12; btnh = 2;
  x = figw-(btnw+dx); y = 1;
  hs.cancel = button(hs.fig,'Cancel',[x y btnw btnh],@cancelCB);

  movegui(hs.fig,'center');
  
end

% Update control status based on contents of jobset.
function updateControls(jobset)
  
  hs = handles;
  opts = jobset.options;
  
  % fill movie information
  hs.movieDirectory.String = jobset.movieDirectory;
  set(hs.movies,'String',jobset.movieFiles,'Value',1:length(jobset.movieFiles));
  
  % fill channel options
  sDch = opts.detectChan;
  hs.spotDetectChNum = sDch;
  spotDetectChCB();
  for i=1:4
    hs.spotDetectCh{i}.Value = (i==sDch);
    hs.measCh{i}.Value = opts.measureChans(i);
  end
  
  % fill spot detect options
  hs.minSpots.String = num2str(opts.minSpots);
  hs.maxSpots.String = num2str(opts.maxSpots);
  hs.alphaA.String = num2str(opts.mmfSensitivity);
  
  % fill spot detect options
  hs.maskRadius.String = num2str(opts.maskRadius*1000);
  
  % fill filename information
  if isfield(jobset,'filename')
    [~,file] = fileparts(jobset.filename);
    hs.filename.String = file;
  end
  
  % check if metadata previously validated
  if isfield(jobset,'metadata') && jobset.metadata{1}.validated
    hs.validateMetadata.String = 'Re-validate...';
  end
      

  populateMovieBox();
  populateROIBox();
  
  handles = hs;
  
end

% Check controls for consistent input.
function tf=checkControls()
  
  hs = handles;
  
  v = hs.movieDirectory.String;
  if isempty(v)
    errorbox('No movie directory selected.');
    tf = false;
    return
  end
  
  v = hs.ROIs.Value;
  if v == 0
    errorbox('No movies selected from movie directory.');
    tf = false;
    return
  end
  
  v = hs.spotDetectChNum;
  if ~isfinite(v) || v<1 || v>4
    errorbox('Invalid channel number for spot detection channel. Should be a number between 1 and 4');
    tf = false;
    return
  end

  v = str2double(hs.minSpots.String);
  if ~isfinite(v) || v < 0
    errorbox('Invalid value for minimum spots per frame. Should be a positive number.')
    tf = false;
    return
  end
  v(2) = str2double(hs.maxSpots.String);
  if ~isfinite(v(2)) || v(2) < 0
    errorbox('Invalid value for maximum spots per frame. Should be a positive number.')
    tf = false;
    return
  elseif diff(v)<=0
    errorbox('Invalid values for spots per frame. Maximum number should be larger than the minimum.')
    tf = false;
    return
  end
  
  v = hs.filename.String;
  if isempty(v)
    errorbox('Filename is a required field.');
    tf = false;
    return
  end

  tf = true;
end

function roisCB(hObj,event)
  if isempty(handles.ROIs.Value)
    handles.ROIs.Value = 1;
  end
end

function selectDirectoryCB(hObj,event)
  if ~isempty(get(handles.ROIs,'String'))
    r = questdlg('Selecting movie directory will clear existing ROIs. Select?','Warning','Yes','No','No');
    if strcmp(r,'No')
      return
    end
  end

  dirName = uigetdir([], 'Select directory tree containing movies');
  if ~isempty(dirName)
    set(handles.movieDirectory, 'String', dirName);
    populateMovieBox();
    set(handles.ROIs,'String',[]);
  end
end

function addROICB(hObj,event)
  movieFiles = handles.movies.String;
  movieDir = handles.movieDirectory.String;
  v = handles.movies.Value;
  if isempty(v)
    errorbox('Must select movies first to skip ROIs');
    return
  end
  waitmsg = sprintf('Opening movie 1 of %i',length(v));
  hwait = waitbar(0,waitmsg);
  for i=1:length(v)
    md=sidOpenMovie(fullfile(movieDir,movieFiles{v(i)}),'ROI');
    crop = [1 1 md.frameSize(1:2)];
    cropSize = md.frameSize(1:3);
    r = length(jobset.ROI) + 1;
    jobset.ROI(r).movie = handles.movies.String{v(i)};
    jobset.ROI(r).crop = crop;
    jobset.ROI(r).cropSize = cropSize;
    if i<length(v)
      waitmsg = sprintf('Opening movie %i of %i',i+1,length(v));
      waitbar((i-1)/length(v),hwait,waitmsg);
    end
  end
  close(hwait);
  populateROIBox();
end

function cropROICB(hObj,event)
  movieFiles = handles.movies.String;
  movieDir = handles.movieDirectory.String;
  v = handles.movies.Value;
  if isempty(v)
    errorbox('Must select movies first before adding ROIs');
    return
  end
  waitmsg = sprintf('Opening movie 1 of %i',length(v));
  hwait = waitbar(0,waitmsg);
  for i=1:length(v)
    [crop,cropSize] = sidCropImage(fullfile(movieDir,movieFiles{v(i)}));
    if ~isempty(crop)
      for j=1:size(crop,1)
        r = length(jobset.ROI) + 1;
        jobset.ROI(r).movie = handles.movies.String{v(i)};
        jobset.ROI(r).crop = crop(j,:);
        jobset.ROI(r).cropSize = cropSize(j,:);
      end
    end
    if i<length(v)
      waitmsg = sprintf('Opening movie %i of %i',i+1,length(v));
      waitbar((i-1)/length(v),hwait,waitmsg);
    end
  end
  close(hwait);
  populateROIBox();
end

function deleteROICB(hObj,event)
  v = handles.ROIs.Value;
  if ~isempty(v)
    r = questdlg('Delete selected ROI?','Warning','Yes','No','No');
    if strcmp(r,'Yes')
      jobset.ROI(v) = [];
    end
  end
  populateROIBox();
end

function viewROICB(hObj,event)
  v = handles.ROIs.Value;
  if ~isempty(v)
    movieDir = handles.movieDirectory.String;
    sidImageProj(fullfile(movieDir,jobset.ROI(v).movie),[],jobset.ROI(v).crop);
  end
end

function spotDetectChCB(hObj,event)
  if exist('hObj')
    chan = str2double(hObj.String);
  else
    chan = jobset.options.detectChan;
  end
  handles.spotDetectChNum = chan;
  handles.measCh{chan}.Value = 1;
  handles.measCh{chan}.Enable = 'off';
  for i = setdiff(1:4,chan)
    handles.spotDetectCh{i}.Value = 0;
    handles.measCh{i}.Enable = 'on';
    handles.measCh{i}.Value = 0;
  end  
end

function validateCB(hObj,event)
  updateJobset();
  % check that ROIs are already provided
  if ~isfield(jobset,'ROI')
    errorbox('Must provide ROIs prior to validating their metadata.')
  else
    % loop over each movie
    for iMov = 1:length(jobset.ROI)
      [jobset,applyAll] = sidValidateMetadata(jobset,iMov);
      % skip showing remaining movies, just save metadata for all
      if applyAll
        for jMov = iMov+1:length(jobset.ROI)
          jobset.metadata{jMov} = jobset.metadata{iMov};
        end
        handles.validateMetadata.String = 'Re-validate...';
        break
      end
    end
    
  end
  % show that movies have been validated
  handles.validateMetadata.String = 'Re-validate...';
  
end

function saveCB(hObj,event)
  if ~checkControls()
    return
  end
  updateJobset();
  sidSaveJobset(jobset);
  uiresume(gcf);
end

function cancelCB(hObj,event)
  jobset.cancel = 1;
  uiresume(gcf);
end

function populateMovieBox()
  movieDir = handles.movieDirectory.String;
  if isempty(movieDir)
    handles.movies.String = [];
  else
    % Find movie files.
    movieFiles = sidFindFiles(movieDir, sidSupportedFormats(),1,0,1);
    % Strip search directory from filenames.
    for i=1:length(movieFiles)
      movieFiles{i} = strrep(movieFiles{i},[movieDir filesep],'');
    end
    set(handles.movies,'String',movieFiles,'Value',1:length(movieFiles));
  end
end

function populateROIBox()
  handles.ROIs.String=[];
  maxMovLen = 32;
  movieFiles = handles.movies.String;
  handles.ROIs.Value = 0; % Keep MATLAB quiet about invalid selection.
  if ~isempty(movieFiles)
    for i=1:length(jobset.ROI)
      handles.ROIs.String{i} = [strshorten(jobset.ROI(i).movie,maxMovLen) ' [' ...
                          num2str(round(jobset.ROI(i).crop),'%d ') ']'];
    end
  end
  if (handles.ROIs.Value <= 0 && ~isempty(handles.ROIs.String)) || handles.ROIs.Value > length(jobset.ROI)
    handles.ROIs.Value = 1;
  end
end

function updateJobset()
  
  hs = handles;
  
  jobset.movieDirectory = hs.movieDirectory.String;
  jobset.movieFiles = hs.movies.String;
  filename = ['sidjobset_' datestr(now,'yymmdd') '_' hs.filename.String '.mat'];
  jobset.filename = fullfile(jobset.movieDirectory,filename);

  opts = jobset.options;
  opts.detectChan = hs.spotDetectChNum;
  for i = 1:4
    opts.measureChans(i) = hs.measCh{i}.Value;
  end
  opts.minSpots = str2double(hs.minSpots.String);
  opts.maxSpots = str2double(hs.maxSpots.String);
  opts.mmfSensitivity = str2double(hs.alphaA.String);
  opts.maskRadius = str2double(hs.maskRadius.String)/1000;
  jobset.options = opts;
  
end

function errorbox(msg)
    h=msgbox(msg,'Error','Error','modal');
    uiwait(h);
end

end % sidSetupJob
