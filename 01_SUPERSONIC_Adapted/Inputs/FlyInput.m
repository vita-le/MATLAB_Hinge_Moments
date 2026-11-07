function FlightInput = FlyInput(ID)

% Definition of different Flight conditions Identified by ID numbers

if ID == 0

    FlightInput.Mach     = 0.72;
    FlightInput.Altitude = 7620;        % 25000 ft
    FlightInput.alpha    = 0;           % deg, AoA
    FlightInput.delta    = 0;           % deg, deflection anle ailerons
    FlightInput.beta     = 0;           % deg, sidelsip angle

    FlightInput.P        = 0;           % Roll angular velocity P [deg/s]
    FlightInput.Q        = 0;           % Pitch angular velocity Q [deg/s]
    FlightInput.R        = 0;           % Yaw angular velocity R [deg/s]

elseif ID == 1 

    FlightInput.Mach     = 0.72;
    FlightInput.Altitude = 7620;        % 25000 ft
    FlightInput.alpha    = 1;           % deg
    FlightInput.delta    = -15;         % deg
    FlightInput.beta     = 0;           % deg, sidelsip angle


    FlightInput.P        = 0;           % Roll angular velocity P [deg/s]
    FlightInput.Q        = 0;           % Pitch angular velocity Q [deg/s]
    FlightInput.R        = 0;           % Yaw angular velocity R [deg/s]

elseif ID == 2 

    FlightInput.Mach     = 0.72;
    FlightInput.Altitude = 7620;        % 25000 ft
    FlightInput.alpha    = 1;           % deg
    FlightInput.delta    = 15;          % deg
    FlightInput.beta     = 0;           % deg, sidelsip angle


    FlightInput.P        = 0;           % Roll angular velocity P [deg/s]
    FlightInput.Q        = 0;           % Pitch angular velocity Q [deg/s]
    FlightInput.R        = 0;           % Yaw angular velocity R [deg/s]

elseif ID == 3

    FlightInput.Mach     = 0.84;
    FlightInput.Altitude = 7620;       
    FlightInput.alpha    = 1;            % deg
    FlightInput.delta    = 15;          % deg  
    FlightInput.beta     = 0;           % deg, sidelsip angle


    FlightInput.P        = 0;           % Roll angular velocity P [deg/s]
    FlightInput.Q        = 0;           % Pitch angular velocity Q [deg/s]
    FlightInput.R        = 0;           % Yaw angular velocity R [deg/s]

end

end