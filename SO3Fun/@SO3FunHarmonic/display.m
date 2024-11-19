function display(SO3F,varargin)
% standard output

if check_option(varargin,'skipHeader')
  disp(strong("  harmonic component"));
else
  displayClass(SO3F,inputname(1),[],'moreInfo',symChar(SO3F),varargin{:});
  if SO3F.antipodal, disp('  antipodal: true'); end
  if ~SO3F.isReal, disp('  isReal: false'); end
  if length(SO3F) > 1, disp(['  size: ' size2str(SO3F)]); end
end

disp(['  bandwidth: ' num2str(SO3F.bandwidth)]);

if isscalar(SO3F) 
  disp(['  weight: ' xnum2str(mean(SO3F))]);
elseif length(SO3F)<4
  disp(['  weights: [' xnum2str(mean(SO3F)),']']);
else
  disp(['  weight: ' xnum2str(mean(mean(SO3F))) ]);
end

disp(' ');

end
