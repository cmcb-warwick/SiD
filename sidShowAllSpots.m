function sidShowAllSpots(job,varargin)
% SIDSHOWALLSPOTS Plots images of each spot in an image.
%
%    SIDSHOWALLSPOTS(JOB,...) Plots coordinates over images of each
%    spot localised in a given channel.
%
%    Options, defaults in {}:-
%
%    channel: {1}, 2 or 3. Which channel to show.
%
%    subset: {[]} or array of numbers. The spots to plot from a movie.
%           These numbers will refer to the track ID for each spot.
%
%
% Copyright (c) 2017 C. A. Smith

opts.channel = 1;
opts.subset = [];
opts = processOptions(opts,varargin{:});

% suppress warnings
w = warning;
warning('off','all');

% get important information
dS = job.dataStruct{opts.channel};
if isempty(opts.subset)
  nSpots = size(dS.initCoord.allCoord,1);
  opts.subset = 1:nSpots;
else
  nSpots = length(opts.subset);
  opts.subset = opts.subset(:)'; %ensure is a row vector
end
opts.imageSize = job.ROI.cropSize;

% set up figure
figure(1); clf
fig_n=ceil(sqrt(nSpots));
fig_m=ceil(nSpots/fig_n);

% open movie
[~,reader] = sidOpenMovie(fullfile(job.movieDirectory,job.ROI.movie),'ROI');
% read stack
img = sidReadImageStack(reader,job.metadata,opts.channel,job.ROI.crop,0);

% show each sister
for iSpot=opts.subset
    
    opts.spotID = iSpot;
    
    f = subplot(fig_m,fig_n,iSpot);
    
    noCoords = showSpot(job,img,opts);
    if noCoords
        cla(f);
    else
        plotTit = sprintf('Spot %i',iSpot);
        title(plotTit,'FontSize',10)
    end
end

warning(w);

end
   
%% SUB-FUNCTIONS
function noCoords = showSpot(job,img,opts)

% get coordinate system and plot channels
chan = opts.channel;
refChan = job.options.detectChan;

% get sister information
tk = opts.spotID;

% get pixel resolution
pixelSize = job.metadata.pixelSize;
imageSize = size(img);

% accumulate initCoord information
iC = job.dataStruct{refChan}.initCoord;
coords = iC.allCoordPix(tk,1:3);

% check whether any coordinates have been found, plot nothing if so
if any(isnan(coords))
    noCoords = 1;
    return
else
    noCoords = 0;
end

% calculate centre pixel
centrePxl = round(coords);

% max project over three z-slices around point
img = max(img(:,:,max(1,centrePxl(3)-2):min(centrePxl(3)+2,opts.imageSize(3))), [], 3);

% produce cropped image around track centre
xReg = [centrePxl(1)-ceil(0.5/pixelSize(1))+1 ...
           centrePxl(1)+ceil(0.5/pixelSize(1))+1];
yReg = [centrePxl(2)-ceil(0.5/pixelSize(2))+1 ...
           centrePxl(2)+ceil(0.5/pixelSize(2))+1];
xReg(1) = max(xReg(1),1); xReg(2) = min(xReg(2),imageSize(2));
yReg(1) = max(yReg(1),1); yReg(2) = min(yReg(2),imageSize(1));
imgCrpd = img(yReg(1):yReg(2),xReg(1):xReg(2));

% define contrast stretch and apply
irange=stretchlim(imgCrpd,[0.1 1]);
imgCrpd = imadjust(imgCrpd, irange, []);

% correct coordinates to the cropped region
coords(:,1:2) = coords(:,1:2) - [xReg(1) yReg(1)] + 1;

% plot image
imshow(imgCrpd)

% plot coordinates
hold on
plot(coords(1),coords(2),...
    'Color','k','Marker','x','MarkerSize',10)
hold off

end
