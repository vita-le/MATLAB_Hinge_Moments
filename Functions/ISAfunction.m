function [T, P, rho, a, mu, liuID1, liuID2] = ISAfunction(Z)
% ISA function - Include a brief description here.   
%
% Synopsis
%   [T P rho a mu liuid1 liuid2] = ISAfunction(Z)
%
% Description
%   Implementing a function that can calculate temperature, pressure,
%   density,speed of sound and viscosity with the right approximations
%   after being given an altitude
%
% Inputs ([]s are optional)
%   (scalar or vector) Z      Geometric altitude in [m]
%
% Outputs ([]s are optional)
%   (scalar or vector) T      Temperature, K
%   (scalar or vector) P      Pressure, Pa
%   (scalar or vector) rho    Density, kg/m^3
%   (scalar or vector) a      Sound speed, m/s
%   (scalar or vector) mu     Dynamic viscosity, kg/(m s)
%
% Reference material:
%   US standard atmosphere 1976
%
% Authors
  liuID1 = "andvi311";  % Andrea Vitale
  liuID2 = "matbu673";  % Mattia Buscemi

% License
%   This program is part of an academic exercise for the course TMAL02,
%   Linköping University, year 2024. The program is therefore free for 
%   non-commercial academic use.
%
%% The executable code starts here:
% Define constants and reference values
    
    g0 = 9.80665; % gravitational constant [m/s^2]
    R = 8.31432 ; % gas constant [N*m/mol*K]
    M0 = 0.0289644 ; % molar mass of air [Kg/mol]
    bs = 1.458 * 10^-6 ; % constant [Kg / s * m * K^1/2]
    y0 = 1.4 ; % ratio cp/cv
    S = 110.4 ; % Sutherland's constant [K]
    Hb = [0, 11, 20, 32, 47, 51, 71, 84.852] .* 10^3 ; % reference levels [m];
    Lmb = [-6.5, 0, 1, 2.8, 0, -2.8, -2] .* 10^-3; %temperature gradients
    T0 = 288.15; % reference temperature at sea level [K]
    P0 = 1.01325 * 10^5 ; % reference pressure at sea level [N/m^2]
    r0 = 6.356766 * 10^6; % earth radius [m] 
    
    
% How many input values do we have? 

    nInput = length(Z); 
    
% The input values come in geometrical altitude, we need to
% convert them
   
    H = (r0 .* Z) ./ (r0 + Z);

% approximation for results

format shortg

% Let's create the vector Tb, reference temperature for each level

Tb = zeros(1, 8);
Tb(1) = T0; 
Tb(2) = Tb(1) + Lmb(1) * Hb(2); 
Tb(3) = Tb(2); 
Tb(4) = Tb(3) + Lmb(3) * (Hb(4) - Hb(3));
Tb(5) = Tb(4) + Lmb(4) * (Hb(5) - Hb(4));
Tb(6) = Tb(5);
Tb(7) = Tb(6) + Lmb(6) * (Hb(7) - Hb(6));
Tb(8) = Tb(7) + Lmb(7) * (Hb(8) - Hb(7));

% same  procedure for the reference pressure levels Pb

Pb = zeros(1,8);
Pb(1) = P0;
Pb(2) = P0 * (Tb(1) / ( Tb(1) + Lmb(1) * Hb(2) ))^( (g0*M0) / (R*Lmb(1)) );
Pb(3) = Pb(2) * exp( (- g0 * M0 * (Hb(3) - Hb(2)) ) / (R * Tb(2)) );
Pb(4) = Pb(3) * (Tb(3) / ( Tb(3) + Lmb(3) * (Hb(4) - Hb(3)) ))^( (g0*M0) / (R*Lmb(3)) );
Pb(5) = Pb(4) * (Tb(4) / ( Tb(4) + Lmb(4) * (Hb(5) - Hb(4)) ))^( (g0*M0) / (R*Lmb(4)) );
Pb(6) = Pb(5) * exp( (- g0 * M0 * (Hb(6) - Hb(5)) ) / (R * Tb(5)) );
Pb(7) = Pb(6) * (Tb(6) / ( Tb(6) + Lmb(6) * (Hb(7) - Hb(6)) ))^( (g0*M0) / (R*Lmb(6)) );
Pb(8) = Pb(7) * (Tb(7) / ( Tb(7) + Lmb(7) * (Hb(8) - Hb(7)) ))^( (g0*M0) / (R*Lmb(7)) );

% If instead
% of a single value, the input contains multiple values, we will need to
% make a loop so the equations are applied to each one of those inputs.
% Let's make a loop as long as the number of inputs we counted before

   
    for j = 1:nInput
        
        % Now that we are inside the loop, for each one of the inputs, we
        % need to identify the right layer and apply the right equations.
        
        if Hb(1) <= H(j)&& H(j) < Hb(2)

            T(j) = Tb(1) + Lmb(1) * (H(j) - Hb(1));

            P(j) = P0 * (Tb(1) / ( Tb(1) + Lmb(1) * (H(j) - Hb(1)) ))^( (g0*M0) / (R*Lmb(1)) );


        elseif Hb(2) <= H(j) && H(j) < Hb(3)

            T(j) = Tb(2) + Lmb(2) * (H(j) - Hb(2));

            P(j) = Pb(2) * exp( (- g0 * M0 * (H(j) - Hb(2)) ) / (R * Tb(2)) );


        elseif Hb(3) <= H(j) && H(j) < Hb(4)

            T(j) = Tb(3) + Lmb(3) * (H(j) - Hb(3));

            P(j) = Pb(3) * (Tb(3) / ( Tb(3) + Lmb(3) * (H(j) - Hb(3)) ))^( (g0*M0) / (R*Lmb(3)) );


        elseif Hb(4) <= H(j) && H(j)  < Hb(5)

            T(j) = Tb(4) + Lmb(4) * (H(j) - Hb(4));

            P(j) = Pb(4) * (Tb(4) / ( Tb(4) + Lmb(4) * (H(j) - Hb(4)) ))^( (g0*M0) / (R*Lmb(4)) );


        elseif Hb(5) <= H(j) && H(j) < Hb(6)

            T(j) = Tb(5) + Lmb(5) * (H(j) - Hb(5));

            P(j) = Pb(5) * exp( (- g0 * M0 * (H(j) - Hb(5)) ) / (R * Tb(5)) );


        elseif Hb(6) <= H(j) && H(j) < Hb(7)

            T(j) = Tb(6) + Lmb(6) * (H(j) - Hb(6));

            P(j) = Pb(6) * (Tb(6) / ( Tb(6) + Lmb(6) * (H(j) - Hb(6)) ))^( (g0*M0) / (R*Lmb(6)) );


        elseif Hb(7) <= H(j) && H(j) < Hb(8)

            T(j) = Tb(7) + Lmb(7) * (H(j) - Hb(7));

            P(j) = Pb(7) * (Tb(7) / ( Tb(7) + Lmb(7) * (H(j) - Hb(7)) ))^( (g0*M0) / (R*Lmb(7)) );

        end
   
        % We are still inside the main loop. Now that we have calculated 
        % the "primary" properties for this step, we can use them to 
        % calculate the rest of the properties

        rho(j) = (P(j) * M0) / (R * T(j)) ;

        a(j) = sqrt( y0 * R * T(j)/ M0);

        mu(j) = bs * ( T(j) ^ (3/2) ) / ( T(j) + S ) ;

       
       
    end


end
