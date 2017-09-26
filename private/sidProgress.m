function lastUpdate = sidProgress(progress, lastUpdate, updateInterval)
% SIDPROGRESS Print formatted progress message
%
% SYNOPSIS: sidProgress(progress, lastUpdate)
%
% INPUT progress: Fraction complete [0,1].
%
%       lastUpdate: Last timestamp progress was called with (optional).
%                   Omit for first call.
%
% Copyright (c) 2012 Jonathan W. Armond

currentClock = clock;

if nargin<3
    updateInterval = 10.0; % seconds
end

% Add timestamp to message.
fmt = [datestr(now, 'HH:MM:SS') ': % 6.2f%% complete\n'];

msg = sprintf(fmt, 100*progress);
if nargin < 2 || etime(currentClock, lastUpdate) > updateInterval
    % Print message.
    fprintf('%s\n',deblank(msg));
    lastUpdate = currentClock;
end
