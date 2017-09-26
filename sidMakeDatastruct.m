function dataStruct = sidMakeDatastruct(job, channel)
%SIDMAKEDATASTRUCT Generates datastruct from Sid job
%
% SYNOPSIS: dataStruct = sidMakeDatastruct(job)
%
% INPUT job: Struct containing tracking job setup options.
%
% OUTPUT dataStruct: Struct containing the .dataProperties field.
%
% Created by: J. W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2017 Jonathan W. Armond

% Default values for non-Sid fields.
dataProperties.LENSID=12003;
dataProperties.timeLapse=1;
dataProperties.expTime=NaN;
dataProperties.NDfilter=NaN;
dataProperties.cellCycle=NaN;
dataProperties.strains=NaN;
dataProperties.drugs=NaN;
dataProperties.temperature={'Nan'};
dataProperties.crop=[];
dataProperties.F_TEST_PROB=0.9990;
dataProperties.IDopt= [];
dataProperties.PATCHSIZE=7;
dataProperties.CH_MAXNUMINTERV=1000;
dataProperties.OVERLPSIZE=[15 15 15];
dataProperties.sigmaCorrection=[1.5 1.5];
dataProperties.split=[];
dataProperties.MAXSPOTS=500;
dataProperties.T_TEST_PROB=0.0500;
dataProperties.maxSize = 100 * 2^20; % 100 Mb
dataProperties.amplitudeCutoff = 0; % undefined
dataProperties.fitNPlusOne = 1; % super-resolution fitting in detector
dataProperties.waveIdx = channel; % current wavelength
dataProperties.movieType = 'sorger'; % also: 'sedat', 'misteli', 'synth'
dataProperties.name = '';

% linker properties
dataProperties.linker_relativeMaxDistance = -1; % don't use
dataProperties.linker_absoluteMaxDistance=-1; % don't use
dataProperties.linker_relAmpWeight=1/1.5; % weighs distance more
dataProperties.linker_useCOM = 1; % use center of mass to correct
dataProperties.linker_fuseRatio = 1.5; % fuse if less than 1.5 RL separated

% detector properties
dataProperties.detector_spotfind = 1; %1: standard 2: mammalian

% Translate metadata.
md = job.metadata;

dataProperties.PIXELSIZE_XY = md.pixelSize(1);
if md.pixelSize(1) ~= md.pixelSize(2)
    error('unequal pixelsize x/y!')
end
dataProperties.PIXELSIZE_Z = md.pixelSize(3);
dataProperties.NA = md.na;
if isempty(job.ROI.crop)
    dataProperties.movieSize(1:2) = md.frameSize(1:2);
else
    dataProperties.movieSize(1:2) = job.ROI.cropSize(1:2);
end
dataProperties.movieSize(3) = md.frameSize(3);
dataProperties.movieSize(4) = md.nFrames;
dataProperties.WVL = md.wavelength;
% if there are multiple wavelengths: Make it a numZ x numT x
% numW array
dataProperties.frameTime = repmat(md.frameTime, [1, 1, length(md.wavelength)]);

% calculate filterparms
[FT_XY, FT_Z] = calcFilterParms(...
  dataProperties.WVL(dataProperties.waveIdx),dataProperties.NA,[],'gauss',...
  dataProperties.sigmaCorrection,...
  [dataProperties.PIXELSIZE_XY dataProperties.PIXELSIZE_Z]);
patchXYZ=roundOddOrEven(4*[FT_XY FT_XY FT_Z],'odd','inf');
dataProperties.FILTERPRM = [FT_XY,FT_XY,FT_Z,patchXYZ];
dataProperties.FT_SIGMA = [FT_XY,FT_XY,FT_Z];


% Assign to dataStruct.
dataStruct.dataProperties = dataProperties;

