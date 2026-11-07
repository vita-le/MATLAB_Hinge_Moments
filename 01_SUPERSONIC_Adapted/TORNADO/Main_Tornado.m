
%% ========================================================================
%                           MAIN SCRIPT
%  Tornado Sped-Up
%  last updated: 13/04/2025
%  by: Andrea Vitale
%  removed text-based menu
%  ========================================================================

function Main_Tornado(GeomInput, Flight)

% initializing variables
geo.version=136;             %version of geometry file
geo.name=[];                 %Geometry name string
geo.project=[];
geo.allmove=0;              %Allmoving surface set bit
geo.allmove_origin=[0 0 0]; %Origin of rotation for allmoving surface
geo.allmove_axis=[0 0 0];   %Hingeline for allmoving surface
geo.allmove_symetric=0;     %Symmetry for allmoving deflection
geo.allmove_def=0;          %Deflection of allmovin surface
geo.fnx=0;				    %number of panels on flap chords (2d array)
geo.ny=1;					%number of panels in span (2d array)
geo.nx=1;					%number of panels on chord (2d array)
geo.fsym=0;				    %flap deflection symmetry boolean bit  (2d array)
geo.fc=0;					%flap chord in percent of wingchord (2d array)
geo.flapped=0;			    %flapped partition(wing part) boolean bit (2d array)
geo.TW(:,:,1)=0;	    	%partition twist (3d array)<1 inboard, 2 outboard>
geo.TW(:,:,2)=0;
geo.foil(:,:,1)={'0'};		%Partition airfoils (3d array)	
geo.foil(:,:,2)={'0'};		%1 inboard, 2 outboard
geo.T=1;					%Taper ratio (2d array)
geo.SW=0;					%Sweep (2d array)
geo.c=1;					%Root chord (2d array)
geo.dihed=0;				%Dihedral (2d array)	
geo.b=1;					%span(distance root->tip chord) (2d array)
geo.symetric=1;			    %Wing symmetry boolean bit (2d array)
geo.startx=0;		    	%Partition starting coordinate (2d array)
geo.starty=0;		    	% ---"----
geo.startz=0;		    	% ---"----
geo.nwing=1;				%number of wings (scalar)
geo.nelem=1;				%number of partitions on each wing (1d array)
geo.flap_vector=0;          %Flap deflection vector 
geo.ref_point=[0 0 0];      %System reference point
geo.CG=[0 0 0];             %System center of gravity (around which all rotations occur)
geo.meshtype=0;
geo.structure=[];           %Internal structure of wing number 1;
geo.prop=[];                %propeller geometry

state.AS=0;					%airspeed
state.alpha=0;				%angle of attack
state.betha=0;				%angle of sideslip
state.P=0;					%roll angluar rate	
state.Q=0;					%pitch angular rate
state.R=0;					%Yaw angular rate
state.alphadot=0;           %Angle of attack time derivative
state.bethadot=0;           %Angle of sidesliptime derivative
state.ALT=0;                %Altitude, meters.
state.rho=0;                %Air density, kg/m^3.
state.pgcorr=0;             %Prandtl-Glauert compressibillity correction.

lattice.XYZ=0;				%panel corner matrix (2d array)
lattice.COLLOC=0;           %collocation point matrix
lattice.VORTEX=0;           %Vortex sling cornerpoint position matrix
lattice.N=0;                %Airfoil collocation point normal direction matrix

ref.S_ref=0;                %reference area;
ref.C_mac=0;                %mean aerodynamic choord
ref.mac_pos=0;              %start position of mac
ref.C_mgc=0;                %mean geometric chord
ref.b_ref=0;                %reference span

results.dwcond=0;           %computation result memory structure.    

loop=1;                     %program run bit

stat=0;                     %Status variable, 0 if geometry and lattice is inconsistent


%-------------------- Setup Geometry

[geo]=inpt20(geo, GeomInput);
geo = setcontrol(geo);


%-------------------- Setup State

[state]=statesetup3(state, Flight);


%-------------------- Lattice Generation

lattice_type = 0;                                                                 % Set Lattice Setup 0-Tornado, 1-VLM standard

if lattice_type == 0
    disp('Freestream following wake, Tornado method Active')
else
    disp('Fixed wake, standard VLM method Active')
end

[lattice,ref]=fLattice_setup2(geo,state,lattice_type);


%-------------------- Process

JID = 'JID_MANUAL_001';
solverloop5(results,lattice_type,JID,lattice,state,geo,ref);                          %Static State


resultplot(18, JID)                                                        % Hinge Moment estimation

% 
% %-------------------- Plotting
%  geometryplot(lattice,geo,ref);                                           %Plot Geometry
%  resultplot(1, JID)                                                       %Static comp. Plot
% % 

end

