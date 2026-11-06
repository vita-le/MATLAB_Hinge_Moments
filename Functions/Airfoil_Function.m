function AirfoilInput = Airfoil_Function(AirfoilInput)
%--------------------------------------------------
% Airfoil_Function - Specialized for Two-Block Files
%--------------------------------------------------

    % 1. Setup Data
    x = AirfoilInput.x(:);
    y = AirfoilInput.y(:);
    
    % 2. Separate Upper and Lower Blocks
    % Since the file lists Upper (0->1) then Lower (0->1), 
    % we find the point where the X-coordinates reset to zero.
    
    % Find all indices where x is 0 (Leading Edge)
    idx_zero = find(x == 0);
    
    if length(idx_zero) >= 2
        % Case: File has two distinct blocks starting at 0
        % Upper is usually the first block
        xu = x(idx_zero(1) : idx_zero(2)-1);
        yu = y(idx_zero(1) : idx_zero(2)-1);
        
        % Lower is the second block
        xl = x(idx_zero(2) : end);
        yl = y(idx_zero(2) : end);
    else
        % Fallback: If the logic above fails, use the min(x) split
        [~, idx_LE] = min(x);
        xu = x(1:idx_LE); yu = y(1:idx_LE);
        xl = x(idx_LE:end); yl = y(idx_LE:end);
    end

    % 3. Clean and Sort
    % Remove any potential NaNs that readmatrix might have left from headers
    valid_u = ~isnan(xu); xu = xu(valid_u); yu = yu(valid_u);
    valid_l = ~isnan(xl); xl = xl(valid_l); yl = yl(valid_l);
    
    % Ensure they are sorted 0 -> 1
    [xu, iu] = sort(xu); yu = yu(iu);
    [xl, il] = sort(xl); yl = yl(il);
    
    % 4. Trailing Edge Angle Calculation
    % We search near the end of the chord (maxX)
    maxX = max(x);
    
    % Calculate using the individual slope method (more robust)
    phi_1 = calculate_TE_angle(xu, yu, xl, yl, 0.90*maxX, 0.99*maxX);
    phi_2 = calculate_TE_angle(xu, yu, xl, yl, 0.95*maxX, 0.99*maxX);
    
    % 5. Save Results
    AirfoilInput.Phi_TE_1_rad = phi_1;
    AirfoilInput.Phi_TE_2_rad = phi_2;
    AirfoilInput.Phi_TE_1_deg = rad2deg(phi_1);
    AirfoilInput.Phi_TE_2_deg = rad2deg(phi_2);
    
    % Print for verification
    fprintf('Detected %d upper points and %d lower points.\n', length(xu), length(xl));
    fprintf('TE Angle (90-99%%): %.4f deg\n', AirfoilInput.Phi_TE_1_deg);
    fprintf('TE Angle (95-99%%): %.4f deg\n', AirfoilInput.Phi_TE_2_deg);
end

function phi = calculate_TE_angle(xu, yu, xl, yl, x_start, x_end)
    % Filter points in the range
    mask_u = (xu >= x_start & xu <= x_end);
    mask_l = (xl >= x_start & xl <= x_end);
    
    xu_f = xu(mask_u); yu_f = yu(mask_u);
    xl_f = xl(mask_l); yl_f = yl(mask_l);
    
    % Fallback if range is empty
    if numel(xu_f) < 2 || numel(xl_f) < 2
        xu_f = xu(max(1, end-3):end);
        yu_f = yu(max(1, end-3):end);
        xl_f = xl(max(1, end-3):end);
        yl_f = yl(max(1, end-3):end);
    end
    
    % Fit lines to the tail points
    pu = polyfit(xu_f, yu_f, 1);
    pl = polyfit(xl_f, yl_f, 1);
    
    % Angle = atan(upper_slope) - atan(lower_slope)
    phi = abs(atan(pu(1)) - atan(pl(1)));
end