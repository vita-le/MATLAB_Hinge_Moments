%% Script to evaluate Roskam Method for Preliminary estimation of 
%% Hinge moment coefficient


% Collect geometry data ---------------------------------------------------

run("Geometry.m")
addpath('Roskam_Models')


%  Set Flight conditions --------------------------------------------------

Mach = 0.75;                                % Mach number [-]
Altitude = 10000;                           % Altitude    [m]
[T, P, rho, a, mu] = ISAfunction(Altitude); % Obtain altitude properties
V = Mach * a;                               % Air Speed   [m/s]

q_f = 0.5 * rho * V^2;                      % Dynamic Pressure [Kg/(m*s2)]

alpha = 3;                                  % Angle of attack    [deg]
delta = 5;                                  % Aileron Deflection [deg]


% Estimation of Hinge moment using Roskam methods -------------------------

[Ch, Ch_alpha, Ch_delta] = Roskam_Function(alpha, delta, Mach, AR, Lambda_c4, Lambda_hl);
               
Hinge_Moment = q_f * S_f * c_f_bar * Ch     % Hinge Moment [Nm]