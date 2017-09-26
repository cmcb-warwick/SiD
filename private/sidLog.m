function sidLog(fmt, varargin)
% SIDLOG Print formatted logging message
%
%    SIDLOG(FMT,...) Print formatted logging message. FMT is a printf-style
%    format string. Supply appropriate number of arguments after FMT.
%
% Copyright (c) 2012 Jonathan W. Armond

% Add timestamp to message.
fprintf([datestr(now, 'HH:MM:SS') ': ' fmt '\n'], varargin{:});
