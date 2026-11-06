function [x_GP, y_GP, z_GP, MAC, MAC_mid, dx, dy] = Grid_Points(npx, npy, cr, b, Ale, Ale_back, phi)

% function used to generate the grid intersection points coordinates
% starting from a choosen 2D geometry and grid 

% INPUTS

% npx      =   number of panels rows
% npy      =   number of panels columns
% cr       =   root cord
% Ale      =   swept angle
% Ale_back =   back sweep angle
% phi      =   dihedral angle
% b        =   wing span

% OUTPUTS

% x_GP     =   x coordinates for grid points
% y_GP     =   y coordinates for grid points
% z_GP     =   z coordinates for grid points
% MAC      =   mean aerodynamic chord for each section
% MAC_mid  =   mean aerodynamic chord halfway in the panel span.wise
% dx       =   root  'segment'
% dy       =   upper 'segment'

%--------------------------------------------------------------------------
%% CODE

dx = cr / npx ;
dy = b/2 * 1/npy ; 

% Mean aerodynamic chord (MAC) for each section of the grid

MAC = zeros(1,npy+1);
MAC(1) = cr;           % starting from the root chord

for i = 2 : (npy + 1)

    MAC(i) = MAC(i-1) - dy * tan(Ale) - dy * tan(Ale_back);

end

% MAC for each section at the middle point of each panel

MAC_mid = zeros(1,npy);
MAC_mid(1) = cr - dy/2 * tan(Ale) - dy/2 * tan(Ale_back); 

for i = 2 : (npy)

    MAC_mid(i) = MAC_mid(i-1) - dy * tan(Ale) - dy * tan(Ale_back);

end

% now we calculate the x coordinates of each point on the grid

x_GP = zeros(npx+1, npy+1);

for i = 1 : (npx + 1)
  
    for j = 1 : (npy +1)

        if i==1 && j ~=1

            x_GP(i,j) = x_GP(i,j-1) + dy * tan(Ale);

        elseif j == 1 && i ~=1

            x_GP(i,j) = x_GP(i-1,j) + dx;

        elseif i ~=1 &&  j ~= 1
            x_GP(i,j) = x_GP(i-1, j) + MAC(j) / npx;
           
        end
  
    end

end

% and now we compute the y component of each point

y_GP = zeros(npx+1, npy+1);


for i = 1 : (npx + 1)
  
    for j = 2 : (npy +1)

        y_GP(i,j) = y_GP(i, j-1) + dy*cos(phi);

    end
end

% and now we compute the z component of each point

z_GP = zeros(npx+1, npy+1);


for i = 1 : (npx + 1)
  
    for j = 2 : (npy +1)

        z_GP(i,j) = z_GP(i, j-1) + dy  * cos(phi)* tan(phi);

    end
end


end

