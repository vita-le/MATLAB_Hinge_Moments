function [x_BP, y_BP, z_BP, x_CP, y_CP, z_CP] = BP_and_CP(x_GP, y_GP, z_GP, dx, dy, phi, MAC, MAC_mid, npx, npy)

% function used to generate the bound vortex points ( A, B) and the control
% points (C) coordinates

% INPUTS

% npx        =   number of panels rows
% npy        =   number of panels columns
% MAC        =   mean aerodynamic chord for each section
% MAC_mid    =   mean aerodynamic chord halfway in the panel span-wise
% dx         =   root  'segment'
% dy         =   upper 'segment'
% phi        =   dihedral angle [rad]
% (x,y,z)_GP =   grid points coordinates

% OUTPUTS

% (x,y,z)_BP = bound vortex points coordinates
% (x,y,z)_CP = control points coordinates

%% CODE

% Bound points coordinates

% x coordinates

x_BP = x_GP; % first we set the starting points and then we add the 1/4 inrement

x_BP(:,1) = x_GP(:,1) + 1/4 * dx;

x_BP(npx+1, :) = [];

for i = 1 : (npx)

    for j = 2 : (npy+1)

    x_BP(i,j) = x_GP(i,j) + MAC(j)/npx * 1/4 ;
    
    end

end

% y coordinates

y_BP = y_GP;
y_BP(npx+1,:) = []; % we remove the last row 

% z coordinates

z_BP = z_GP;
z_BP(npx+1,:) = []; % we remove the last row

%--------------------------------------------------------------------------
%% now it's time to define the control points

% x coordinates

x_CP = zeros(npx,npy);

for i = 1 : npx
    for j = 1 : npy

             x_CP(i,j) = x_GP(i,j) + ( x_GP(i,j +1) - x_GP(i,j) ) / 2 + (MAC_mid(j) * 3/4 )/npx ;
       
    end
end

% y coordinates

y_CP = zeros(npx, npy);

for i = 1 : npx

    for j = 1 : npy

        y_CP(i,j) = y_BP(i,j) + 0.5 * dy *cos(phi);

    end

end

% z coordinates 

z_CP = zeros(npx, npy);

for i = 1 : npx

    for j = 1 : npy 

        z_CP(i,j) = z_BP(i,j) + 0.5 * dy * cos(phi) * tan(abs(phi));

    end
end


end

