function sidPrintDiagnostics(dataStruct)
% SIDPRINTDIAGNOSTICS Print out basic tracking diagnostics
%
% Created by: Jonathan W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2016 C. A. Smith

diag = dataStruct.diagnostics;

if isfield(diag,'nSpots')
  fprintf('Spots detected: %.1f\n',diag.nSpots);
end
fprintf('Mean intensity: %.3f ± %.3f\n',diag.meanInt,diag.stdInt);