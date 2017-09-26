function version=sidVersion(mode)
% SIDVERSION Return string containing version number.

if nargin < 1
  mode = 1;
end

switch mode
  case 1
    % Sid version.
    version = '1.0.3';
  case 2
    % Jobset structure version.
    version = 1;
  otherwise
    error('Unknown version mode');
end
