function plotSection(SO3F,varargin)
% plot ODF sections
%
% Options
%  sections - number of sections
%  points   - number of orientations to be plotted
%  all      - plot all orientations
%  resolution - resolution of each plot
%
% Flags
%  phi2      - phi2 sections (default)
%  phi1      - phi1 sections
%  gamma     - gamma sections
%  alpha     - alpha sections
%  sigma     - sigma = phi1 - phi2 sections
%  axisAngle - rotational angle sections
%  smooth    - smooth plot 
%  countourf - filled contour plot 
%  contour   - contour plot
%  contour3, surf3, slice3 - 3d volume plot
%
% Example
% % Section plots at specific angles
% plotSection(SO3Fun.dubna,'phi2',[15,23,36]*degree)
%
% See also
% saveFigure Plotting

if numel(SO3F)>1
  warning(['You try to plot an multivariate function. Plot the desired components ' ...
    'manually. In the following the first component is plotted.'])
  SO3F = SO3F.subSet(1);
end
if ~SO3F.isReal
  warning(['Imaginary part of complex valued SO3FunHarmonic is ignored. ' ...
    'In the following only the real part is plotted.'])
  SO3F.isReal=1;
end


if SO3F.antipodal, ap = {'antipodal'}; else, ap = {}; end
oS = newODFSectionPlot(SO3F.CS,SO3F.SS,ap{:},varargin{:});

% The following does not really speed up since the plotting routine (and not evaluation is very expensive)
% if isa(oS,'gammaSections')   % use equispaced fft
%   % TODO: Use symmetries / do the same for alpha,phi1,phi2 sections
%   oS.plotGrid = plotS2Grid(oS.sR,'resolution',2.5*degree,varargin{:});
%   if isa(oS,'gammaSections')
%     l = numel(oS.gamma);
%   elseif isa(oS,'phi2Sections')
%     l = numel(oS.phi2);
%   elseif isa(oS,'phi1Sections')
%     l = numel(oS.phi1);
%   end
%   oS.gridSize = (0:l) * length(oS.plotGrid);
%   SO3F.isReal = 1;
%   Z = evalSectionsEquispacedFFT(SO3F,oS,'resolution',2.5*degree,varargin{:});
% else
  % plotSection@SO3Fun(SO3F.subSet(1),varargin{:});
  S3G = oS.makeGrid('resolution',2.5*degree,varargin{:});
  % plot on S3G with evalfft
  SO3F.isReal = 1;
  Z = SO3F.eval(S3G,varargin{:});
  clear S3G
% end

cR = [min(Z(:)),max(Z(:))];
if isempty(cR)
  cR = [0,1];
elseif cR(1) == cR(2)
  if cR(1) == 0
    cR(2) = 1;
  else
    cR(1) = 0;    
  end
end

oS.plot(Z,'smooth','colorRange',cR,varargin{:});
