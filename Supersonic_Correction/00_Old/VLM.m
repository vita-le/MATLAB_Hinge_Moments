% The following script executes a VLM to study the aerodynamic properties
% of a finite swept wing connecting to the Roskam Estimations

addpath('00_Old\F-35\')

% ----------------------------------------------------------------------- %
%% Grid Configuration

npx = 2;                                                                   % Number of panels in the streamwise direction
npy = 8;                                                                   % Number of panels in the SEMI-spanwise direction
Num_panels = npx*npy;

% ----------------------------------------------------------------------- %
%% Flight Conditions
% using selected V and rho in Roskam

Uinf  = Flight.V;                                                          % Wind Speed (m/s) assuming a reasonable value
rho   = Flight.rho;                                                        % Air Density (kg/m3)

% Angle of Attack (rad)
% creating a vector with different angles of attack to repeat the same
% experiment at different angles

Num_alpha = 11;                                                            % number of angles investigated
alpha_vector = zeros(Num_alpha,1);                                         % preallocating the vector

for ll = 2 : Num_alpha
    alpha_vector(ll) =  (ll-1) * pi/180;
end

AoA_index = 2 ;                                                            % index for the angle considerated 2 deg in this case to compare roskam

% ----------------------------------------------------------------------- %
%% Wing Geometry


Ale = deg2rad(Geometry.Lambda);              % Leading edge sweep angle (rad)
phi = deg2rad(Geometry.Gamma);                % Dihedral angle [rad] 
cr  = Geometry.c_root;                       % Root chord (m)
ct  = Geometry.c_tip;                       % Tip chord (m)
S   = Geometry.S;                       % Wing surface (m)
b   = Geometry.b;                       % wingspan (m)
AR  = Geometry.AR;                    % Wing Aspect Ratio (-)
TR  = Geometry.TR;                    % taper ratio

% geometrically calculate the backsweep Angle

Ale_back = atan(2/b * (cr - (b/2 * tan(Ale) + ct)) ); % [rad]

%% PANELS GRID 

% Function used to generate the panels structure over the wing
[x_GP, y_GP, z_GP, MAC, MAC_mid, dx, dy] = Grid_Points(npx, npy, cr, b, Ale, Ale_back, phi);

% Plotting grid points for the right side
hold on
h_grid = scatter3(x_GP(:), y_GP(:), z_GP(:), 30, 'b', 'filled'); % Right grid points
grid on; 

% Plotting left side grid points (no legend)
scatter3(x_GP(:), -y_GP(:), z_GP(:), 30, 'b', 'filled');

% Right grid lines
for i = 1:size(z_GP, 1)
    plot3(x_GP(i,:), y_GP(i,:), z_GP(i,:), 'k-'); % Horizontal lines
end
for j = 1:size(z_GP, 2)
    plot3(x_GP(:,j), y_GP(:,j), z_GP(:,j), 'k-'); % Vertical lines
end

% Left side grid lines
for i = 1:size(z_GP, 1)
    plot3(x_GP(i,:), -y_GP(i,:), z_GP(i,:), 'k-'); % Horizontal lines
end
for j = 1:size(z_GP, 2)
    plot3(x_GP(:,j), -y_GP(:,j), z_GP(:,j), 'k-'); % Vertical lines
end

title('ISOMETRIC VIEW OF THE WING')
xlabel('X [m]')
ylabel('Y [m]')
zlabel('Z [m]')

axis equal

%% BOUND AND CONTROL POINTS

% Now we calculate the bound vortex points and control points
[x_BP, y_BP, z_BP, x_CP, y_CP, z_CP] = BP_and_CP(x_GP, y_GP, z_GP, dx, dy, phi, MAC, MAC_mid, npx, npy);

% Plot bound vortex points for the right side
h_bound = scatter3(x_BP(:), y_BP(:), z_BP(:), 50, 'g', 'filled'); % Right bound vortex points

% Left bound points (no legend)
scatter3(x_BP(:), -y_BP(:), z_BP(:), 50, 'g', 'filled');

% Plot control points for the right side
h_control = scatter3(x_CP(:), y_CP(:), z_CP(:), 50, 'r', 'filled'); % Right control points

% Left control points (no legend)
scatter3(x_CP(:), -y_CP(:), z_CP(:), 50, 'r', 'filled'); 

% Create legend only for right-side elements
legend([h_grid, h_bound, h_control], {'Grid Points', 'Bound Vortex Points', 'Control Points'});



view(3) % to see the figure in prospective

%--------------------------------------------------------------------------
%% VELOCITY COMPONENTS and COEFFICIENTS MATRIX 

% we use the function created to generate the matrix of coefficients,
% obtained after the velocities induced by each vortex on every control
% point

[C_coeff, panels] = C_MATRIX(npx, npy, phi, x_BP, y_BP, z_BP, x_CP, y_CP, z_CP);

% now we have obtained the matrix C and a structure 'panels' wich contains
% the coefficients derived from the induced velocity of every panel on each
% control point


%% CALCULATING LIFT

% to apply the bound conditions let's first caluclate the vector B

B = ones(Num_panels, Num_alpha);

for kk = 1 : Num_alpha

    B(:,kk) = - Uinf * sin(alpha_vector(kk)) * cos(phi) * ones(Num_panels,1); % we do it for every angle of attack

end

% since C*Gamma = B we can now revert the system and obtain Gamma, the vector
% containing the intensity of every vortex 

Gamma = C_coeff \ B ;

% using the Kutta-Joukiwski theorem we calculate the total lift

Lift = 2 * rho * Uinf * sum(Gamma * dy);

% and the lift coefficient adimentionalized with the wing surface area

CL = Lift / (0.5 * rho * Uinf^2 * S);


%--------------------------------------------------------------------------
%% LIFT SPANWISE DIRECTION PLOTTING

% to obtain the lift distrbution we apply the same procedure as before for
% the apecific angle of attack and for each section in the span-wise
% direction

% Gamma

Gamma_plot1 = Gamma(:, AoA_index);                       % vector of all npx*npy gamma at 1 deg

Gamma_Matrix = reshape(Gamma_plot1, npy, npx)';          % arrange the vecor a matrix to higlight the columns

Gamma_Plot2 = zeros(npy,1);

for ii = 1 : npy

    Gamma_Plot2(ii) = sum(Gamma_Matrix(:,ii));  % sum of the columns to obtain the total gamma for each span-wise section
end

% Lift

Lift_Plot = zeros(npy, 1);

for kk = 1 : npy
    
    Lift_Plot(kk) = rho * Uinf * ((Gamma_Plot2(kk)) * dy); % lift calculations for each section

end

% Lift Coeeficient

CL_Plot = zeros(npy,1);

for jj = 1 : npy

    CL_Plot(jj) = Lift_Plot(jj) ./ (0.5 * rho * Uinf^2 * MAC_mid(jj));

end

% now we can plot the lift and the lift coefficient in the span-wise
% direction

b_plot = linspace(0,b/2,npy); % half span that will be doubled later for the symmetrical plot 

figure 
plot(b_plot, CL_Plot, 'LineWidth', 1.25, 'Color', 'b')
grid on
hold on
plot(-b_plot, CL_Plot, 'LineWidth', 1.25, 'Color', 'b')
title('LIFT COEFFICIENT IN THE SPAN-WISE DIRECTION')
xlabel('Span, b [m]')
ylabel('CL [-]')

figure 
plot(b_plot, Lift_Plot, 'LineWidth', 1.25, 'Color','b')
grid on
hold on
plot(-b_plot, Lift_Plot, 'LineWidth', 1.25, 'Color' , 'b')
title('LIFT DISTRIBUTION OVER THE SPAN')
xlabel('Span, b [m]')
ylabel('Lift [N]')

%--------------------------------------------------------------------------
%% Cl-alpha

% now we want to plot the Cl over the angle of attack
hold off

figure
plot(alpha_vector, CL, LineWidth=1.25)
title('LIFT COEFFICIENT OVER ANGLE OF ATTACK')
xlabel('Angle of attack, alpha [rad]')
ylabel('CL [-]')
grid on


%and calculating the slope
slope = (CL(end) - CL(1) ) / (alpha_vector(end) - alpha_vector(1));



% ----------------------------------------------------------------------- %
%% Cl vs AR (Aspect Ratio)

hold off

% Vary the Aspect Ratio (AR) by changing the wingspan (b) but keeping the surface area (S) constant

AR_values = linspace(1, 20);         % Aspect ratio values that will be used for the plot
CL_AR = zeros(length(AR_values), 1); % Preallocate CL 

for i = 1 : length(AR_values)
   
    S_AR = b^2 / AR_values(i);                                       % Calculate Surface for the choosen AR
    cr_AR = S_AR / b * (3/2) * (1 + TR)/(1 + TR + TR^2);             % new root cord 
    Ale_back_AR = atan(2/b * (cr_AR - (b/2 * tan(Ale) + cr_AR/TR)) );   % new back sweep


    % lets run all preious steps for each AR

    [x_GP_AR, y_GP_AR, z_GP_AR, MAC_AR, MAC_mid_AR, dx_AR, dy_AR] = Grid_Points(npx, npy, cr_AR, b, Ale, Ale_back_AR, phi); % grid
    [x_BP_AR, y_BP_AR, z_BP_AR, x_CP_AR, y_CP_AR, z_CP_AR] = BP_and_CP(x_GP_AR, y_GP_AR, z_GP_AR, dx_AR, dy_AR, phi, MAC_AR, MAC_mid_AR, npx, npy); % bound and control
    [C_coeff_AR, ~] = C_MATRIX(npx, npy, phi, x_BP_AR, y_BP_AR, z_BP_AR, x_CP_AR, y_CP_AR, z_CP_AR); % matrix
    

    Gamma_AR = C_coeff_AR \ B(:, AoA_index);          % Solve for Gamma for the current AR
    Lift_AR = 2 * rho * Uinf * sum(Gamma_AR * dy_AR); % Calculate lift for the current AR
    CL_AR(i) = Lift_AR / (0.5 * rho * Uinf^2 * S_AR);    % Calculate CL for the current AR

end


% Plot Cl total vs Aspect Ratio

figure
plot(AR_values, CL_AR, 'LineWidth', 1.25)
xlim([1 20])
grid on
title('LIFT COEFFICIENT vs ASPECT RATIO')
xlabel('Aspect Ratio (AR) [-]')
ylabel('CL [-]')

% ----------------------------------------------------------------------- %
%% Cl vs Sweep (Leading Edge Sweep Angle)

sweep_values = linspace(20 * pi/180, 45 * pi/180); % Sweep angles for the plot (in rad)
CL_sweep = zeros(length(sweep_values), 1); % Preallocate CL 

for i = 1:length(sweep_values)

    Ale_sweep = sweep_values(i);                                     % Sweep angle
    Ale_back_sweep = atan(2/b * (cr - (b/2 * tan(Ale_sweep) + ct))); % Calculate back sweep
    
    % run again the procedure
    [x_GP_sweep, y_GP_sweep, z_GP_sweep, MAC_sweep, MAC_mid_sweep, dx_sweep, dy_sweep] = Grid_Points(npx, npy, cr, b, Ale_sweep, Ale_back_sweep, phi); % grid
    [x_BP_sweep, y_BP_sweep, z_BP_sweep, x_CP_sweep, y_CP_sweep, z_CP_sweep] = BP_and_CP(x_GP_sweep, y_GP_sweep, z_GP_sweep, dx_sweep, dy_sweep, phi, MAC_sweep, MAC_mid_sweep, npx, npy); % bound and control points
    [C_coeff_sweep, ~] = C_MATRIX(npx, npy, phi, x_BP_sweep, y_BP_sweep, z_BP_sweep, x_CP_sweep, y_CP_sweep, z_CP_sweep); % C matrix

    Gamma_sweep = C_coeff_sweep \ B(:, AoA_index);             % Solve for Gamma for the current sweep
    Lift_sweep = 2 * rho * Uinf * sum(Gamma_sweep * dy_sweep); % Calculate lift for the current sweep
    CL_sweep(i) = Lift_sweep / (0.5 * rho * Uinf^2 * S);       % Calculate CL for the current sweep angle

end

% Plot Cl vs Sweep Angle
figure
plot(sweep_values, CL_sweep, 'LineWidth', 1.25)
xlim([0.35 0.75])
grid on
title('LIFT COEFFICIENT vs SWEEP ANGLE')
xlabel('Sweep Angle [rad]')
ylabel('CL [-]')

% ----------------------------------------------------------------------- %
%% Cl vs Dihedral Angle

dihedral_values = linspace(1 * pi/180, 55 * pi/180); % Dihedral angles to test (in radians)
CL_dihedral = zeros(length(dihedral_values), 1); % Preallocate CL storage

for i = 1:length(dihedral_values)
    
    phi_dihedral = dihedral_values(i);  % Dihedral angle
    
    % run same procedure
    [x_GP_dihedral, y_GP_dihedral, z_GP_dihedral, MAC_dihedral, MAC_mid_dihedral, dx_dihedral, dy_dihedral] = Grid_Points(npx, npy, cr, b, Ale, Ale_back, phi_dihedral);
    [x_BP_dihedral, y_BP_dihedral, z_BP_dihedral, x_CP_dihedral, y_CP_dihedral, z_CP_dihedral] = BP_and_CP(x_GP_dihedral, y_GP_dihedral, z_GP_dihedral, dx_dihedral, dy_dihedral, phi_dihedral, MAC_dihedral, MAC_mid_dihedral, npx, npy);
    [C_coeff_dihedral, ~] = C_MATRIX(npx, npy, phi_dihedral, x_BP_dihedral, y_BP_dihedral, z_BP_dihedral, x_CP_dihedral, y_CP_dihedral, z_CP_dihedral);

    B_dihedral = - Uinf * sin(alpha_vector(AoA_index)) * cos(phi_dihedral) * ones(Num_panels,1);
    Gamma_dihedral = C_coeff_dihedral \ B_dihedral;                % Solve for Gamma for current phi
    Lift_dihedral = 2 * rho * Uinf * sum(Gamma_dihedral * dy_dihedral); % Calculate lift for current phi
    CL_dihedral(i) = Lift_dihedral / (0.5 * rho * Uinf^2 * S);          % Calculate CL for the current dihedral angle
end

% Plot Cl vs Dihedral Angle
figure
plot(dihedral_values, CL_dihedral, 'LineWidth', 1.25)
xlim([0.1 0.9])
grid on
title('LIFT COEFFICIENT vs DIHEDRAL ANGLE')
xlabel('Dihedral Angle [rad]')
ylabel('CL [-]')


%% display values

fprintf('Velocity [m/s] :  %.2f \n', Uinf);
fprintf('AoA [deg] :  %.3f \n', alpha_vector(AoA_index) * 180 / pi);
fprintf('Lift [N] :  %.1f \n', Lift(AoA_index));
fprintf('CL [-] :  %.4f \n', CL(AoA_index));
fprintf('slope CL/alpha [-] :  %.3f \n', slope);