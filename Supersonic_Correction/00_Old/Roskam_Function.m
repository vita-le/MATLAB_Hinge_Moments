function [Ch, Ch_alpha, Ch_delta] = Roskam_Function(alpha, delta, Mach, AR, Lambda_c4, Lambda_hl)

% Roskam Method to estimate Hinge Moment Coefficient

% INPUTS ------------------------------------------------------------------

% alpha                   % Angle of attack       (deg)
% delta                   % Aileron Deflection    (deg)
% Mach                    % Mach Number 
% AR                      % Aspect Ratio
% Lambda_c4               % Sweep at 1/4 of chord (rad)
% Lambda_hl               % Sweep at Hinge line   (rad)

% delta_t = 0;            % Trim Tab Deflection   (rad)

% Extra 
Ch0 = 0;                  % For Symmetrical profiles

%--------------------------------------------------------------------------

% cb = 0.05; % Esempio: corda del bilanciamento
% cf = 0.25; % Esempio: corda totale della superficie
% t = 0.02;  % Spessore del profilo alla linea di cerniera

% 2. Calcolate Balance Ratio (BR)
% BR = sqrt((cb/cf)^2 - (t/(2*cf))^2); 

%% 3. Coefficient with respect to angle of attack (Ch_alpha) --------------

% Note Needs interpolation to get this values

Cha_theory = -0.012; % From Plots
Cha_balance = Cha_theory * 0.9; % Example balance value

% Mach Correction
ChaM = Cha_balance / sqrt(1 - Mach^2); 

% Correction term delta_Cha (From Plots)
delta_Ch_a = 0; 

% Final Formula

Ch_alpha = (AR * cos(Lambda_c4)) / (AR + 2 * cos(Lambda_c4)) * ChaM + delta_Ch_a;

%% 4. Coefficient with respect to deflection delta (Ch_delta) -------------

% 2D Mach Corrected Value
Chd_theory = -0.015; 
Chd_balance = Chd_theory * 0.85; 
ChdM = Chd_balance / sqrt(1 - Mach^2);

% Parameter (Surface effectiveness)
alpha_delta = 0.5; % From Plots vs deflection

% Collective term Chd
delta_Chd = 0;

% Final Formula
Ch_delta = cos(Lambda_c4) * cos(Lambda_hl) * (ChdM + alpha_delta * ChaM * ...
      (2 * cos(Lambda_c4) / (AR + 2 * cos(Lambda_c4))) + delta_Chd);

%% 5. Calcolo Finale Coefficiente Ch
% Equazione generale[cite: 633]:
% Ch = Ch0 + Cha * alpha + Chd * delta + Chdt * deltat
Ch = Ch0 + Ch_alpha * alpha + Ch_delta * delta;

end
