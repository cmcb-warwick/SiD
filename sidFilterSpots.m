function sidFilterSpots(jobset)
% SIDMANUALFILTER(EXPTS,...) Allows the user to remove erroneous data from
% a previously run jobset.
%
% Copyright (c) 2017 C. A. Smith

% define colours for rectangles
handles.col = [1 0   0;...
               0 0.75 0];

% get the data
job = sidLoadAllJobs(jobset);
handles.nImgs = length(job);

% get basic information
c = jobset.options.detectChan;

% start progress bar
prog = sidProgress(0);

% predefine some handles required during looping
handles.imgID = 1;
handles.prevEnable = 'off';
handles.nextEnable = 'on';

% start while loop until aborted
handles.stop = 0;
while ~handles.stop
    
    % get this image ID
    iImg = handles.imgID;

    % check whether there is any data contained within this movie
    if ~isfield(job{iImg},'dataStruct') || ~isfield(job{iImg}.dataStruct{c},'failed') || job{iImg}.dataStruct{c}.failed
        continue
    end
    % get dataStruct
    dS = job{iImg}.dataStruct{c};
    % get the full initCoord and spotInt
    iC = dS.initCoord;
    sI = dS.spotInt;
    % get IDs for all spots not previously filtered
    nonNaNs = find(~isnan(iC.allCoord(:,1)));
    
    % back up the full initCoord and spotInt
    if isfield(dS,'rawData')
      iC = dS.rawData.initCoord;
      sI = dS.rawData.spotInt;
    end
    raw.initCoord = iC;
    raw.spotInt = sI;
    dS.rawData = raw;
    
    % get number of spots
    nSpots = length(dS.initCoord.allCoord);
    handles.nSpots = nSpots;

    % show all spots - defined using tracks
    rectDims = griddedSpots(job{iImg},'channel',c);
    
    % get image information
    rectPos = rectDims(:,1:2);
    rectWid = rectDims(1,3);
    handles.rectPos = rectPos;
    handles.rectWid = rectWid;
    handles.keep = ismember(1:nSpots,nonNaNs);
    
    % draw rectangles
    hold on
    for iSpot = 1:nSpots
        % get the colour for this spot
        keep = handles.keep(iSpot);
        icol = handles.col(keep+1,:);
        
        % draw the rectangle
        rectangle('Position',[rectPos(iSpot,:)-0.5 rectWid rectWid],...
            'EdgeColor',icol,'LineWidth',3);
    end
    
    % Buttons and labels.
    btnw = [12 7]; btnh = 2; h = 1.5;
    figpos = get(gcf,'Position');
    dx = 2.5; ddx = 1;
    % make label at top left for instructions
    x = dx; y = figpos(4)-(btnh+ddx);
    labw = 60;
    handles.instructions = label(gcf,'Click on spots to keep (green) or remove (red).',[x y labw h],12);
    % add all buttons: finish, next and previous
    x = figpos(3)-(btnw(1)+dx);
    handles.finishBtn = button(gcf,'Finish',[x y btnw(1) btnh],@finishCB);
    x = x-(btnw(2)+ddx);
    handles.nextBtn = button(gcf,'Next',[x y btnw(2) btnh],@nextCB);
    handles.nextBtn.Enable = handles.nextEnable;
    x = x-(btnw(2)+ddx/2);
    handles.prevBtn = button(gcf,'Prev',[x y btnw(2) btnh],@prevCB);
    handles.prevBtn.Enable = handles.prevEnable;
    % deselect all
    x = figpos(3)-(btnw(1)+dx); y = dx;
%     handles.deselectBtn = button(gcf,'Deselect all',[x y btnw(1) btnh],@deselectAllCB);
    handles.invertBtn = button(gcf,'Invert all',[x y btnw(1) btnh],@invertCB);
    
    % set up remove environment
    set(get(gca,'Children'),'ButtonDownFcn',@rmvCB);
    
    % GUI now set up, wait for user
    uiwait(gcf);
    
    % get the spots requiring removal
    rmvList = find(~handles.keep);
    
    % check for any sisters not in the list, provide warning and
    % remove if so
    incorrect = setdiff(rmvList,1:nSpots);
    if ~isempty(incorrect)
        warning('The following selected spots do not exist: %s. Will ignore.',num2str(incorrect));
    end

    % process the list
    if ~isempty(rmvList)
        % push all removed spots to NaNs
        nRmvs = length(rmvList);
        % push to initCoord
        iC.allCoord(rmvList,:) = NaN;
        iC.allCoordPix(rmvList,:) = NaN;
        iC.nSpots = iC.nSpots-nRmvs;
        iC.amp(rmvList,:) = NaN;
        iC.bg(rmvList,:) = NaN;
        % push to spotInt
        sI.intensity_mean(rmvList,:) = NaN;
        sI.intensity_median(rmvList,:) = NaN;
        sI.intensity_min(rmvList,:) = NaN;
        sI.intensity_max(rmvList,:) = NaN;
        sI.intensity_ratio(rmvList,:) = NaN;
    end

    % back up results and save
    dS.initCoord = iC; dS.spotInt = sI;
    job{iImg}.dataStruct{c} = dS;
    job{iImg} = sidSaveJob(job{iImg});

    % update progress
    prog = sidProgress(iImg/handles.nImgs,prog);
    
    % close the figure for the next image
    close(gcf);

end

sidLog('Manual filtering complete.');


%% Callback functions

function rmvCB(hObj,event)
  
  % get the position of the click
  pos=get(gca,'CurrentPoint');
  xpos = pos(1,1); ypos = pos(1,2);

  % get all positions
  allPos = handles.rectPos;
  
  % get candidates using click's row position
  diffs = xpos-allPos(:,1);
  diffs(diffs<0) = NaN;
  xidx = find(diffs == nanmin(diffs));
  % get candidates using click's column position
  diffs = ypos-allPos(:,2);
  diffs(diffs<0) = NaN;
  yidx = find(diffs == nanmin(diffs));
  % get the common candidate
  idx = intersect(xidx,yidx);

  % if a click is made elsewhere, remind user how to select images
  if isempty(idx)
    handles.instructions.String = 'Click on the images to select/deselect.';
    return
  end
  
  % get the colour for this spot
  keepStat = ~handles.keep(idx);
  icol = handles.col(keepStat+1,:);

  % draw the rectangle
  rectangle('Position',[handles.rectPos(idx,:)-0.5 handles.rectWid handles.rectWid],...
      'EdgeColor',icol,'LineWidth',3);

  handles.keep(idx) = keepStat;
  
end

function deselectAllCB(hObj,event)
  hs = handles;
  % force all stops to be ignored
  handles.keep(1,:) = 0;
  for i = 1:hs.nSpots
    % draw the rectangle
    rectangle('Position',[hs.rectPos(i,:)-0.5 hs.rectWid hs.rectWid],...
        'EdgeColor',hs.col(1,:),'LineWidth',3);
  end
end

function invertCB(hObj,event)
  hs = handles;
  % force all stops to be ignored
  handles.keep = ~handles.keep;
  for i = 1:hs.nSpots
    
    % get the colour for this spot
    keepStat = handles.keep(i);
    jcol = handles.col(keepStat+1,:);
    
    % draw the rectangle
    rectangle('Position',[hs.rectPos(i,:)-0.5 hs.rectWid hs.rectWid],...
        'EdgeColor',jcol,'LineWidth',3);
  end
end

function prevCB(hObj,event)
  % update the handles
  handles.imgID = handles.imgID-1;
  if handles.imgID == 1
    handles.prevEnable = 'off';
  end
  handles.nextEnable = 'on';
  % continue the function
  uiresume(gcf);
end

function nextCB(hObj,event)
  % update the handles
  handles.imgID = handles.imgID+1;
  handles.prevEnable = 'on';
  if handles.imgID == handles.nImgs
    handles.nextEnable = 'off';
  end
  % continue the function
  uiresume(gcf);
end

function finishCB(hObj,event)
  % force stop
  handles.stop = 1;
  % continue the function
  uiresume(gcf);
end

end

    