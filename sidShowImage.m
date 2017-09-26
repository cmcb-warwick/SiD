function sidShowImage(job,varargin)
% SIDSHOWIMAGE Plots multi-channel image.
%
%    SIDSHOWIMAGE(JOB,...) Shows cropped image from JOB.
%
%    Options, defaults in {}:-
%
%    channels: {[1 2]} or subset of 1 to 4. Channels in which to show images.
%
%    chanOrder: {'rgbm'} or other permutation of r (red), g (green), b
%       (blue) and m (magenta). Order in which channels provided in the job
%       file are represented as colours in the RGB image.
%
%    contrast: {{[0.1 1],[0.1 1],[0.1 1],[0.1 1]}}, 'help', or similar.
%       Upper and lower contrast limits for each channel. Values must be in
%       range [0 1]. 'help' outputs the minimum and maximum intensity
%       values as guidance, then requests values from the user.
%       Tips: - Increase the lower limit to remove background noise.
%             - Decrease the upper limit to increase brightness.
%
%    coords: {'xy'}, 'xz' or 'yz'. Coordinate plane in which to show
%       images.
%
%    crop: 0, {1} or -1. Whether or not to show cropped images, as defined
%       by ROI.crop. -1 shows a full image with the cropped region
%       annotated.
%
%    projectionRange: {[]}, 'help', or subset of other coordinate's full
%       range. The range of pixels over which to project the third
%       coordinate not given by 'coords'. 'help' outputs the possible
%       values the range can take, then requests a range from the user.
%
%    scaleBarLabel: {0} or 1. Whether or not to label the scale bar's
%       length.
%
%    scaleBarSize: {3} or distance in �m. Length of the scale bar. Scale
%       bars are overlaid at the south west (bottom right) of the image.
%
%    textNorthWest, textNorthEast and textSouthEast: {[]} or a string.
%       String labels to be overlaid on the image in the designated corner
%       of the image. To separate text into multiple lines in a given
%       corner, provide each line as a string in a different element of a
%       cell, e.g. {'mNeonGreen-','CENP-A'}.
%
%    transpose: {0} or 1. Whether or not to transpose images.
%
%
% Copyright (c) 2017 C. A. Smith

% define default options
opts.channels = [1 2];
opts.chanOrder = 'grmb';
opts.contrast = repmat({[0.1 1]},1,4);
opts.coords = 'xy';
opts.crop = 1; % use -1 to show crop on a full image
opts.projectionRange = [];
opts.scaleBarLabel = 0;
opts.scaleBarSize = 3; % in �m, length of scale bar
opts.textNorthWest = [];
opts.textNorthEast = [];
opts.textSouthEast = [];
opts.transpose = 0;
% process user-defined options
opts = processOptions(opts, varargin{:});

%% Pre-processing

% convert coordinates to image into numbers
switch opts.coords
    case 'xy'
        opts.coords = [1 2];
    case 'xz'
        opts.coords = [1 3];
    case 'yz'
        opts.coords = [2 3];
    otherwise
        error('Coordinates requested for imaging not recognised. Please provide either: ''xy'',''xz'' or ''yz''.');
end

% convert channel order into numbers
if length(opts.chanOrder) < length(opts.channels)
    error('Number of channels in channel order (n=%i) does not reflect the number of channels being imaged (n=%i).',...
        length(opts.chanOrder),length(opts.channels));
else
    chanOrder = [4 4 4 4];
    colours = {'r','g','b','m'};
    for iChan = 4:-1:1
        tempLoc = find(opts.chanOrder == colours{iChan});
        if ~isempty(tempLoc)
            chanOrder(tempLoc) = iChan;
        end
    end
    if sum(chanOrder == 4) > 1
        error('More channels required in channel order. Please provide at least 2.');
    end
end

% get the reader, and crop limits and size for the movie
if iscell(job)
    job = job{1};
end
jobID = job.index;
[~,reader] = sidOpenMovie(fullfile(job.movieDirectory,job.ROI.movie),'ROI');
md = job.metadata;
if opts.crop==1
  crop = job.ROI.crop;
  cropSize = job.ROI.cropSize;
else
  crop = [];
  cropSize = md.frameSize;
end

% get required metadata
pixelSize = md.pixelSize(1:3);

% provide guidance on projection range if requested
projectCoord = setdiff(1:3,opts.coords);
if strcmp(opts.projectionRange,'help')
    % get maximum crop size for third coordinate
    maxOtherCoordRange = cropSize(projectCoord);
    % output possible range 
    sidLog('Projection range guidance:');
    fprintf('Range in third coordinate: [1 %i].\n',maxOtherCoordRange);
    % request input from user
    userRange = input('Please provide range over which to project: ');
    while userRange(1)<1 || userRange(2)>maxOtherCoordRange || userRange(1)>userRange(2) 
        userRange = input('These values fall outside the permitted range. Please try again: ');
    end
    opts.projectionRange = userRange(1):userRange(2);
% otherwise check whether one has been provided
elseif isempty(opts.projectionRange)
    opts.projectionRange = 1:cropSize(projectCoord);
end

%% Create image structures

% produce structure to hold images, dependent on transposing
if opts.transpose
    rgbImg = zeros([cropSize(fliplr(opts.coords)), 3]);
else
    rgbImg = zeros([cropSize(opts.coords), 3]);
end

% get images for each channel
if strcmp(opts.contrast,'help')
    sidLog('Contrast guidance:');
end
for iChan = opts.channels
    
    % get image stack for this timepoint
    img = sidReadImageStack(reader, md, iChan, crop, 0);
    
    % project the image in the third coordinate
    switch projectCoord
        case 1
            img = img(opts.projectionRange,:,:);
        case 2
            img = img(:,opts.projectionRange,:);
        case 3
            img = img(:,:,opts.projectionRange);
    end
    img = max(img,[],projectCoord);
    % reshape the image to ensure is in the correct form
    img = reshape(img, size(img,opts.coords(1)), size(img,opts.coords(2)));
    if opts.transpose
        img = img';
    end
    
    % contrasting
    if iscell(opts.contrast)
        
        irange(iChan,:) = stretchlim(img,opts.contrast{iChan});
        
    elseif strcmp(opts.contrast,'help')
        
        % get maximum and minimum intensities of image
        intensityRange(1) = min(img(:));
        intensityRange(2) = max(img(:));
        % output possible range 
        fprintf('Range of intensities in channel %i: [%i %i].\n',iChan,intensityRange(1),intensityRange(2));
        % request input from user
        userRange = input('Please provide range of intensities to image: ');
        while userRange(1)>userRange(2) 
            userRange = input('The maximum cannot be smaller than the minimum. Please try again: ');
        end
        irange(iChan,:) = [userRange(1) userRange(2)];
        fprintf('\n');
        
    else
        irange(iChan,:) = opts.contrast(iChan,:);
    end
    if chanOrder(iChan)==4 % the magenta case
      rgbImg(:,:,1) = rgbImg(:,:,1) + imadjust(img, irange(iChan,:), []);
      rgbImg(:,:,3) = rgbImg(:,:,3) + imadjust(img, irange(iChan,:), []);
    else
      rgbImg(:,:,chanOrder(iChan)) = rgbImg(:,:,chanOrder(iChan)) + ...
          imadjust(img, irange(iChan,:), []);
    end

end

%% Plotting the image

figure(1); clf
imshow(rgbImg);
if opts.crop == -1
    hold on
    rectangle('Position',job.ROI(jobID).crop,'EdgeColor','w')
end

%% Overlays
indent = 10;

% scalebar
barLength = opts.scaleBarSize/pixelSize(1);
labelGap = 6;

if barLength > 0
    line([indent indent+barLength], [cropSize(1)-indent cropSize(1)-indent],...
      'Color','w','LineWidth',5);
    if opts.scaleBarLabel
        scaleLabel = [num2str(opts.scaleBarSize) ' �m'];
        text(indent+(barLength/2),imageSize(1)-indent-labelGap,scaleLabel,...
          'Color','w','HorizontalAlignment','center','FontSize',20);
    end
end

% text in each other corner
if ~isempty(opts.textNorthWest)
    % print label requested in top right
    if iscell(opts.textNorthWest)
        vertIndent = indent+((length(opts.textNorthWest)-1)*5);
    else
        vertIndent = indent;
    end
    text(indent,vertIndent,opts.textNorthWest,...
        'Color','w','FontSize',25,'HorizontalAlignment','left');
end
if ~isempty(opts.textNorthEast)
    % print label requested in top right
    if iscell(opts.textNorthEast)
        vertIndent = indent+((length(opts.textNorthEast)-1)*5);
    else
        vertIndent = indent;
    end
    text(imageSize(2)-indent,vertIndent,opts.textNorthEast,...
        'Color','w','FontSize',25,'HorizontalAlignment','right');
end
if ~isempty(opts.textSouthEast)
    % print label requested in top right
    if iscell(opts.textSouthEast)
        vertIndent = imageSize(1)-indent-((length(opts.textSouthEast)-1)*5);
    else
        vertIndent = imageSize(1)-indent;
    end
    text(imageSize(2)-indent,vertIndent,opts.textSouthEast,...
        'Color','w','FontSize',25,'HorizontalAlignment','right');
end

end