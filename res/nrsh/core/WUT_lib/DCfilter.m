function [DCflt] = DCfilter(Nx,Ny,q_center_filter)
%   DCflt function generates DC filter to cover DC term
%   Nx - X size of reconstructed hologram
%   Ny - Y size of reconstructed hologram
%   q_center_filter - parameter defining size of the filter
% -------------------------------------------------------------------------
% Code developed by Tomasz Kozacki*, Weronika Zaperty*, Hyon-Gon Choo**
%
% *
% Institute of Micromechanics and Photonics
% Faculty of Mechatronics
% Warsaw University of Technology
% 
% **
% Electronics and Telecommunications Research Institute
% 1110-6 Oryong-dong, Buk-gu, Kwangju, Korea Po³udniowa
% 
% Contact: t.kozacki@mchtr.pw.edu.pl
% -------------------------------------------------------------------------
% Copyright (c) 2019, Warsaw University of Technology
% All rights reserved.
%                                                            
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% 1. Redistribution and use in source and binary forms, with or without
% modification, are permitted for standardization and academic purpose only
% 
% 2. Redistributions of source code must retain the above copyright notice, this
%   list of conditions.
% 
% 3. Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions in the documentation and/or other materials
%   provided with the distribution
% 
% -------------------------------------------------------------------------

if nargin < 2
     error('ktzerror: bad parametter')
elseif nargin == 2
    q_center_filter = 0.1;
end
if q_center_filter > 1 || q_center_filter < 0,  error('ktzerror: bad parametter'), end
    
Nx_filter = 2*round(q_center_filter*Nx/2); Ny_filter = 2*round(q_center_filter*Ny/2);
q = 0.7;
Nwx = round(Nx_filter*q/2); filterx = (1:Nwx)/Nwx;
filterx = [filterx,ones(1,Nx_filter-2*Nwx),fliplr(filterx)];
Nwy = round(Ny_filter*q/2); filtery = (1:Nwy)/Nwy;
filtery = [filtery,ones(1,Ny_filter-2*Nwy),fliplr(filtery)];

DCflt = ones(Ny,Nx);
DCflt(Ny/2+1-Ny_filter/2:Ny/2+Ny_filter/2, Nx/2+1-Nx_filter/2:Nx/2+Nx_filter/2) = 1- filtery.'*filterx;
end

