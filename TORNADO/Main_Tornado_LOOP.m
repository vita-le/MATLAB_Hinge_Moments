function out = Main_Tornado_LOOP(GeomInput, Flight, JID)
    if nargin < 3 || isempty(JID), JID = 'JID_ERROR'; end
    global settings
    if isempty(settings) || ~isfield(settings, 'odir') || isempty(settings.odir)
        settings.odir = 'output';
    end

    % --- Geometry & State Setup ---
    geo = struct();
    [geo] = inpt20(geo, GeomInput);
    geo = setcontrol2(geo, Flight.delta);
    state = struct();
    [state] = statesetup3(state, Flight);
    
    % --- Lattice & Solver ---
                                                  
    [lattice,ref] = fLattice_setup2(geo,state,0);                % fixed to Vortex Sling (0)
    solverloop5([],1,JID,lattice,state,geo,ref);
    
    % --- Load and Extract Hinge Moment ---
    fname = [JID, '-Cx.mat'];
    fpath = fullfile(settings.odir, fname);
    S = load(fpath);
    
    data_hinge = fhingemoments2(1, S.results, S.lattice, S.geo, S.state); 
    
    % --- Output Collection ---
    out.JID     = JID;
    out.state   = S.state;
    out.ref     = S.ref;
    out.geo     = S.geo;
    out.lattice = S.lattice;
    out.Hinge.M          = data_hinge.M;
    out.Hinge.coeff      = data_hinge.coeff;
    out.Hinge.fig_handle = data_hinge.fig_handle; % <--- Store plot handle

end
