classdef (InferiorClasses = {?rotation,?quaternion}) quadratureSO3Grid < orientation
% Compute nodes and weights for quadrature on SO(3). Therefore the
% following quadrature rules are implemented yet:
%
%   'ClenshawCurtis'  - combinate the Gauss quadrature in 1st and 3rd Euler angle 
%                       (alpha, gamma) with Clenshaw Curtis quadrature in 2nd 
%                       Euler angle (beta)
%   'GaussLegendre'   - combinate the Gauss quadrature in 1st and 3rd Euler angle 
%                       (alpha, gamma) with Gauss Legendre quadrature in 2nd 
%                       Euler angle (beta)
%
% Syntax
%   SO3G = quadratureSO3rid(N, 'ClenshawCurtis')
%   [SO3G, W] = quadratureSO3rid(N,CS,SS,'ClenshawCurtis') % quadrature grid of type Clenshaw Curtis
%
% Input
%  N - bandwidth
%  CS,SS  - @symmetries
%
% Output
%  SO3G - @orientation grid
%  W - quadrature weights
%
% Options
%  ClenshawCurtis - use Clenshaw Curtis quadrature nodes and weights (default)
%  GaussLegendre - use Gauss Legendre quadrature nodes and weights
%
% See also
% regularSO3Grid  SO3FunHarmonic/quadrature


properties
  weights =[]
  scheme = 'ClenshawCurtis'
  evalShape = []
end

properties (Dependent=true)
  bandwidth
  nodes
  uniqueNodes
  uniqueIndexes
end

methods

  function SO3G = quadratureSO3Grid(varargin)
  
    % Get bandwidth
    if nargin>0 && isnumeric(varargin{1}) && numel(varargin{1})==1
      N = varargin{1};
    else
      N = get_option(varargin,'bandwidth', getMTEXpref('maxSO3Bandwidth'));
    end
    % Get symmetries
    [SRight,SLeft] = extractSym(varargin);
    % Get quadrature scheme
    if check_option(varargin,'GaussLegendre')
      scheme = 'GaussLegendre';
    else
      scheme = 'ClenshawCurtis';
    end
    % check whether it is suitable
    quadratureSO3Grid.check_bandwidth(N,SRight,SLeft,scheme)
  
    % Do not use 'antipodal' for evaluation or quadrature grid
    varargin = delete_option(varargin,'antipodal');
   
    % The quadrature method itself only uses Z-fold rotational symmetry axis
    % (only use cyclic symmetry axis)
    sym = {'1','112','3','4','','6'};
    if isa(SRight,'crystalSymmetry')
      SRightNew = crystalSymmetry(sym{SRight.multiplicityZ});
    else
      SRightNew = specimenSymmetry(sym{SRight.multiplicityZ});
    end
    if isa(SLeft,'crystalSymmetry')
      SLeftNew = crystalSymmetry(sym{SLeft.multiplicityZ});
    else
      SLeftNew = specimenSymmetry(sym{SLeft.multiplicityZ});
    end
  
    % Construct quadrature nodes
    nodes = regularSO3Grid(scheme,'bandwidth',2*N,SRightNew,SLeftNew,varargin{:},'ABG');
    nodes.CS = SRight; nodes.SS = SLeft;
    SO3G = SO3G@orientation(nodes);
    s = size(nodes);
  
    % Construct Weights
    if check_option(varargin,'GaussLegendre')
      [~,w] = legendreNodesWeights(N+1,-1,1);
    else
      w = quadratureSO3Grid.fclencurt2(2*N+1);
      if s(2) == 1+N
        w = w(1:size(nodes,2));
      end
    end
    % W = normalized volume * 2xGauß-quadrature-weights * Clenshaw-Curtis-quadrature-weights
    % W =     1/sqrt(8*pi^2)    *      (2*pi/(2*N+2))^2     *              w_b^N
    SO3G.weights = repmat(w'/(2*s(1)*s(3)),s(1),1,s(3));
    SO3G.scheme = scheme;
  
  end

  function N = get.bandwidth(SO3G)
    s = size(SO3G);
    if strcmp(SO3G.scheme,'GaussLegendre')
      N = s(2)-1;
    else
      N = (s(2)-1)/2;
    end
  end

  function SO3G = set.bandwidth(SO3G,N)
    SO3G = quadratureSO3Grid(N,SO3G.CS,SO3G.SS,SO3G.scheme);
  end

  function nodes = get.nodes(SO3G)
    nodes = orientation(SO3G);
  end

  function u = get.uniqueNodes(SO3G)
    quadratureSO3Grid.check_bandwidth(SO3G.bandwidth,SO3G.CS,SO3G.SS,SO3G.scheme)
    u = uniqueQuadratureSO3Grid(SO3G);
  end

  function indexes = get.uniqueIndexes(SO3G)
    quadratureSO3Grid.check_bandwidth(SO3G.bandwidth,SO3G.CS,SO3G.SS,SO3G.scheme)
    [~,~,indexes] = uniqueQuadratureSO3Grid(SO3G);
  end

end

methods (Static = true, Hidden = true)

  function check_bandwidth(N,SRight,SLeft,scheme)
    % check for suiting bandwidth
    [~,~,g] = fundamentalRegionEuler(SRight,SLeft,'ABG');
    LCM = lcm((1+double(round(2*pi/g/SRight.multiplicityZ) == 4))*SRight.multiplicityZ,SLeft.multiplicityZ);
    t1 = N;
    while mod(2*t1+2,LCM)~=0
      t1 = t1-1;
    end
    t2 = N;
    while mod(2*t2+2,LCM)~=0
      t2 = t2+1;
    end
    if t1~=N
    error(['When trying to evaluate the function on ' ,scheme,...
           ' quadrature grid with bandwidth %i using the symmetries, ' ...
           'an error was detected. The specified bandwidth does not fit the ' ...
           'symmetries. Use bandwidth %i or %i instead.'],N,t1,t2);
    end 
  end

  function w = fclencurt2(n)

    c = zeros(n,2);
    c(1:2:n,1) = (2./[1 1-(2:2:n-1).^2 ])';
    c(2,2)=1;
    f = real(ifft([c(1:n,:);c(n-1:-1:2,:)]));
    w = 2*([f(1,1); 2*f(2:n-1,1); f(n,1)])/2;
    %x = 0.5*((b+a)+n*bma*f(1:n1,2));

  end


end

methods (Static = true)
  v = eval(SO3F, SO3G, varargin);
end

end


