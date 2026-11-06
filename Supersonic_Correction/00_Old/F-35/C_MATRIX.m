function [C_coeff, panels] = C_MATRIX(npx, npy, phi, x_BP, y_BP, z_BP, x_CP, y_CP, z_CP)

% function used to generate the C matrix, strarting from the points
% coordinates

% INPUT
% npx = number of panels on x direction
% npy = number of panels on y direction
% phi = dihedral angle
% (x,y,z)_BP = bound points coordinates
% (x,y,z)_CP = control points coordinates

% OUTPUT
% C_coeff = matrix of (npx*npy) X (npx*npy)*2 elements
% panels = structure used to save values relative to each panel

%--------------------------------------------------------------------------
%% CODE

% to take into account both wings vortices effects, k = 1 implies that we 
% are considering the right wing, and 2 for the left one vortices, then we
% cycle the control points for the vortex of each panel

for k = 1 : 2 


    for i = 1 : npx   % firt pair of loops to choose the panel (or vortex)
        for j = 1 : npy


            if k == 1 % if we are on the right wing

                 A = [x_BP(i,j), y_BP(i,j), z_BP(i,j)];
                 B = [x_BP(i,j+1), y_BP(i,j+1), z_BP(i,j+1)];
                 r_AB = B - A;
                 N = 1 ;

            else % if we are on the left wing

                 B = [x_BP(i,j), - y_BP(i,j), z_BP(i,j)];
                 A = [x_BP(i,j+1), - y_BP(i,j+1), z_BP(i,j+1)];
                 r_AB = B - A;
                 N = 1 ;

            end

            for n = 1 : npx % second pair of loops to choose the control point
                for m = 1 : npy 

                     C = [x_CP(n,m), y_CP(n,m), z_CP(n,m)];
                     r_AC = C - A;
                     r_BC = C - B;

                     % BOUND COMPONENT

                     cross_product = cross(r_AC, r_BC);  
                     norm_cross_product = norm(cross_product);  % |r1 x r2| 

                     FAC1_AB = cross_product / (norm_cross_product^2); % r1xr2 / |r1xr2|^2

                     
                     r_ = r_AC / norm(r_AC) - r_BC / norm(r_BC);
                     r_ = r_';     % trasposing for dot product

                     FAC2_AB = r_AB * r_; 

                     V_BOUND = FAC1_AB * FAC2_AB ;
  
                        if V_BOUND(1,1) < 1e-10 % just to approximate

                        V_BOUND(1,1) = 0;

                        end

                     % LEFT TRAIL 

                     num =  [0, (C(3) - A(3)), (A(2) - C(2))];
                     den = (C(3) - A(3))^2 + (A(2) - C(2))^2 ;
                     FAC1_AD = num / den ;

                     num2 = (C(1) - A(1));  
                     den2 = (norm(r_AC));        
                     FAC2_AD = 1 + num2/den2 ;

                     V_LEFT = FAC1_AD * FAC2_AD;

                     % RIGHT TRAIL

                     num =  [0, (C(3) - B(3)), (B(2) - C(2))];
                     den = (C(3) - B(3))^2 + (B(2) - C(2))^2 ;
                     FAC1_BD = num / den ;

                     num3 = (C(1) - B(1));  
                     den3 = (norm(r_BC));        
                     FAC2_BD = 1 + num3/den3 ;

                     V_RIGHT = - FAC1_BD * FAC2_BD;

                % saving the values and sum to get the total
               
                V_tot = (V_BOUND + V_LEFT + V_RIGHT) / (4*pi); %  divide for 4pi !!

                V_TOT = - V_tot(2) * sin(phi) + V_tot(3) * cos(phi);

                if k == 1

                    panels(i,j).V_TOT_RW(N,1) = V_TOT; % so we save each induced velocity of the considered panel on the control point considered


                else

                    panels(i,j).V_TOT_LW(N,1) = V_TOT;


                end

                N = N + 1; %going for the next control point but staying in the same panel (or vortex)

                end
            end

        end
    end

end

C_coeff = [];

for k = 1:2

   for i = 1 : npx
       for j = 1 : npy

          if k == 1

            C_coeff = [C_coeff  panels(i,j).V_TOT_RW(:,1) ];

          else 

            C_coeff = [C_coeff  panels(i,j).V_TOT_LW(:,1) ];

          end

       end
   end

end
% now we add the left side of the matrix to the right side to get a square matrix
% rapresenting the influence on each control points both sides of the
% vortices, so we can later find the total gamma for each panel

C1 = C_coeff(:, 1: (npx*npy) );

C2 = C_coeff(:, (npx*npy + 1) : (2 * npx*npy));

C_coeff = C1 + C2;

% now we have a sqare matrix where each row rapresents the influence of the
% all vortices on a single control point

end

