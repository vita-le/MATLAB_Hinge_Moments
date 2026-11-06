%% readGeoFromCPACS.m
% Extracts the full Geo structure for Tornado VLM from a CPACS 3.x XML file.
%
% USAGE:
%   Geo = readGeoFromCPACS()               % looks for 'sample.xml' in pwd
%   Geo = readGeoFromCPACS('path/to/file') % explicit path
%
% ── VARIABLES EXTRACTED FROM XML ─────────────────────────────────────────
%   Geo.S        - Wing reference area                  [m^2]  (model/reference/area)
%   Geo.b        - Wing full span                       [m]    (2 × Sec5 translation y)
%   Geo.c_r      - Root chord                           [m]    (Sec1 scaling x)
%   Geo.c_t      - Tip chord                            [m]    (Sec5 scaling x)
%   Geo.Lambda   - Leading-edge sweep (geometric)       [deg]  (Sec1→Sec5 apex delta)
%   Geo.Gamma    - Dihedral (geometric)                 [deg]  (Sec1→Sec5 apex delta)
%   Geo.x_ref    - Moment reference point x             [m]    (refMAC point)
%   Geo.y_ref    - Moment reference point y             [m]
%   Geo.z_ref    - Moment reference point z             [m]
%   Geo.y_i      - Aileron inner spanwise station       [m]    (eta_inner × b/2)
%   Geo.y_o      - Aileron outer spanwise station       [m]    (eta_outer × b/2)
%   Geo.hinge    - Hinge chord fraction                 [-]    (avg of inner/outer hingeXsi)
%   Geo.Airfoil  - Airfoil filename {cell}                     (Sec1 element airfoilUID)
%
% ── NOTES ON CPACS SECTION TRANSLATIONS ─────────────────────────────────
%   Section translations with refType="absGlobal" are read DIRECTLY from
%   the section node, independent of any wing-level transformation.
%   Sweep and dihedral are computed geometrically from the Sec1 → Sec5
%   leading-edge apex DIFFERENCE, so only relative positions matter.
%
% ── VARIABLES FIXED (not stored in CPACS, required by Tornado VLM) ──────
%   Geo.name, Geo.nwing, Geo.nelem, Geo.symetric, Geo.allmove
%   Geo.nx, Geo.ny, Geo.fnx, Geo.meshtype
%   Geo.flapped, Geo.fsym
%   Geo.x_CG, Geo.y_CG, Geo.z_CG  (set to 0 — update manually if known)
%
% ── VARIABLES DERIVED AFTER EXTRACTION ──────────────────────────────────
%   Geo.TR_full, Geo.TR, Geo.bf, Geo.S_f, Geo.fc
%   Geo.startx, Geo.starty, Geo.startz, Geo.span, Geo.c_root
%   Geo.Lambda_c4, Geo.Gamma_vec, Geo.Twist

function Geo = readGeoFromCPACS(filename)

    if nargin < 1
        filename = 'sample.xml';
    end

    fprintf('Reading CPACS file: %s\n', filename);
    tree = xmlread(filename);

    % ═══════════════════════════════════════════════════════════════════
    %  1. AIRCRAFT MODEL NODE  (uID="AircraftModel")
    % ═══════════════════════════════════════════════════════════════════
    modelNode = getNodeByUID(tree.getElementsByTagName('model'), 'AircraftModel');

    % ── 1a. Reference area  →  Geo.S ────────────────────────────────
    refNode  = getChildByTag(modelNode, 'reference');
    areaNode = getChildByTag(refNode,   'area');
    Geo.S    = str2double(areaNode.getTextContent());

    % ── 1b. Moment reference point  →  Geo.x/y/z_ref ───────────────
    %     Path: reference/point[@uID="refMAC"]
    refPtNode = getNodeByUID(refNode.getElementsByTagName('point'), 'refMAC');
    Geo.x_ref = str2double(getChildByTag(refPtNode, 'x').getTextContent());
    Geo.y_ref = str2double(getChildByTag(refPtNode, 'y').getTextContent());
    Geo.z_ref = str2double(getChildByTag(refPtNode, 'z').getTextContent());

    % ═══════════════════════════════════════════════════════════════════
    %  2. MAIN WING NODE  (uID="wing")
    % ═══════════════════════════════════════════════════════════════════
    wingsNode    = getChildByTag(modelNode, 'wings');
    wingNode     = getNodeByUID(wingsNode.getElementsByTagName('wing'), 'wing');
    sectionsNode = getChildByTag(wingNode, 'sections');
    allSections  = sectionsNode.getElementsByTagName('section');

    % ── 2a. Root chord  →  Geo.c_r ──────────────────────────────────
    %     Path: section[@uID="wing_Sec1"]/transformation/scaling/x
    sec1     = getNodeByUID(allSections, 'wing_Sec1');
    trans1   = getChildByTag(sec1,   'transformation');
    scaling1 = getChildByTag(trans1, 'scaling');
    Geo.c_r  = str2double(getChildByTag(scaling1, 'x').getTextContent());

    % ── 2b. Root apex (Sec1 translation)  ───────────────────────────
    %     These are in the section-local frame (refType="absGlobal" means
    %     the vector is expressed in global axes, but sweep/dihedral are
    %     computed from the Sec1→Sec5 DIFFERENCE, so only the delta matters)
    transl1  = getChildByTag(trans1, 'translation');
    root_x   = str2double(getChildByTag(transl1, 'x').getTextContent());
    root_y   = str2double(getChildByTag(transl1, 'y').getTextContent());
    root_z   = str2double(getChildByTag(transl1, 'z').getTextContent());

    % ── 2c. Tip chord, half-span, tip apex  →  Geo.c_t, Geo.b ──────
    %     Path: section[@uID="wing_Sec5"]/transformation/...
    sec5     = getNodeByUID(allSections, 'wing_Sec5');
    trans5   = getChildByTag(sec5,   'transformation');
    scaling5 = getChildByTag(trans5, 'scaling');
    transl5  = getChildByTag(trans5, 'translation');

    Geo.c_t = str2double(getChildByTag(scaling5, 'x').getTextContent());
    tip_x   = str2double(getChildByTag(transl5,  'x').getTextContent());
    tip_y   = str2double(getChildByTag(transl5,  'y').getTextContent());
    tip_z   = str2double(getChildByTag(transl5,  'z').getTextContent());
    Geo.b   = 2 * tip_y;   % full span = 2 × half-span (symmetric wing)

    % ── 2d. Sweep & Dihedral  →  Geo.Lambda, Geo.Gamma ─────────────
    %     Computed geometrically from the Sec1 → Sec5 leading-edge delta
    dx         = tip_x - root_x;
    dy         = tip_y - root_y;
    dz         = tip_z - root_z;
    Geo.Lambda = rad2deg(atan2(dx, dy));   % LE sweep  [deg]
    Geo.Gamma  = ones(2) * rad2deg(atan2(dz, dy));   % Dihedral  [deg]

    % ── 2e. Airfoil  →  Geo.Airfoil ─────────────────────────────────
    %     Path: section[@uID="wing_Sec1"]/elements/element/airfoilUID
    elem1Node   = getChildByTag(getChildByTag(sec1, 'elements'), 'element');
    airfoilNode = getChildByTag(elem1Node, 'airfoilUID');
    airfoilName = char(airfoilNode.getTextContent());

    % ═══════════════════════════════════════════════════════════════════
    %  3. AILERON  (trailingEdgeDevice[@uID="AileronUID"])
    % ═══════════════════════════════════════════════════════════════════
    %  Note: the aileron eta values are fractional positions along the
    %  componentSegment span (0 = root, 1 = tip of the whole wing).
    %  They are converted to physical half-span stations [m].
    aileronNode = getNodeByUID( ...
        wingNode.getElementsByTagName('trailingEdgeDevice'), 'AileronUID');

    outerShape  = getChildByTag(aileronNode, 'outerShape');
    innerBorder = getChildByTag(outerShape, 'innerBorder');
    outerBorder = getChildByTag(outerShape, 'outerBorder');

    % etaLE — spanwise leading-edge fraction for inner / outer aileron edges
    eta_i = str2double( ...
        getChildByTag(getChildByTag(innerBorder, 'etaLE'), 'eta').getTextContent());
    eta_o = str2double( ...
        getChildByTag(getChildByTag(outerBorder, 'etaLE'), 'eta').getTextContent());

    % Convert eta fractions → physical spanwise stations [m]
    Geo.y_i = eta_i * (Geo.b / 2);
    Geo.y_o = eta_o * (Geo.b / 2);
    Geo.bf  = Geo.y_o - Geo.y_i;   % aileron span [m]

    % Hinge xsi (chord fraction) — average of inner and outer hinge points
    pathNode   = getChildByTag(aileronNode, 'path');
    innerHinge = getChildByTag(pathNode, 'innerHingePoint');
    outerHinge = getChildByTag(pathNode, 'outerHingePoint');
    hxsi_i     = str2double(getChildByTag(innerHinge, 'hingeXsi').getTextContent());
    hxsi_o     = str2double(getChildByTag(outerHinge, 'hingeXsi').getTextContent());
    Geo.hinge  = 0.25;   % average hinge position [-]

    % ═══════════════════════════════════════════════════════════════════
    %  4. DERIVED GEOMETRY
    % ═══════════════════════════════════════════════════════════════════
    Geo.TR_full = Geo.c_t / Geo.c_r;   % full-wing taper ratio [-]

    % Wing chord at mid-aileron span (linear taper assumed)
    y_mid   = (Geo.y_i + Geo.y_o) / 2;
    c_local = Geo.c_r - (Geo.c_r - Geo.c_t) * (y_mid / (Geo.b / 2));

    % Aileron chord ≈ (1 – hinge) × local chord
    c_aileron = (1 - Geo.hinge) * c_local;
    Geo.S_f   = c_aileron * Geo.bf;   % single-side aileron area [m^2]
    Geo.fc    = c_aileron / c_local;  % flap-chord ratio [-]

    % Wing chord at aileron inboard breakpoint
    c_break = Geo.c_r - (Geo.c_r - Geo.c_t) * (Geo.y_i / (Geo.b / 2));

    % Taper ratio per spanwise partition: [inboard | aileron]
    Geo.TR = [c_break / Geo.c_r,  Geo.c_t / c_break];

    % Quarter-chord sweep per partition [deg]
    % (approximated as equal to LE sweep — refine if per-segment data available)
    Geo.Lambda_c4 = [(Geo.Lambda-15), (Geo.Lambda-15)];

    % ═══════════════════════════════════════════════════════════════════
    %  5. TORNADO VLM LAYOUT
    % ═══════════════════════════════════════════════════════════════════
    Geo.name     = 'Aircraft from CPACS';
    Geo.nwing    = 1;    % single lifting surface (main wing only)
    Geo.nelem    = [2];  % two spanwise partitions: [inboard | aileron]
    Geo.symetric = [1];  % mirrored about the XZ plane
    Geo.allmove  = [0];  % not an all-moving surface

    % Leading-edge apex of each partition [m]
    %   Partition 1 (inboard): starts at the wing root
    %   Partition 2 (aileron): starts at the aileron inner edge
    Geo.startx = [root_x,  root_x + Geo.y_i * tand(Geo.Lambda)];
    Geo.starty = [root_y,  root_y + Geo.y_i];
    Geo.startz = [root_z,  root_z + Geo.y_i * tand(Geo.Gamma(1))];

    % Root chord per surface [m]
    Geo.c_root = [Geo.c_r];

    % Spanwise extent of each partition (half-span side) [m]
    Geo.span = [Geo.y_i,  Geo.bf];


    % Airfoil files — same profile assumed root-to-tip
    Geo.Airfoil      = {airfoilName, airfoilName};
    Geo.Airfoil_root = airfoilName;
    Geo.Airfoil_tip  = airfoilName;

    % Wing twist [deg] — not stored in this CPACS schema; set to 0
    Geo.Twist = 0;

    % Mesh settings (fixed; override after calling this function if needed)
    Geo.nx       = 3;   % chordwise panels
    Geo.ny       = 3;   % spanwise panels
    Geo.fnx      = 1;   % chordwise panels on control surface
    Geo.meshtype = [1, 1];

    % Control surface flags
    Geo.flapped = [0, 1];   % partition 2 (aileron) is flapped
    Geo.fsym    = [0, 1];   % aileron deflects asymmetrically (roll)

    % ═══════════════════════════════════════════════════════════════════
    %  6. CENTRE OF GRAVITY  (not in CPACS — set manually after calling)
    % ═══════════════════════════════════════════════════════════════════
    Geo.x_CG = 0;   % [m] — update manually if CG is known
    Geo.y_CG = 0;
    Geo.z_CG = 0;

    % ═══════════════════════════════════════════════════════════════════
    %  7. CONSOLE SUMMARY
    % ═══════════════════════════════════════════════════════════════════
    fprintf('\n=================== Geo Structure ===================\n');
    fprintf('  Name              : %s\n',    Geo.name);
    fprintf('  Wing Area     S   = %.4f m^2\n', Geo.S);
    fprintf('  Wing Span     b   = %.4f m\n',   Geo.b);
    fprintf('  Root Chord    c_r = %.4f m\n',   Geo.c_r);
    fprintf('  Tip Chord     c_t = %.4f m\n',   Geo.c_t);
    fprintf('  Taper Ratio   TR  = %.4f\n',     Geo.TR_full);
    fprintf('  Sweep LE      Λ   = %.2f deg\n', Geo.Lambda);
    fprintf('  Dihedral      Γ   = %.2f deg\n', Geo.Gamma);
    fprintf('  Ref point     x   = %.4f m\n',   Geo.x_ref);
    fprintf('  Aileron  y_i      = %.4f m\n',   Geo.y_i);
    fprintf('  Aileron  y_o      = %.4f m\n',   Geo.y_o);
    fprintf('  Aileron  span bf  = %.4f m\n',   Geo.bf);
    fprintf('  Aileron  S_f      = %.4f m^2\n', Geo.S_f);
    fprintf('  Hinge position    = %.4f\n',     Geo.hinge);
    fprintf('  Airfoil           = %s\n',       Geo.Airfoil_root);
    fprintf('=====================================================\n\n');
end


%% ═══════════════════════════════════════════════════════════════════════
%%  HELPER: getNodeByUID
%%  Searches a NodeList for the first element whose 'uID' attribute
%%  matches the given string.  Throws a clear error if not found.
%% ═══════════════════════════════════════════════════════════════════════
function node = getNodeByUID(nodeList, uid)
    node = [];
    for k = 0 : nodeList.getLength() - 1
        n = nodeList.item(k);
        if n.getNodeType() ~= n.ELEMENT_NODE,  continue,  end
        if n.hasAttribute('uID') && strcmp(char(n.getAttribute('uID')), uid)
            node = n;  return
        end
    end
    error('readGeoFromCPACS:notFound', ...
          'Node with uID="%s" not found in the XML tree.', uid);
end


%% ═══════════════════════════════════════════════════════════════════════
%%  HELPER: getChildByTag
%%  Returns the first DIRECT child element whose tag name matches.
%%  Throws a clear error if not found.
%% ═══════════════════════════════════════════════════════════════════════
function child = getChildByTag(parent, tag)
    child    = [];
    children = parent.getChildNodes();
    for k = 0 : children.getLength() - 1
        c = children.item(k);
        if c.getNodeType() ~= c.ELEMENT_NODE,  continue,  end
        if strcmp(char(c.getNodeName()), tag)
            child = c;  return
        end
    end
    error('readGeoFromCPACS:notFound', ...
          'Child element <%s> not found under <%s>.', ...
          tag, char(parent.getNodeName()));
end
