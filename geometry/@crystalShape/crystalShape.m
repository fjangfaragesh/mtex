classdef crystalShape
  % a class representing crystal shapes.
  %
  % The code of this class is based on the paper
  %
  % Enderlein, J., 1997. A package for displaying crystal morphology.
  % Mathematica Journal, 7(1).
  %
  % Example
  %
  %   mtexdata titanium;
  %   cS = crystalShape.hex(ebsd.CS)
  %   close all
  %   plot(cS)
  %   
  
  properties
    N % face normals
    V % vertices
    F % faces

    habitus = 0 % describes how visible mixed hkl faces are
    extension = [1 1 1]; % describes distance of the faces in dependence of hkl
  end
  
  properties (Dependent = true)
    CS % crystal symmetry
    diameter
    faceArea
    faceCenter
    volume
    E % edges
  end
  
  methods
    
    function cS = crystalShape(N,habitus,extension)
      
      if isa(N,'crystalSymmetry')
        N = basicHKL(cs);
        N = N .* N.dspacing;
      else
        %N = unique(N.symmetrise,'noSymmetry');
      end
      cS.N = N;
      
      if nargin >= 2, cS.habitus = habitus; end
      if nargin >= 3, cS.extension = extension; end
      
      cS = cS.update;
    end
        
    function cS = update(cS)

      % ensure N is vector3d and apply habitus scaling
      N = cS.N(:); %#ok<*PROP>
      if cS.habitus >0
        N = N ./ ((abs(N.h) * cS.extension(1)).^cS.habitus + ...
          (abs(N.k) * cS.extension(2)).^cS.habitus + ...
          (abs(N.l) * cS.extension(3)).^cS.habitus).^(1/cS.habitus);
      end
      
      N = unique(vector3d(N.symmetrise),'stable');
            
      tol = 1e-5;

      % compute vertices as intersections between all combinations
      % of three planes
      [a,b,c] = allTriple(1:length(N));
      V = planeIntersect(N(a),N(b),N(c));

      % take only the finite ones
      V = V(V.isfinite);

      % take only those inside the polyhedron
      V = V(all(dot_outer(V,N) <= 1 + tol,2));
      V = unique(V);
      
      % triangles of the convex hull of vertices
      T = convhull(V.xyz);
      
      % preallocate face list
      cS.F = nan(length(N),length(N));
      
      % incidence matrix vertices - faces / normals
      I_VN = dot_outer(V,N) > 1 - tol;

      % for all potential faces
      for in = 1:length(N)
          
        % vertices of triangles with exactly 2 points in the face N(in)
        V_in = T(sum(reshape(I_VN(T,in),[],3),2)==2,:);
        
        % take only those points of Kf that belongs to C (delete the others)
        V_in(~I_VN(V_in,in)) = NaN;
        V_in=sort(V_in,2);
        V_in(:,3)=[];
        
        % connect edges to form a polygon
        face = cell2mat(EulerCycles(V_in));
        cS.F(in,1:length(face)) = face;
        
      end

      % write back to class as vector3d
      % and scale vertices such that maximum distance between them is 1
      cS.V = V(:) ./ max(norm(V)) ./ 2;
      
    end
    
    function cs = get.CS(cS)
      cs = cS.N.CS;
    end
    
    function d = get.diameter(cS)
      V = repmat(cS.V(:,1),1,size(cS.V,1));
      d = max(max(norm(V - V.')));
    end
    
    function cS = set.diameter(cS,d)
      cS.V = cS.V * (d/cS.diameter);
    end
    
    function fA = get.faceArea(cS)
      fA = zeros(size(cS.F,1),1);
      for i = 1:length(fA)
        VId = cS.F(i,:); VId = VId(~isnan(VId));
        fA(i) = polyArea(cS.V(VId));
      end
    end
    
    function fC = get.faceCenter(cS)
      fC = vector3d.zeros(size(cS.F,1),1);
      for i = 1:length(fC)
        if any(~isnan(cS.F(i,:)))
          VId = cS.F(i,:); VId = VId(~isnan(VId));
          fC(i) = centroid(cS.V(VId));
        else
          fC(i)=nan;
        end
      end
    end
    
    function cSVol = get.volume(cS) 
     % get the volume of the shape
     cSVol = 1/3*sum( ...
             dot(cS.faceCenter,normalize(unique(vector3d(symmetrise(cS.N)),'stable'))) ...
             .*cS.faceArea);
    end

    function E = get.E(cS)
      F = cS.F.'; F = F(:);
      E = [F(1:end-1),F(2:end)];
      E = E(~any(isnan(E),2),:);
      E = unique(sort(E,2),'rows');
    end

  end

  methods (Static = true)
  
    function cS = cube(cs)
      % a very simple cube crystal
      cS = crystalShape(Miller({1,0,0},cs,'hkl'));
      
    end
    
    function cS = hex(cs)
      % a very simple hex crystal
      cS = crystalShape(Miller({1,0,0},{0,0,2},cs,'hkil'));
      
    end

    function cS= tetr(cs)
        % a very simple tetragonal crystal
        cS = crystalShape(Miller({1,0,0},{0,0,1},cs,'hkl'));
    end
            
    function demo
      
      % import some data
      CS = crystalSymmetry('622',[3,3,4.7],'x||a','mineral','Titanium (Alpha)');

      fname = fullfile(mtexDataPath,'EBSD','titanium.txt');
      ebsd = EBSD.load(fname, 'CS', CS,...
        'ColumnNames', {'phi1' 'Phi' 'phi2' 'phase' 'ci' 'iq' 'sem_signal' ...
        'x' 'y' 'grainId'});

      % compute grains
      grains = calcGrains(ebsd('indexed'));
      grains = smooth(grains,4);

      % plot the grain boundary
      plot(grains.boundary,'micronbar','off','figSize','large')

      % use quartz crystals 
      cS = crystalShape.apatite;
      %cS = crystalShape.hex(ebsd.CS);
      
      % and plot them 
      hold on
      plot(grains,0.6 * cS,'DisplayName','Titanium','colored')
      hold off

    end
    
    function demo2
      cS  = crystalShape.quartz;
      cs = cS.CS;
      ori = orientation.rand(200,cs);
      
      plotSection(ori,0.6*(ori*cS),'sigma','sections',8)
      hold on
      %plotSection(ori,0.6*(ori*cS(cs.aAxisRec)),'sigma','sections',8,'faceColor','red')
      plotSection(ori,0.6*(ori*cS(cS.N(2).symmetrise)),'sigma','sections',8,'faceColor',[1 0.7 0.7])     
      hold off
      
    end
  end
    
end
