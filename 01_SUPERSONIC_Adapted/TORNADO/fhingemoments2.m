function [output] = fhingemoments2(rudder, results, lattice, geo, state)
% FHINGEMOMENTS2 Calculates aerodynamic hinge moments and coefficients.
% Uses 3D vector projection for accurate results on swept/dihedral wings.

    %% --- INITIALIZATION ---
    q_inf = 0.5 * state.rho * state.AS^2; 
    mForces = results.F;                 
    
    [I, K] = find(geo.flapped');
    try
        wing = K(rudder);
        division = I(rudder);
    catch
        error('Rudder index %d not found.', rudder);
    end

    %% --- 1. PRESSURE CENTER COORDINATES ---
    % Midpoint of the bound vortex (segments 4 and 5 in Tornado)
    VP_all = squeeze((lattice.VORTEX(:, 4, :) + lattice.VORTEX(:, 5, :)) / 2);

    %% --- 2. TORNADO INDEXING LOGIC ---
    t = 1; r = 0;
    [q6, q7] = size(geo.nx);
    nr = ((geo.nx + geo.fnx) .* geo.ny) .* (1 + geo.symetric' * ones(1, q7));
    
    for i = 1:q6
        for j = 1:q7
            if geo.flapped(i,j) == 1
                r = r + 1;
                if r == rudder, break; end
            end
            if r < rudder, t = t + nr(i,j); end
        end
        if r == rudder, break; end
    end

    nx = geo.nx(wing, division);
    ny = geo.ny(wing, division);
    fnx = geo.fnx(wing, division);
    nnx = nx + fnx;        
    sym = geo.symetric(wing);

    %% --- 3. HINGE LINE DEFINITION ---
    A_hinge = squeeze(lattice.XYZ(t + nx, 1, :))'; 
    B_hinge = squeeze(lattice.XYZ(t + (ny-1)*nnx + nx, 2, :))';
    h_hat = (B_hinge - A_hinge) / norm(B_hinge - A_hinge);

    %% --- 4. MOMENT CALCULATION (RIGHT SIDE) ---
    M_sum = 0;
    all_VP = []; all_VPP = [];
    
    for i = 1:ny
        strip_start = t + (i-1)*nnx;
        idx_flap = (strip_start + nx) : (strip_start + nnx - 1);
        
        for idx = idx_flap
            F_p = mForces(idx, :); 
            P_p = VP_all(idx, :);  
            
            % Orthogonal projection onto hinge line
            rel_pos = P_p - A_hinge;
            P_pivot = A_hinge + dot(rel_pos, h_hat) * h_hat;
            
            % Moment vector calculation: r x F
            M_vec = cross(P_p - P_pivot, F_p);
            M_sum = M_sum + dot(M_vec, h_hat);
            
            all_VP = [all_VP; P_p];
            all_VPP = [all_VPP; P_pivot];
        end
    end

    %% --- 5. SYMMETRY (LEFT SIDE) ---
    M_sum_left = 0;
    all_VP_L = []; all_VPP_L = [];
    if sym
        t_sym = t + nnx * ny;
        h_hat_L = h_hat .* [1, -1, 1];   
        A_hinge_L = A_hinge .* [1, -1, 1]; 
        
        for i = 1:ny
            strip_start = t_sym + (i-1)*nnx;
            idx_flap = (strip_start + nx) : (strip_start + nnx - 1);
            for idx = idx_flap
                F_p = mForces(idx, :);
                P_p = VP_all(idx, :);
                P_pivot = A_hinge_L + dot(P_p - A_hinge_L, h_hat_L) * h_hat_L;
                M_sum_left = M_sum_left + dot(cross(P_p - P_pivot, F_p), h_hat_L);
                all_VP_L = [all_VP_L; P_p];
                all_VPP_L = [all_VPP_L; P_pivot];
            end
        end
    end

    %% --- 6. GEOMETRIC COEFFICIENTS AND OUTPUT ---
    c_root_w = geo.c(wing); 
    if division > 1, c_root_w = c_root_w * prod(geo.T(wing, 1:division-1)); end
    c_tip_w = c_root_w * geo.T(wing, division);
    
    fc = geo.fc(wing, division); 
    S_f = geo.b(wing, division) * (c_root_w*fc + c_tip_w*fc) / 2;
    c_f = (c_root_w*fc + c_tip_w*fc) / 2;

    offset = 0; 
    output.M = [M_sum + offset, M_sum_left + offset];
    output.coeff = output.M ./ (q_inf * S_f * c_f);

%% --- 7. HIDDEN PLOT GENERATION (Isolated) ---
    %Hidden and separate figure for ispection
    h_fig = figure('Name', ['Hinge Moment - Rudder ', num2str(rudder)], ...
                   'Visible', 'off', ...
                   'HandleVisibility', 'off', ... 
                   'IntegerHandle', 'off'); 

    
    ax = axes('Parent', h_fig); 
    hold(ax, 'on'); grid(ax, 'on');
    
    
    plot3(ax, lattice.XYZ(:,:,1)', lattice.XYZ(:,:,2)', lattice.XYZ(:,:,3)', 'k:', 'HandleVisibility', 'off');
    plot3(ax, all_VP(:,1), all_VP(:,2), all_VP(:,3), 'ro', 'MarkerSize', 4, 'DisplayName', 'Pressure Centers');
    plot3(ax, all_VPP(:,1), all_VPP(:,2), all_VPP(:,3), 'b^', 'DisplayName', 'Hinge Projections');
    line(ax, [A_hinge(1) B_hinge(1)], [A_hinge(2) B_hinge(2)], [A_hinge(3) B_hinge(3)], 'Color', 'g', 'LineWidth', 3, 'DisplayName', 'Hinge Line');
    
    if sym
        plot3(ax, all_VP_L(:,1), all_VP_L(:,2), all_VP_L(:,3), 'ro', 'HandleVisibility', 'off');
        plot3(ax, all_VPP_L(:,1), all_VPP_L(:,2), all_VPP_L(:,3), 'b^', 'HandleVisibility', 'off');
        A_L = A_hinge .* [1 -1 1]; B_L = B_hinge .* [1 -1 1];
        line(ax, [A_L(1) B_L(1)], [A_L(2) B_L(2)], [A_L(3) B_L(3)], 'Color', 'g', 'LineWidth', 3, 'HandleVisibility', 'off');
    end
    
    view(ax, 3); axis(ax, 'equal'); legend(ax, 'show');
    xlabel(ax, 'X [m]'); ylabel(ax, 'Y [m]'); zlabel(ax, 'Z [m]');
    
    output.fig_handle = h_fig;
end