function  display(grains,varargin)
% standard output

displayClass(grains,inputname(1));

disp(' ')
%disp(char(dynOption(grains)));

% generate phase table
matrix = cell(numel(grains.phaseMap),6);

allVolume = grains.volume;

for ip = 1:numel(grains.phaseMap)
  
  ind = grains.phaseId == ip;
  
  % phase
  matrix{ip,1} = num2str(grains.phaseMap(ip)); %#ok<*AGROW>
  
  % grains
  matrix{ip,2} = int2str(nnz(ind));
  
  % grains
  matrix{ip,3} = xnum2str(sum(allVolume(ind)));
  
  % abort in special cases
  if isempty(grains.CSList{ip})
    continue
  elseif ischar(grains.CSList{ip})
    matrix{ip,4} = grains.CSList{ip};
    continue
  else
    % mineral
    matrix{ip,4} = char(grains.CSList{ip}.mineral);
  end
  
  % symmetry
  matrix{ip,5} = grains.CSList{ip}.pointGroup;
  
  % reference frame
  matrix{ip,6} = option2str(grains.CSList{ip}.alignment);
  
end

% remove empty rows
matrix(accumarray(full(grains.phaseId),1,[size(matrix,1) 1])==0,:) = [];

if ~isempty(grains)
  cprintf(matrix,'-L',' ','-Lc',...
    {'Phase' 'Grains' 'Volume' 'Mineral'  'Symmetry' 'Crystal reference frame'},...
    '-d','  ','-ic',true);
else
  disp('  no grains here!')
end

disp(' ')

% show boundary and triple points
disp([' ' varlink([inputname(1),'.boundary'],'boundary faces') ': ',int2str(length(grains.boundary))])
%disp([' ' varlink([inputname(1),'.innerBoundary'],'inner boundary faces') ': ',int2str(length(grains.innerBoundary))])
%disp([' ' varlink([inputname(1),'.triplePoints'],'triple points') ': ',int2str(length(grains.triplePoints))])
disp(' ');

if isempty(grains), return; end

% show properties
disp(char(dynProp(grains.prop),...
  'Id',grains.id,'Phase',grains.phase,'Pixels',grains.numPixel))
disp(' ')
