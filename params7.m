% ===== Doppio pendolo da parete, D = 1.8 m, attuatore CubeMars AK80-6 =====
g  = 9.81;
L1 = 0.50;  L2 = 0.40;          % lunghezze link [m]
W1 = 0.03;  W2 = 0.03;          % larghezze (per disegno e inerzia) [m]
rho_l = 0.9;                    % massa lineare link, stima per eccesso [kg/m]
m1l = rho_l*L1;                 % massa link 1 [kg]
m2  = rho_l*L2;                 % massa link 2 [kg]
me  = 0.15;                     % gomito: cuscinetto, mozzo, encoder [kg]
Jr  = 0.003;                    % inerzia rotore riportata all'uscita [kg m^2]
b1  = 0.015;   b2 = 0.0015;       % attrito viscoso [N m s/rad]

% --- Link 1 equivalente (link + massa al gomito + rotore) ---
m1  = m1l + me;
lc1 = (m1l*L1/2 + me*L1)/m1;                       % baricentro dalla base
I1  = m1l*(L1^2+W1^2)/12 + m1l*(L1/2-lc1)^2 ...    % inerzia attorno al baricentro
    + me*(L1-lc1)^2 + Jr;
% --- Link 2 ---
lc2 = L2/2;
I2  = m2*(L2^2+W2^2)/12;

p  = [L1 lc1 m1 I1 L2 lc2 m2 I2 b1 b2 g];          % 11 parametri
x0 = [0.01; 0; 0; 0];

% --- LQR attorno a [pi 0 0 0] ---
M0 = [I1+I2+m1*lc1^2+m2*(L1+lc2)^2,  I2+m2*(lc2^2+L1*lc2);
    I2+m2*(lc2^2+L1*lc2),          I2+m2*lc2^2];
dG = -[(m1*lc1+m2*L1)*g + m2*lc2*g,  m2*lc2*g;
    m2*lc2*g,                    m2*lc2*g];
A = [zeros(2) eye(2); -M0\dG, -M0\diag([b1 b2])];
B = [0; 0; M0\[1; 0]];
[K, P] = lqr(A, B, diag([10 10 1 1]), 1);

% --- Controllo ---
kE      = 5;      % guadagno pompaggio di energia
tau_sw  = 2;      % limite coppia in swing-up [N m] (< coppia statica ~3 N m)
tau_lqr = 12;     % limite in bilanciamento = picco AK80-6 [N m]
Vin = 20;  Vout = 60;
cpar = [kE tau_sw tau_lqr Vin Vout];
kp_dn = 2;  kd_dn = 1;          % PD per il ritorno in basso
cpar = [kE tau_sw tau_lqr Vin Vout kp_dn kd_dn];

% --- Encoder ---
N_red  = 6;                         % riduzione AK80-6
dq_enc = [2*pi/(2^14*N_red), 2*pi/2^14];   % risoluzione [rad] q1, q2
fc_vel = 30;                        % taglio filtro velocità [Hz]
Ts     = 1e-3;                      % periodo di campionamento [s]
encpar = [dq_enc fc_vel Ts];