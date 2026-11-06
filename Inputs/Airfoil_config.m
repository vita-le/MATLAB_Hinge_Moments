function AirfoilInput = Airfoil_config(ID)

if ID == 18.2 || ID == 18.1

    % --- NACA 64A210 -----------------------------------------------------
    AirfoilInput.name      = 'NACA 64A 210';
    AirfoilInput.filename  = 'N64210.dat';   
    AirfoilInput.t_c       = 0.10;
    AirfoilInput.Cla_data  = 0.10385 * 180/pi;   % [rad^-1]

end


