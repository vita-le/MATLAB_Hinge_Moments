function Geo = INPUT(ID)

% =========================================================================
%   GEOMETRY INPUT FUNCTION
%   Returns a Geo struct with all geometric parameters for a given aircraft ID
% =========================================================================

if ID == 18.1 % no tail

    % =====================================================================
    %   F/A-18 GEOMETRY — Wing + Horizontal Tail + Vertical Tail
    %   Source: https://man.fas.org/dod-101/sys/ac/f-18.htm
    % =====================================================================

    Geo.name = 'F/A-18 TAIL';

    % -----------------------------------------------------------------
    %   1. WING PARAMETERS  (Roskam)
    % -----------------------------------------------------------------

    Geo.b       = 12.31;            % Full span [m]
    Geo.S       = 37.16;            % Full wing surface area [m^2]
    Geo.Lambda  = 35;               % Leading-edge sweep angle [deg]
    Geo.c_r     = 4.04;             % Root chord [m]
    Geo.c_t     = 1.68;             % Tip chord [m]
    Geo.TR_full = Geo.c_t / Geo.c_r; % Full-wing taper ratio [-]

    % -----------------------------------------------------------------
    %   2. AILERON PARAMETERS  (Roskam)
    % -----------------------------------------------------------------

    Geo.S_f   = 2.27 / 2;              % Single aileron surface area [m^2]  (total / 2)
    Geo.hinge = 0.25;                  % Hinge line position (fraction of local chord) [-]
    Geo.y_i   = 4.03;                  % Inner spanwise station [m]
    Geo.y_o   = 5.87;                  % Outer spanwise station [m]
    Geo.bf    = Geo.y_o - Geo.y_i;    % Aileron span [m]

    % Derived aileron geometry
    y_mid     = (Geo.y_i + Geo.y_o) / 2;                           % Mid-span of aileron [m]
    c_local   = Geo.c_r - (Geo.c_r - Geo.c_t) * (y_mid / (Geo.b/2)); % Wing chord at y_mid [m]
    c_aileron = Geo.S_f / Geo.bf;                                   % Aileron MAC [m]

    % -----------------------------------------------------------------
    %   3. REFERENCE FRAME
    % -----------------------------------------------------------------

    % Center of Gravity
    Geo.x_CG = 2.40;   % [m]
    Geo.y_CG = 0;      % [m]
    Geo.z_CG = 0;      % [m]

    % Moment reference point
    Geo.x_ref = 0;     % [m]
    Geo.y_ref = 0;     % [m]
    Geo.z_ref = 0;     % [m]

    % -----------------------------------------------------------------
    %   4. SURFACE LAYOUT  (Tornado VLM)
    %   Wing index:  1 = Main wing  |  2 = Horizontal tail  |  3 = Vertical tail
    % -----------------------------------------------------------------

    Geo.nwing    = 1;           % Number of lifting surfaces
    Geo.nelem    = [2];  % Number of spanwise partitions per surface
    Geo.symetric = [1];  % Symmetry flag (1 = mirrored about XZ plane)
    Geo.allmove  = [0];  % All-moving surface flag

    % -----------------------------------------------------------------
    %   5. APEX COORDINATES  [surface × partition]
    % -----------------------------------------------------------------
    
    % x-coordinates of partition leading-edge apex [m]
    Geo.startx = [0,   (Geo.b/2 - Geo.bf) * tand(Geo.Lambda)];             % wing 1, part 1 - 2 (VT)
    
    % y-coordinates of partition leading-edge apex [m]
    Geo.starty = [0,   (Geo.b/2 - Geo.bf)];   
    
    % z-coordinates of partition leading-edge apex [m]
    Geo.startz = [0,   0];    

    % -----------------------------------------------------------------
    %   6. CHORD & AIRFOIL DEFINITION  [surface × partition]
    % -----------------------------------------------------------------

    Geo.c_root = [4.04];   % Root chord for each surface (wing) [m]

    Geo.Airfoil = {'N64210.DAT',   'N64210.DAT'};    % Main wing  (cambered)

    % (legacy named references, kept for compatibility)
    Geo.Airfoil_root = 'N64210.DAT';
    Geo.Airfoil_tip  = 'N64210.DAT';


    % -----------------------------------------------------------------
    %   7. PLANFORM GEOMETRY  [surface × partition]
    % -----------------------------------------------------------------

    Geo.span = [Geo.b/2 - Geo.bf, Geo.bf];          % Main wing:  inboard | aileron

    Geo.TR = [2.38/Geo.c_root(1), Geo.c_t/2.38];    % Main wing taper ratios


    Geo.Lambda_c4 = [20, 20];                        % Main wing quarter-chord sweep [deg]

    Geo.Gamma = [-3, -3];                            % Main wing dihedral [deg]


    Geo.Twist = 0;                                  % Wing twist angle [deg]  (uniform)

    % -----------------------------------------------------------------
    %   8. MESH SETTINGS  [surface × partition]
    % -----------------------------------------------------------------

    Geo.nx       = 3;   % Chordwise panels (fixed)
    Geo.ny       = 3;   % Spanwise panels  (fixed)
    Geo.fnx      = 1;   % Chordwise panels on flap/aileron

    Geo.meshtype = [1, 1];   % Panel distribution type (1–7)

    % -----------------------------------------------------------------
    %   9. CONTROL SURFACE (AILERON) SETTINGS
    % -----------------------------------------------------------------

    Geo.flapped = [0, 1];   % Partition is flapped? (1 = yes)  — main wing only


    Geo.fc   = c_aileron / c_local;   % Flap-chord ratio (aileron chord / local wing chord) [-]
    Geo.fsym = [0, 1];                % Symmetric deflection flag per flapped partition

    
    
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------


elseif ID == 18.2 % tail yes

    % =====================================================================
    %   F/A-18 GEOMETRY — Wing + Horizontal Tail + Vertical Tail
    %   Source: https://man.fas.org/dod-101/sys/ac/f-18.htm
    % =====================================================================

    Geo.name = 'F/A-18 TAIL';

    % -----------------------------------------------------------------
    %   1. WING PARAMETERS  (Roskam)
    % -----------------------------------------------------------------

    Geo.b       = 12.31;            % Full span [m]
    Geo.S       = 37.16;            % Full wing surface area [m^2]
    Geo.Lambda  = 35;               % Leading-edge sweep angle [deg]
    Geo.c_r     = 4.04;             % Root chord [m]
    Geo.c_t     = 1.68;             % Tip chord [m]
    Geo.TR_full = Geo.c_t / Geo.c_r; % Full-wing taper ratio [-]

    % -----------------------------------------------------------------
    %   2. AILERON PARAMETERS  (Roskam)
    % -----------------------------------------------------------------

    Geo.S_f   = 2.27 / 2;              % Single aileron surface area [m^2]  (total / 2)
    Geo.hinge = 0.25;                  % Hinge line position (fraction of local chord) [-]
    Geo.y_i   = 4.03;                  % Inner spanwise station [m]
    Geo.y_o   = 5.87;                  % Outer spanwise station [m]
    Geo.bf    = Geo.y_o - Geo.y_i;    % Aileron span [m]

    % Derived aileron geometry
    y_mid     = (Geo.y_i + Geo.y_o) / 2;                           % Mid-span of aileron [m]
    c_local   = Geo.c_r - (Geo.c_r - Geo.c_t) * (y_mid / (Geo.b/2)); % Wing chord at y_mid [m]
    c_aileron = Geo.S_f / Geo.bf;                                   % Aileron MAC [m]

    % -----------------------------------------------------------------
    %   3. REFERENCE FRAME
    % -----------------------------------------------------------------

    % Center of Gravity
    Geo.x_CG = 2.40;   % [m]
    Geo.y_CG = 0;      % [m]
    Geo.z_CG = 0;      % [m]

    % Moment reference point
    Geo.x_ref = 0;     % [m]
    Geo.y_ref = 0;     % [m]
    Geo.z_ref = 0;     % [m]

    % -----------------------------------------------------------------
    %   4. SURFACE LAYOUT  (Tornado VLM)
    %   Wing index:  1 = Main wing  |  2 = Horizontal tail  |  3 = Vertical tail
    % -----------------------------------------------------------------

    Geo.nwing    = 3;           % Number of lifting surfaces
    Geo.nelem    = [2, 1, 1];  % Number of spanwise partitions per surface
    Geo.symetric = [1, 1, 1];  % Symmetry flag (1 = mirrored about XZ plane)
    Geo.allmove  = [0, 0, 0];  % All-moving surface flag

    % -----------------------------------------------------------------
    %   5. APEX COORDINATES  [surface × partition]
    % -----------------------------------------------------------------
    
    % x-coordinates of partition leading-edge apex [m]
    Geo.startx = [0,   (Geo.b/2 - Geo.bf) * tand(Geo.Lambda);              % wing 1, part 1 - 2 (wing)
                  5.05, 0;                                                 % wing 2, part 1 - 2 (HT)
                  3.23, 0];                                                % wing 3, part 1 - 2 (VT)
    
    % y-coordinates of partition leading-edge apex [m]
    Geo.starty = [0,   (Geo.b/2 - Geo.bf);
                  0,   0;
                  1.16, 0];   
    % z-coordinates of partition leading-edge apex [m]
    Geo.startz = [0,   0;
                  0,   0;
                  0,   0];    

    % -----------------------------------------------------------------
    %   6. CHORD & AIRFOIL DEFINITION  [surface × partition]
    % -----------------------------------------------------------------

    Geo.c_root = [4.04, 3.1, 2.98];   % Root chord for each surface (wing) [m]

    Geo.Airfoil = {
        'N64210.DAT',   'N64210.DAT';    % Main wing  (cambered)
        'naca0018.DAT', 'naca0018.DAT';  % H-tail     (symmetric)
        'naca0018.DAT', 'naca0018.DAT'}; % V-tail     (symmetric)

    % (legacy named references, kept for compatibility)
    Geo.Airfoil_root = 'N64210.DAT';
    Geo.Airfoil_tip  = 'N64210.DAT';
    Geo.Airfoil_tail = 'naca0018';

    % -----------------------------------------------------------------
    %   7. PLANFORM GEOMETRY  [surface × partition]
    % -----------------------------------------------------------------

    Geo.span = [Geo.b/2 - Geo.bf, Geo.bf;           % Main wing:  inboard | aileron
                6.58/2,           0;                % H-tail
                3,                0];               % V-tail          [m]

    Geo.TR = [2.38/Geo.c_root(1), Geo.c_t/2.38;     % Main wing taper ratios
              0.33,                0;               % H-tail
              0.3,                 0];              % V-tail          [-]

    Geo.Lambda_c4 = [20, 20;                        % Main wing quarter-chord sweep [deg]
                     40,  0;                        % H-tail
                     35,  0];                       % V-tail

    Geo.Gamma = [-3, -3;                            % Main wing dihedral [deg]
                  0,  0;                            % H-tail
                 70,  0];                           % V-tail (cant angle)

    Geo.Twist = 0;                                  % Wing twist angle [deg]  (uniform)

    % -----------------------------------------------------------------
    %   8. MESH SETTINGS  [surface × partition]
    % -----------------------------------------------------------------

    Geo.nx       = 3;   % Chordwise panels (fixed)
    Geo.ny       = 3;   % Spanwise panels  (fixed)
    Geo.fnx      = 1;   % Chordwise panels on flap/aileron

    Geo.meshtype = [1, 1;
                    1, 1;
                    1, 1];   % Panel distribution type (1–7)

    % -----------------------------------------------------------------
    %   9. CONTROL SURFACE (AILERON) SETTINGS
    % -----------------------------------------------------------------

    Geo.flapped = [0, 1;   % Partition is flapped? (1 = yes)  — main wing only
                   0, 0;
                   0, 0];

    Geo.fc   = c_aileron / c_local;   % Flap-chord ratio (aileron chord / local wing chord) [-]
    Geo.fsym = [0, 1];                % Symmetric deflection flag per flapped partition

end