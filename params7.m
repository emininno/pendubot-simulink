% ===== Wall-mounted double pendulum, D = 1.8 m, CubeMars AK80-6 actuator =====
g  = 9.81;
L1 = 0.50;  L2 = 0.40;          % link lengths [m]
W1 = 0.03;  W2 = 0.03;          % link widths (for drawing and inertia) [m]
rho_l = 0.9;                    % link linear mass, conservative estimate [kg/m]
m1l = rho_l*L1;                 % link 1 mass [kg]
m2  = rho_l*L2;                 % link 2 mass [kg]
me  = 0.15;                     % elbow: bearing, hub, encoder [kg]
Jr  = 0.003;                    % rotor inertia reflected to the output [kg m^2]
b1  = 0.015;   b2 = 0.0015;     % viscous friction [N m s/rad]
% --- Equivalent link 1 (link + elbow mass + rotor) ---
m1  = m1l + me;
lc1 = (m1l*L1/2 + me*L1)/m1;                       % CoM distance from the base
I1  = m1l*(L1^2+W1^2)/12 + m1l*(L1/2-lc1)^2 ...    % inertia about the CoM
    + me*(L1-lc1)^2 + Jr;
% --- Link 2 ---
lc2 = L2/2;
I2  = m2*(L2^2+W2^2)/12;
p  = [L1 lc1 m1 I1 L2 lc2 m2 I2 b1 b2 g];          % 11 parameters
x0 = [0.01; 0; 0; 0];
% --- LQR about [pi 0 0 0] ---
M0 = [I1+I2+m1*lc1^2+m2*(L1+lc2)^2,  I2+m2*(lc2^2+L1*lc2);
    I2+m2*(lc2^2+L1*lc2),          I2+m2*lc2^2];
dG = -[(m1*lc1+m2*L1)*g + m2*lc2*g,  m2*lc2*g;
    m2*lc2*g,                    m2*lc2*g];
A = [zeros(2) eye(2); -M0\dG, -M0\diag([b1 b2])];
B = [0; 0; M0\[1; 0]];
[K, P] = lqr(A, B, diag([10 10 1 1]), 1);
% --- Control ---
kE      = 3.5;      % energy pumping gain
tau_sw  = 3;      % swing-up torque limit [N m] (< static torque ~3.6 N m)
tau_lqr = 12;     % balancing torque limit = AK80-6 peak [N m]
Vin = 20;  Vout = 60;           % LQR switching thresholds on e'*P*e
kp_dn = 2;  kd_dn = 1;          % PD gains for the return to the bottom
cpar = [kE tau_sw tau_lqr Vin Vout kp_dn kd_dn];
% --- Encoders ---
N_red  = 6;                         % AK80-6 gear ratio
dq_enc = [2*pi/(2^14*N_red), 2*pi/2^14];   % resolution [rad] for q1, q2
fc_vel = 30;                        % velocity filter cutoff [Hz]
Ts     = 1e-3;                      % sampling period [s]
encpar = [dq_enc fc_vel Ts];