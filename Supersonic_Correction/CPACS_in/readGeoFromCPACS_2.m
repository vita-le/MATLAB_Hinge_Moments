function Geo = readGeoFromCPACS_2(xmlFile)
    % Load File
    doc = xmlread(xmlFile);
    import javax.xml.xpath.*
    factory = XPathFactory.newInstance;
    xpath = factory.newXPath;

    % --- 1. Name ---------------------------------------------------------
    Geo.name = readXPath(xpath, doc, '/cpacs/vehicles/aircraft/model/name', 'string');

    % --- 2. Wing ---------------------------------------------------------
   
    % halfspan
    y_tip = readXPath(xpath, doc, '/cpacs/vehicles/aircraft/model/wings/wing/sections/section[last()]/transformation/translation/y', 'double');
    
    % Full Span
    Geo.b = y_tip * 2; 
    
    % S: Reference Area
    Geo.S = readXPath(xpath, doc, '/cpacs/vehicles/aircraft/model/reference/area', 'double');
    
    % Lambda: Sweep LE
    Geo.Lambda = 35; 
    
    % Chords (Root e Tip)
    Geo.c_r = readXPath(xpath, doc, '/cpacs/vehicles/aircraft/model/wings/wing/sections/section[1]/transformation/scaling/x', 'double');
    Geo.c_t = readXPath(xpath, doc, '/cpacs/vehicles/aircraft/model/wings/wing/sections/section[last()]/transformation/scaling/x', 'double');
    Geo.TR_full = Geo.c_t / Geo.c_r;

    % --- 3. Aileron ---
    Geo.S_f = readXPath(xpath, doc, '//controlSurfaces/trailingEdgeDevices/trailingEdgeDevice/reference_S/S_f', 'double');
    Geo.hinge = 0.25; % Fixed
    
    % Aileron Coord
    Geo.y_i = readXPath(xpath, doc, '//trailingEdgeDevice/outerShape/innerBorder/y_i', 'double');
    Geo.y_o = readXPath(xpath, doc, '//trailingEdgeDevice/outerShape/outerBorder/y_o', 'double');
    Geo.bf  = Geo.y_o - Geo.y_i;
    
    % fc: 
    xsi_val = readXPath(xpath, doc, '//trailingEdgeDevice/outerShape/innerBorder/xsiLE/xsi', 'double');
    Geo.fc = 1 - xsi_val;

    % --- 4. CG and Ref ---
    Geo.x_CG = readXPath(xpath, doc, '//designMasses/mTOM/location/x', 'double');
    Geo.y_CG = readXPath(xpath, doc, '//designMasses/mTOM/location/y', 'double');
    Geo.z_CG = readXPath(xpath, doc, '//designMasses/mTOM/location/z', 'double');

    % fix
    Geo.x_ref = 0;
    Geo.y_ref = 0;
    Geo.z_ref = 0;

    % --- 5. Section ---
    Geo.nwing = 1;
    Geo.nelem = 2;
    Geo.symetric = 1;
    Geo.allmove  = 0;
    
    span1 = y_tip - Geo.bf;
    x1    = span1 * tand(Geo.Lambda);

    Geo.startx = [0, x1];
    Geo.starty = [0, span1];
    Geo.startz = [0, 0];
    Geo.c_root = Geo.c_r;
    
    % Airfoils
    Geo.Airfoil_root = readXPath(xpath, doc, '//wing/sections/section[1]/elements/element/airfoilUID', 'string');
    Geo.Airfoil_tip  = readXPath(xpath, doc, '//wing/sections/section[last()]/elements/element/airfoilUID', 'string');
    Geo.Airfoil = {Geo.Airfoil_root, Geo.Airfoil_tip};

    span1 = y_tip - Geo.bf;

    Geo.span      = [span1, Geo.bf];


    Geo.TR        = [0.5891, 0.7059];
    Geo.Lambda_c4 = [20, 20];
    Geo.Gamma     = [-3, -3];
    Geo.Twist     = 0;

    % --- 6. TORNADO ---
    Geo.nx = readXPath(xpath, doc, '/cpacs/toolspecific/tool/nx', 'double');
    Geo.ny = readXPath(xpath, doc, '/cpacs/toolspecific/tool/ny', 'double');
    Geo.fnx = readXPath(xpath, doc, '/cpacs/toolspecific/tool/fnx', 'double');
    Geo.meshtype = str2num(readXPath(xpath, doc, '/cpacs/toolspecific/tool/meshtype', 'string'));
    Geo.flapped  = str2num(readXPath(xpath, doc, '/cpacs/toolspecific/tool/flapped', 'string'));
    Geo.fsym     = str2num(readXPath(xpath, doc, '/cpacs/toolspecific/tool/fsym', 'string'));
end

%-------------------------------------------------------------------------

function val = readXPath(xpath, doc, pathStr, type)
    import javax.xml.xpath.*
    try
        expression = xpath.compile(pathStr);
        result = char(expression.evaluate(doc, XPathConstants.STRING));
        if strcmp(type, 'double')
            val = str2double(result);
        else
            val = result;
        end
    catch
        val = NaN; % O valore di default se il path non esiste
    end
end