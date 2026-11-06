function Geo = GeoInput(ID)

%% ================================================================
% GEOMETRY DATABASE
% To add a new aircraft geometry:
%   1) Copy an IF block
%   2) Change the ID
%   3) Modify the geometry parameters
%
% Important parameters defining the geometry:
%   Geo.nwing      → number of lifting surfaces (wing, tail, canard, etc.)
%   Geo.nelem      → number of spanwise partitions for each surface
%   Geo.startx     → x-coordinates of the leading edge start of each partition
%   Geo.span       → span of each partition
%   Geo.TR         → taper ratio of each partition
%   Geo.Lambda_c4  → quarter-chord sweep angle of each partition
%================================================================

if ID == 18
    
    % =============================================================
    % F/A-18 WITHOUT TAIL
    % =============================================================
    
    Geo.name = 'F/A-18';                 % Aircraft name
    
    
    % ---------------- ROSKAM DATA ----------------
    % Basic aerodynamic geometry parameters
    
    Geo.b = 12.31;                      % Total wingspan [m]
    Geo.S = 37.16;                      % Total wing reference area [m^2]
    
    Geo.Lambda = 35;                    % Leading edge sweep angle [deg]
    
    Geo.c_r = 4.04;                     % Root chord of the wing [m]
    Geo.c_t = 1.68;                     % Tip chord of the wing [m]
    
    Geo.TR_full = Geo.c_t / Geo.c_r;    % Overall wing taper ratio
    
    
    % ---------------- AILERON GEOMETRY ----------------
    
    Geo.S_f = 2.27/2;                   % Area of one aileron [m^2]
    Geo.hinge = 0.25;                   % Hinge line location as fraction of chord
    
    Geo.y_i = 4.03;                     % Inner spanwise location of aileron [m]
    Geo.y_o = 5.87;                     % Outer spanwise location of aileron [m]
    
    Geo.bf = Geo.y_o - Geo.y_i;         % Aileron span [m]
    
    
    % ---------------- TORNADO REFERENCE DATA ----------------
    
    Geo.x_CG = 0;                       % Center of gravity x-coordinate [m]
    Geo.y_CG = 0;                       % Center of gravity y-coordinate [m]
    Geo.z_CG = 0;                       % Center of gravity z-coordinate [m]
    
    Geo.x_ref = 0;                      % Reference point x-coordinate for moments
    Geo.y_ref = 0;                      % Reference point y-coordinate
    Geo.z_ref = 0;                      % Reference point z-coordinate
    
    
    % ---------------- SURFACE DEFINITION ----------------
    
    Geo.nwing = 1;                      % Number of lifting surfaces
    
    Geo.nelem = [2];                    % Number of partitions for each surface
    
    Geo.symetric = [1];                 % 1 = surface mirrored about aircraft centerline
    
    Geo.allmove = [0];                  % 1 = whole surface moves (e.g. stabilator)
    
    
    % Root chord of each lifting surface
    Geo.c_root = [4.04];
    
    
    % Airfoil files used at root and tip
    Geo.Airfoil_root = 'N64210.DAT';
    Geo.Airfoil_tip  = 'N64210.DAT';
    
    
    % ---------------- PANEL DISCRETIZATION ----------------
    % Number of aerodynamic panels used by Tornado
    
    Geo.nx = 3;                         % Number of chordwise panels
    Geo.ny = 7;                         % Number of spanwise panels
    
    Geo.fnx = 2;                        % Chordwise panels on control surface
    Geo.fny = 4;                        % Spanwise panels on control surface
    
    
    % ---------------- WING GEOMETRY ----------------
    
    Geo.startx = [0  (Geo.b/2 - Geo.bf)*tand(Geo.Lambda)];
    % x-coordinate of the leading edge start of each partition
    
    Geo.starty = [0  (Geo.b/2 - Geo.bf)];
    % y-coordinate of the leading edge start of each partition
    
    Geo.startz = [0 0];
    % z-coordinate of the leading edge start of each partition
    
    
    Geo.span = [Geo.b/2 - Geo.bf  Geo.bf];
    % Span of each partition
    
    
    Geo.TR = [2.38/Geo.c_root(1)  Geo.c_t/2.38];
    % Taper ratio of each partition
    
    
    Geo.Lambda_c4 = [20 20];
    % Quarter-chord sweep angle of each partition [deg]
    
    
    Geo.Gamma = -3;                    % Dihedral angle [deg]
    Geo.Twist = 0;                     % Geometric twist angle [deg]
    
    
    % ---------------- CONTROL SURFACES ----------------
    
    Geo.flapped = [0 1];
    % 1 = partition contains a control surface
    
    Geo.fsym = [0 1];
    % Symmetry of control surface deflection
    
    Geo.meshtype = [1 1];
    % Mesh distribution type used by Tornado
    
    
    
elseif ID == 18.1
    
    % =============================================================
    % TEMPLATE
    % =============================================================
    
    Geo.name = 'F-18.Tail';
    
    
    % ---------------- ROSKAM DATA ----------------
    
    Geo.b = 12.31;                     % Wing span [m]
    Geo.S = 37.16;                     % Wing reference area [m^2]
    
    Geo.Lambda = 35;                   % Leading edge sweep [deg]
    
    Geo.c_r = 4.04;                    % Wing root chord [m]
    Geo.c_t = 1.68;                    % Wing tip chord [m]
    
    Geo.TR_full = Geo.c_t / Geo.c_r;   % Overall wing taper ratio
    
    
    % ---------------- AILERON GEOMETRY ----------------
    
    Geo.S_f = 2.27/2;
    Geo.hinge = 0.25;
    
    Geo.y_i = 4.03;
    Geo.y_o = 5.87;
    
    Geo.bf = Geo.y_o - Geo.y_i;
    
    
    % ---------------- TORNADO REFERENCE DATA ----------------
    
    Geo.x_CG = 0;
    Geo.y_CG = 0;
    Geo.z_CG = 0;
    
    Geo.x_ref = 0;
    Geo.y_ref = 0;
    Geo.z_ref = 0;
    
    
    % ---------------- SURFACE DEFINITION ----------------
    
    Geo.nwing = 2;                     % Wing + horizontal tail
    
    Geo.nelem = [2 1];                 % Partitions per surface
    
    Geo.symetric = [1 1];              % Both surfaces are symmetric
    
    Geo.allmove = [0 0];               % No fully moving surfaces
    
    
    Geo.c_root = [4.04 2.5];           % Root chord of wing and tail
    
    
    Geo.Airfoil_root = 'N64210.DAT';
    Geo.Airfoil_tip  = 'N64210.DAT';
    
    
    % ---------------- PANEL DISCRETIZATION ----------------
    
    Geo.nx = 3;
    Geo.ny = 7;
    
    Geo.fnx = 2;
    Geo.fny = 4;
    
    
    % ---------------- SURFACE GEOMETRY ----------------
    
    % Leading edge x-coordinates for wing and tail
    Geo.startx = [
        0 (Geo.b/2 - Geo.bf)*tand(Geo.Lambda);
        4.47 0
    ];
   
    
    % Leading edge y-coordinates
    Geo.starty = [
        0 (Geo.b/2 - Geo.bf);
        0 0
    ];
    
    
    % Leading edge z-coordinates
    Geo.startz = [
        0 0;
        0 0
    ];
    
    
    % Span of each partition
    Geo.span = [
        Geo.b/2 - Geo.bf  Geo.bf;
        6.58/2 0
    ];
    
    
    % Taper ratios
    Geo.TR = [
        2.38/Geo.c_root(1)  Geo.c_t/2.38;
        0.33 0
    ];
    
    
    % Quarter-chord sweep angles
    Geo.Lambda_c4 = [
        20 20;
        40 0
    ];
    
    
    
    Geo.Gamma = -3;                   % Dihedral angle
    Geo.Twist = 0;                    % Twist
    
    
    % ---------------- CONTROL SURFACES ----------------
    
    Geo.flapped = [
        0 1;
        0 0
    ];
    
    Geo.fsym = [0 1];
    
    Geo.meshtype = [
        1 1;
        1 1
    ];
    
elseif ID == 18.2
    
    % =============================================================
    % TEMPLATE
    % =============================================================
    
    Geo.name = 'F-18.Tail';
    
    
    % ---------------- ROSKAM DATA ----------------
    
    Geo.b = 12.31;                     % Wing span [m]
    Geo.S = 37.16;                     % Wing reference area [m^2]
    
    Geo.Lambda = 35;                   % Leading edge sweep [deg]
    
    Geo.c_r = 4.04;                    % Wing root chord [m]
    Geo.c_t = 1.68;                    % Wing tip chord [m]
    
    Geo.TR_full = Geo.c_t / Geo.c_r;   % Overall wing taper ratio
    
    
    % ---------------- AILERON GEOMETRY ----------------
    
    Geo.S_f = 2.27/2;
    Geo.hinge = 0.25;
    
    Geo.y_i = 4.03;
    Geo.y_o = 5.87;
    
    Geo.bf = Geo.y_o - Geo.y_i;
    
    
    % ---------------- TORNADO REFERENCE DATA ----------------
    
    Geo.x_CG = 0;
    Geo.y_CG = 0;
    Geo.z_CG = 0;
    
    Geo.x_ref = 0;
    Geo.y_ref = 0;
    Geo.z_ref = 0;
    
    
    % ---------------- SURFACE DEFINITION ----------------
    
    Geo.nwing = 2;                     % Wing + horizontal tail
    
    Geo.nelem = [2 1];                 % Partitions per surface
    
    Geo.symetric = [1 1];              % Both surfaces are symmetric
    
    Geo.allmove = [0 0];               % No fully moving surfaces
    
    
    Geo.c_root = [4.04 2.5];           % Root chord of wing and tail
    
    
    Geo.Airfoil_root = 'N64210.DAT';
    Geo.Airfoil_tip  = 'N64210.DAT';
    
    
    % ---------------- PANEL DISCRETIZATION ----------------
    
    Geo.nx = 3;
    Geo.ny = 7;
    
    Geo.fnx = 2;
    Geo.fny = 4;
    
    
    % ---------------- SURFACE GEOMETRY ----------------
    
    % Leading edge x-coordinates for wing and tail
    Geo.startx = [
        0 (Geo.b/2 - Geo.bf)*tand(Geo.Lambda);
        4.47 0
    ];
   
    
    % Leading edge y-coordinates
    Geo.starty = [
        0 (Geo.b/2 - Geo.bf);
        0 0
    ];
    
    
    % Leading edge z-coordinates
    Geo.startz = [
        0 0;
        0 0
    ];
    
    
    % Span of each partition
    Geo.span = [
        Geo.b/2 - Geo.bf  Geo.bf;
        6.58/2 0
    ];
    
    
    % Taper ratios
    Geo.TR = [
        2.38/Geo.c_root(1)  Geo.c_t/2.38;
        0.33 0
    ];
    
    
    % Quarter-chord sweep angles
    Geo.Lambda_c4 = [
        20 20;
        40 0
    ];
    
    
    
    Geo.Gamma = -3;                   % Dihedral angle
    Geo.Twist = 0;                    % Twist
    
    
    % ---------------- CONTROL SURFACES ----------------
    
    Geo.flapped = [
        0 1;
        0 0
    ];
    
    Geo.fsym = [0 1];
    
    Geo.meshtype = [
        1 1;
        1 1
    ];
    
end
%--------------------------------------------------------------------------




%% ================================================================
% DERIVED AILERON QUANTITIES
% Calculates local chord and flap chord ratio
%% ================================================================

y_mid = (Geo.y_i + Geo.y_o)/2;

c_local = Geo.c_r - ...
          (Geo.c_r - Geo.c_t) * ...
          (y_mid/(Geo.b/2));

c_aileron = Geo.S_f / Geo.bf;

Geo.fc = c_aileron / c_local;         % Flap chord ratio


%% ================================================================
% AUTOMATIC MATRIX SIZE NORMALIZATION
% Ensures all geometry matrices have dimensions:
%   [number of surfaces  ×  max number of partitions]
%% ================================================================

nwing = Geo.nwing;

maxelem = max(Geo.nelem);

fields = {'startx','starty','startz','span','TR','Lambda_c4','flapped','meshtype'};

for k = 1:length(fields)
    
    f = fields{k};
    
    A = Geo.(f);
    
    if size(A,1) ~= nwing || size(A,2) ~= maxelem
        
        B = zeros(nwing,maxelem);
        
        B(1:size(A,1),1:size(A,2)) = A;
        
        Geo.(f) = B;
        
    end
    
end

end