function GeomInput = Geometry_config(ID)

% Reference Point
GeomInput.x_ref = 0;     % coord x
GeomInput.y_ref = 0;     % coord y 
GeomInput.z_ref = 0;     % coord z

% Panels distribution
GeomInput.nx         = 3;             % Chord-wise number of panels
GeomInput.ny         = 7;             % Span-wise number of panels
GeomInput.fnx        = 2;             % Chord-wise number of panels for flap
GeomInput.fny        = 4;             % Span-wise number of panels for flap

if ID == 18 
    % =======================
    % F/A-18 GEOMETRY INPUT
    % https://man.fas.org/dod-101/sys/ac/f-18.htm?level=1&utm  for data
    % =======================
   
    GeomInput.name       = 'F/A-18';        
    GeomInput.b          = 12.31;         % full wingspan [m]
    GeomInput.S          = 37.16;         % wing surface [m^2]
    GeomInput.c_root     = 4.04;          % root chord [m]
    GeomInput.c_tip      = 1.68;          % tip chord [m]
    GeomInput.Lambda     = 35;            % LE sweep [deg]
    GeomInput.Lambda_c4  = 20;            % sweep at 1/4 chord [deg]
    GeomInput.Gamma      = -3;            % dihedral [deg]
    GeomInput.TR         =  GeomInput.c_tip /  GeomInput.c_root;
    GeomInput.Twist      = 0;             % wing twist angle [deg]


    % Aileron geometry
    GeomInput.y_i        = 4.03;          % inner spanwise station
    GeomInput.y_o        = 5.87;          % outer spanwise station
    bf                   = GeomInput.y_o - GeomInput.y_i;   % span aileron (preliminary (not used in calculations later)) 
    GeomInput.S_f        = 2.27 / 2;      % aileron surface area (total /2 for each aileron)
    GeomInput.hinge      = 0.25;          % hinge line position
    
    % Airfoil
    GeomInput.Airfoil    = 'N64210.DAT';

    % For TORNADO ---------------------------------------------------------

    GeomInput.bpart = [(GeomInput.b/2 -  bf) , bf ] ;                       % span of partitions

    % wing partitions
    GeomInput.nwing  = 1;                                                  % number of wings
    GeomInput.nelem  = 2;                                                  % number of partitions

    GeomInput.startx = [0, (GeomInput.b/2 - bf)*tand(GeomInput.Lambda)];   % apex point x coord for each part
    GeomInput.starty = [0, (GeomInput.b/2 - bf)];                          % apex point y coord for each part
    GeomInput.startz =  [0, 0];                                            % apex point z coord for each part
 
    cpart = GeomInput.c_root - (GeomInput.c_root - GeomInput.c_tip ) * ((GeomInput.b/2-bf) / (GeomInput.b/2)); % chord at partition

    GeomInput.T = [cpart / GeomInput.c_root, GeomInput.c_tip / cpart];     % TR for each partition

    GeomInput.flapped = [0, 1];                                            % is partition flapped

    y_mid = (GeomInput.y_i + GeomInput.y_o)/2;

    c_local = GeomInput.c_root - ...
          (GeomInput.c_root - GeomInput.c_tip) * ...
          (y_mid / (GeomInput.b/2));

    c_flap = GeomInput.S_f / bf;

    GeomInput.fc = c_flap / c_local;

    % CG
    GeomInput.x_CG      = 0;             % CG x coord
    GeomInput.y_CG      = 0;             % CG y coord
    GeomInput.z_CG      = 0;             % CG z coord

    %----------------------------------------------------------------------

    elseif ID == 35
    % =======================
    % F-35 GEOMETRY INPUT
    % =======================
    GeomInput.name       = 'F-35';
    GeomInput.b          = 10.7;          % full wingspan [m]
    GeomInput.S          = 42.7;          % wing surface [m^2]
    GeomInput.c_root     = 6.71;          % root chord (calc. from S, b, TR) [m]
    GeomInput.c_tip      = 1.27;          % tip chord (calc. from c_root, TR) [m]
    GeomInput.Lambda     = 35;            % LE sweep [deg]
    GeomInput.Lambda_c4  = 24.1;          % sweep at 1/4 chord [deg]
    GeomInput.Gamma      = 0;             % dihedral [deg]
    GeomInput.TR         =  GeomInput.c_tip /  GeomInput.c_root;

    % Aileron geometry
    GeomInput.y_i        = 1.65;          % inner spanwise station
    GeomInput.y_o        = 5.15;          % outer spanwise station
    GeomInput.S_f        = 3.65;          % flap surface area
    GeomInput.hinge      = 0.25;          % hinge line position
    
    % Airfoil
    GeomInput.Airfoil    = 'N64210.DAT';

    % For Tornado ---------------------------------------------------------

    % wing partitions
    GeomInput.nwing = 1;    % number of wings

    % CG
    GeomInput.x_CG      = 0;             % CG x coord
    GeomInput.y_CG      = 0;             % CG y coord
    GeomInput.z_CG      = 0;             % CG z coord

    %----------------------------------------------------------------------

    elseif ID == 300
    % ==========================
    % EXTRA 300 GEOMETRY INPUT
    % ==========================
    GeomInput.name       = 'EXTRA 300';
    GeomInput.b          = 8;             % full wingspan [m]
    GeomInput.S          = 10.7;          % wing surface [m^2]
    GeomInput.c_root     = 1.85;          % root chord (calc. from S, b, TR) [m]
    GeomInput.c_tip      = 0.83;          % tip chord (calc. from c_root, TR) [m]
    GeomInput.Lambda     = 2.5;             % LE sweep [deg]
    GeomInput.Lambda_c4  = 0;          % sweep at 1/4 chord (forward sweep) [deg]
    GeomInput.Gamma      = 0;             % dihedral [deg]
    GeomInput.TR         =  GeomInput.c_tip /  GeomInput.c_root;
    
    % Aileron geometry
    GeomInput.y_i        = 0;             % inner spanwise station
    GeomInput.y_o        = 2.95;          % outer spanwise station
    GeomInput.S_f        = 0.855;          % flap surface area
    GeomInput.hinge      = 0.3;          % hinge line position
    
    % Airfoil
    GeomInput.Airfoil    = 'NACA0012.DAT';

    % For Tornado ---------------------------------------------------------

    % wing partitions
    GeomInput.nwing = 1;    % number of wings
    % GeomInput.bPart = GeomInput.b - GeomInput.y_i                        aileron beaks partition

    % CG
    GeomInput.x_CG      = 0;             % CG x coord
    GeomInput.y_CG      = 0;             % CG y coord
    GeomInput.z_CG      = 0;             % CG z coord

    %----------------------------------------------------------------------

end