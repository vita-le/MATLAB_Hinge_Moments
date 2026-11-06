function Geo = readGeoFromCPACS(xmlFile)
% READTORNADOGEOFROMCPACS 
% Read the toolspecific Tornado Geo block from CPACS.
%
%   Geo = readTornadoGeoFromCPACS("F18Tail_TornadoTemplate.xml")
%
% The XML stores the authoritative Tornado/VLM fields in:
%   /cpacs/toolspecific/tool[name="tornadoGeometry"]/tornadoGeometry/geo

doc = xmlread(xmlFile);
geoNode = findTornadoGeoNode(doc);

Geo.name = readText(geoNode, 'name');

Geo.b       = readScalar(geoNode, 'b');
Geo.S       = readScalar(geoNode, 'S');
Geo.Lambda  = readScalar(geoNode, 'Lambda');
Geo.c_r     = readScalar(geoNode, 'c_r');
Geo.c_t     = readScalar(geoNode, 'c_t');
Geo.TR_full = readScalar(geoNode, 'TR_full');

Geo.S_f   = readScalar(geoNode, 'S_f');
Geo.hinge = readScalar(geoNode, 'hinge');
Geo.y_i   = readScalar(geoNode, 'y_i');
Geo.y_o   = readScalar(geoNode, 'y_o');
Geo.bf    = readScalar(geoNode, 'bf');

Geo.x_CG = readScalar(geoNode, 'x_CG');
Geo.y_CG = readScalar(geoNode, 'y_CG');
Geo.z_CG = readScalar(geoNode, 'z_CG');

Geo.x_ref = readScalar(geoNode, 'x_ref');
Geo.y_ref = readScalar(geoNode, 'y_ref');
Geo.z_ref = readScalar(geoNode, 'z_ref');

Geo.nwing    = readScalar(geoNode, 'nwing');
Geo.nelem    = readVector(geoNode, 'nelem');
Geo.symetric = readVector(geoNode, 'symetric');
Geo.allmove  = readVector(geoNode, 'allmove');

Geo.startx = readVector(geoNode, 'startx');
Geo.starty = readVector(geoNode, 'starty');
Geo.startz = readVector(geoNode, 'startz');

Geo.c_root = readVector(geoNode, 'c_root');

Geo.Airfoil = readTextList(geoNode, 'Airfoil');

Geo.Airfoil_root = readText(geoNode, 'Airfoil_root');
Geo.Airfoil_tip  = readText(geoNode, 'Airfoil_tip');

Geo.span      = readVector(geoNode, 'span');
Geo.TR        = readVector(geoNode, 'TR');
Geo.Lambda_c4 = readVector(geoNode, 'Lambda_c4');
Geo.Gamma     = readVector(geoNode, 'Gamma');

Geo.Twist = readScalar(geoNode, 'Twist');

Geo.nx       = readScalar(geoNode, 'nx');
Geo.ny       = readScalar(geoNode, 'ny');
Geo.fnx      = readScalar(geoNode, 'fnx');
Geo.meshtype = readVector(geoNode, 'meshtype');

Geo.flapped = readVector(geoNode, 'flapped');
Geo.fc      = readScalar(geoNode, 'fc');
Geo.fsym    = readVector(geoNode, 'fsym');

end

function geoNode = findTornadoGeoNode(doc)
toolNodes = doc.getElementsByTagName('tool');
geoNode = [];

for idx = 0:toolNodes.getLength - 1
    toolNode = toolNodes.item(idx);
    toolName = readOptionalText(toolNode, 'name');

    if strcmp(toolName, 'tornadoGeometry')
        tornadoNode = firstChildElement(toolNode, 'tornadoGeometry');
        geoNode = firstChildElement(tornadoNode, 'geo');
        return
    end
end

error('readTornadoGeoFromCPACS:MissingGeoBlock', ...
    'Could not find toolspecific/tool[name="tornadoGeometry"]/tornadoGeometry/geo.');
end

function value = readScalar(parentNode, tagName)
raw = readText(parentNode, tagName);
value = str2double(raw);

if isnan(value)
    error('readTornadoGeoFromCPACS:InvalidScalar', ...
        'Field "%s" is not a valid scalar number: %s', tagName, raw);
end
end

function value = readVector(parentNode, tagName)
raw = readText(parentNode, tagName);
parts = strsplit(strtrim(raw), ';');
value = str2double(parts);

if any(isnan(value))
    error('readTornadoGeoFromCPACS:InvalidVector', ...
        'Field "%s" contains a non-numeric value: %s', tagName, raw);
end
end

function value = readTextList(parentNode, tagName)
raw = readText(parentNode, tagName);
value = strtrim(strsplit(strtrim(raw), ';'));
value = value(~cellfun('isempty', value));
end

function value = readText(parentNode, tagName)
value = readOptionalText(parentNode, tagName);

if isempty(value)
    error('readTornadoGeoFromCPACS:MissingField', ...
        'Missing required XML field "%s".', tagName);
end
end

function value = readOptionalText(parentNode, tagName)
childNode = firstChildElement(parentNode, tagName);

if isempty(childNode)
    value = '';
else
    value = strtrim(char(childNode.getTextContent));
end
end

function childNode = firstChildElement(parentNode, tagName)
childNode = [];
children = parentNode.getChildNodes;

for idx = 0:children.getLength - 1
    candidate = children.item(idx);

    if candidate.getNodeType == candidate.ELEMENT_NODE && strcmp(char(candidate.getNodeName), tagName)
        childNode = candidate;
        return
    end
end
end