function [Cha, Chd, RoskamCoeff] = Hinge_Coeff(Geometry, Airfoil, Flight)
% =========================================================================
% Hinge_Coeff
% Computes hinge moment derivatives Cha and Chd using Roskam models
% =========================================================================

addpath('Roskam_Models')

%% ================== EXTRACT GEOMETRY ====================================

b          = Geometry.b;
lambda_c4  = Geometry.Lambda_c4(1);
lambda_hl  = Geometry.Lambda_hl;
yi         = Geometry.y_i;
yo         = Geometry.y_o;
AR         = Geometry.AR;
c_aileron  = Geometry.c_aileron;
MAC        = Geometry.MAC;
hinge      = Geometry.hinge;

%% ================== EXTRACT AIRFOIL =====================================

t_c        = Airfoil.t_c;
Phi_TE_1   = Airfoil.Phi_TE_1_deg;       % [rad]
Phi_TE_2   = Airfoil.Phi_TE_2_deg;       % [rad]

%% ================== EXTRACT FLIGHT ======================================

M      = Flight.Mach;
delta  = Flight.delta;
Re     = Flight.Re;

%% ================== BASIC DERIVED PARAMETERS =============================

cf = c_aileron * (1 - hinge);     % hinge -> TE
cb = c_aileron * hinge;           % LE -> hinge
cf_ratio = c_aileron / MAC;              % flap ratio w.r.t MAC

eta_i = yi / (b/2);
eta_o = yo / (b/2);

tc = t_c * c_aileron;             % thickness of control surface

%% ================== ---------------- Cha ---------------------------------

Cha_theory = get_ChalphaTheory(cf_ratio, t_c);

Cla_theory = get_ClalphaTheory(t_c);

Phi_TE_AVG = (Phi_TE_1 + Phi_TE_2) / 2; 
Cla_ratio  = get_ClalphaCorrection(tand(Phi_TE_1/2), Re);
Cha1_ratio = get_ChalphaCorrection(cf_ratio, Cla_ratio);
Cha1       = Cha1_ratio * Cha_theory;

% Thickness correction
tol = 1e-2;                                 % Using a mean value with tol to check condition

if abs(t_c - tand(Phi_TE_AVG/2)) < tol
    CHECK = 0;
    Cha2 = Cha1;
else
    warning('t_c different from tan(Phi_TE_AVG/2) with tol = %g', tol);
    CHECK = 1;
    Cha2 = Cha1 + 2 * Cla_theory * (1 - Cla_ratio) * ...
           (tand(Phi_TE_2/2) - t_c);
end

% Balance correction
BR = sqrt((cb/cf)^2 - (tc/(2*cf))^2);
Cha_balance_ratio = get_BalanceEffect_Chalpha(BR,'elliptic');
Cha_balance = Cha2 * Cha_balance_ratio;

% Mach correction
Cha_M = Cha_balance / sqrt(1 - M^2);

% Finite wing correction
term1 = get_AR_Correction_alpha(AR);
B2    = get_B2(cf_ratio, cb/cf);

Kai = get_Ka(eta_i);
Kao = get_Ka(eta_o);

Ka = (Kai*(1-eta_i) - Kao*(1-eta_o)) / (eta_o - eta_i);

Cla = Cla_ratio * Cla_theory;

Delta_Cha = term1 * Cla * B2 * Ka * cosd(lambda_c4);

Cha = (AR*cosd(lambda_c4)) / ...
      (AR + 2*cosd(lambda_c4)) * Cha_M ...
      + Delta_Cha;

%% ================== ---------------- Chd ---------------------------------

a_d = get_ad(delta, cf_ratio);

Chd1_ratio  = get_ChdeltaCorrection(cf_ratio, Cla_ratio);
Chd_theory  = get_ChdeltaTheory(cf_ratio, t_c);
Chd1        = Chd1_ratio * Chd_theory;

Cld_theory  = get_CldeltaTheory(cf_ratio, t_c);
Cld_ratio = get_CldeltaCorrection(tand(Phi_TE_1/2), Cla_ratio);

if CHECK == 0
    Chd2 = Chd1;
else                 
    Chd2 = Chd1 + 2 * Cld_theory * (1 - Cld_ratio) * ...
           (tand(Phi_TE_2/2) - t_c);
end

% Balance correction
Chd_balance_ratio = get_BalanceEffect_Chdelta(BR,'elliptic');
Chd_balance = Chd2 * Chd_balance_ratio;

% Mach correction
Chd_M = Chd_balance / sqrt(1 - M^2);

% Finite wing correction
term2 = get_AR_Correction_delta(AR, cf_ratio);

Kdi = get_Kd(eta_i);
Kdo = get_Kd(eta_o);

Kd = (Kdi*(1-eta_i) - Kdo*(1-eta_o)) / (eta_o - eta_i);

Cld = Cld_ratio * Cld_theory;

Delta_Chd = term2 * Cld * B2 * Kd * cosd(lambda_c4);

Chd = cosd(lambda_c4) * cosd(lambda_hl) * ...
      (Chd_M + a_d * Cha_M * ...
      (2*cosd(lambda_c4)) / (AR + 2*cosd(lambda_c4)) ...
      + Delta_Chd);


RoskamCoeff = struct();

%% ---------------- BASIC DERIVED PARAMETERS ----------------
RoskamCoeff.cf        = cf;
RoskamCoeff.cb        = cb;
RoskamCoeff.cf_ratio  = cf_ratio;
RoskamCoeff.eta_i     = eta_i;
RoskamCoeff.eta_o     = eta_o;
RoskamCoeff.tc        = tc;

%% ---------------- Cha ----------------
RoskamCoeff.Cha_theory        = Cha_theory;
RoskamCoeff.Cla               = Cla;
RoskamCoeff.Cla_ratio         = Cla_ratio; 
RoskamCoeff.Cla_theory        = Cla_theory;
RoskamCoeff.Cha1_ratio        = Cha1_ratio;
RoskamCoeff.Cha1              = Cha1;
RoskamCoeff.Cha2              = Cha2;
RoskamCoeff.BR                = BR;
RoskamCoeff.Cha_balance_ratio = Cha_balance_ratio;
RoskamCoeff.Cha_balance       = Cha_balance;
RoskamCoeff.Cha_M             = Cha_M;
RoskamCoeff.term1             = term1;
RoskamCoeff.B2                = B2;
RoskamCoeff.Kai               = Kai;
RoskamCoeff.Kao               = Kao;
RoskamCoeff.Ka                = Ka;
RoskamCoeff.Delta_Cha         = Delta_Cha;
RoskamCoeff.Cha_final         = Cha;

%% ---------------- Chd ----------------
RoskamCoeff.a_d               = a_d;
RoskamCoeff.Chd1_ratio        = Chd1_ratio;
RoskamCoeff.Chd_theory        = Chd_theory;
RoskamCoeff.Chd1              = Chd1;
RoskamCoeff.Cld_theory        = Cld_theory;
RoskamCoeff.Cld               = Cld;
RoskamCoeff.Cld_ratio         = Cld_ratio;
RoskamCoeff.Chd2              = Chd2;
RoskamCoeff.Chd_balance_ratio = Chd_balance_ratio;
RoskamCoeff.Chd_balance       = Chd_balance;
RoskamCoeff.Chd_M             = Chd_M;
RoskamCoeff.term2             = term2;
RoskamCoeff.Kdi               = Kdi;
RoskamCoeff.Kdo               = Kdo;
RoskamCoeff.Kd                = Kd;
RoskamCoeff.Delta_Chd         = Delta_Chd;
RoskamCoeff.Chd_final         = Chd;

end