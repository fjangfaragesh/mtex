function ori = exp(ori,v,varargin)
% exponential function
%
% Syntax
%   ori_2 = exp(ori_1,v)
%   ori_2 = exp(ori_1,S)
%
% Input
%  ori_1 - @orientation
%  v     - @vector3d axis of rotation scaled by the angle of rotation
%  S     - skew symmetry @tensor
%
% Output
%  ori_2 - @orientation rotate ori_1 about axis v with angle norm(v) 

if isa(v,'tensor')
   
  % make sure T is an antisymmetric tensor
  v = antiSym(v);
  
  % form the gradient vector
  v = vector3d(v{3,2},-v{3,1},v{2,1});
  v =  reshape(v,size(ori));
end

% compute the orientation
if isa(v,'SO3TangentVector')
  tS = v.tangentSpace;
else
  tS = SO3TangentSpace.extract(varargin{:});
end

if tS.isLeft
  ori = times(expquat(v),ori,true);
else
  ori = times(ori,expquat(v),false);
end

end