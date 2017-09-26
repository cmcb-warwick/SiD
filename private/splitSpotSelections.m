function spotSels = splitSpotSelections(spotSel)
% Use like newSpotSels = combineSpotSelections(spotSel);
%
% Copyright (c) 2017 C. A. Smith

if iscell(spotSel)
    error('Please provide only one spot selection structure.')
end
nExpts = length(spotSel.selection);
kitLog('Separating %i spot selections from the structure.',nExpts)

for iExpt = 1:nExpts
    spotSels{iExpt} = spotSel;
    spotSels.selection = spotSels.selection(iExpt);
end

end