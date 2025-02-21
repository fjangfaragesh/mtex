function h = plotAngleDistribution(obj,varargin)
% plot axis distribution
%
% Syntax
%
%   plotAngleDistribution(mdf)
%   plotAngleDistribution(CS1,CS2)
%   plotAngleDistribution(grains.boundary.misorientation)
%
% Input
%  CS - @symmetry
%
% Options
%  resolution, xy*degree - resolution of the plots (given as angle)
%  numBins - number of bins
%

[mtexFig,isNew] = newMtexFigure(varargin{:}); 
mtexFig.keepAspectRatio = false;

% compute angles
plotType = 'line';
if isa(obj,'symmetry')
  maxOmega = maxAngle(obj,varargin{:});
else
  maxOmega = maxAngle(obj.CS,obj.SS);
  if ~isa(obj,'SO3Fun'), plotType = 'bar'; end
end

% search for existing bar plots and adjust bar center
h = findobj(mtexFig.gca,'type','bar','-or','type','hgGroup');
h = flipud(h(:));

unit = '%';
if ~isempty(h)

  midPoints = ensurecell(get(h,'XData'));
  midPoints= midPoints{1}*degree;
  bins = [2*midPoints(1)-midPoints(2),midPoints,2*midPoints(end)-midPoints(end-1)];
  bins = (bins(1:end-1) + bins(2:end))/2;
  density = ensurecell(get(h,'YData'));
  density = cellfun(@(x) x(:),density,'UniformOutput',false);
  density = horzcat(density{:});
  lg = ensurecell(get(h,'DisplayName'));

  if strcmp(plotType,'bar')
    delete(h); % remove old bars
    % reset color order
    mtexFig.gca.ColorOrderIndex = 1;
  
    % add a new column
    density(:,end+1) = 0;
    
    % maybe we have to enlarge bins
    if maxOmega > max(bins)
      bins = 0:(bins(2)-bins(1)):maxOmega + 0.01;
      density(end+1:length(bins)-1,:) = 0;
    end
  else
    faktor = 100 / size(density,1);
  end
  
else
  
  if strcmp(plotType,'bar')
  
    % bin size given?
    if max(obj.angle) < maxOmega/2, maxOmega = max(obj.angle);end
    nbins = max(15,round(maxOmega/get_option(varargin,'resolution',5*degree)));
    nbins = get_option(varargin,'numBins',nbins);
    
    % compute bins
    bins = linspace(-eps,maxOmega+0.01,nbins);
    density = zeros(nbins-1,1);
    lg = {};
  elseif check_option(varargin,'percent')
    faktor = 100;    
  else
    faktor = 1;
    unit = 'mrd';
  end
end


% compute angle distribution
if isa(obj,'symmetry') || isa(obj,'SO3Fun')
  [density,omega] = calcAngleDistribution(obj,varargin{:});
else  
  d = histcounts(obj.angle,bins).';
  midPoints = 0.5*(bins(1:end-1) + bins(2:end));
  density(:,end) = 100 * d ./ sum(d);  
end

% plot angle distribution
if strcmp(plotType,'bar')

  h = optiondraw(bar(midPoints/degree,density,'parent',mtexFig.gca),varargin{:});
  xlim(mtexFig.gca,[0,max(bins)/degree])

  % update legend
  displayName = get_option(varargin,'DisplayName',[obj.CS.mineral '-' obj.SS.mineral]);
  lg = [lg;{displayName}];
  [h.DisplayName] = deal(lg{:});
  
else

  h = optiondraw(plot(omega/degree,faktor * max(0,density),...
    'parent',mtexFig.gca),'LineWidth',2,varargin{:});

end
  
% finish  
if isNew
  xlabel(mtexFig.gca,'Misorientation angle (degrees)');
  ylabel(mtexFig.gca,['Frequency (' unit ')']);
  drawNow(mtexFig,varargin{:});
end

if nargout == 0, clear h; end
