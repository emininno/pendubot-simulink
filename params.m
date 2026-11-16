% % Parametri del doppio pendolo
% L1 = 0.5;   W1 = 0.05;  m1 = 1.0;   % link 1 (attuato alla base)
% L2 = 0.5;   W2 = 0.04;  m2 = 1.0;   % link 2 (passivo)
% b1 = 0.15;   b2 = 0.15;               % attrito viscoso [N*m*s/rad]
% g  = 9.81;
% 
% p  = [L1 W1 m1 L2 W2 m2 b1 b2 g];   % vettore parametri per il blocco dinamica
% x0 = [pi/2; 0; 0; 0];               % stato iniziale [q1 q2 q1dot q2dot]
% Parametri del doppio pendolo
L1 = 0.5;   W1 = 0.05;  m1 = 1.0;   % link 1 (attuato alla base)
L2 = 0.5;   W2 = 0.04;  m2 = 1.0;   % link 2 (passivo)
b1 = 0.05;  b2 = 0.05;              % attrito viscoso [N*m*s/rad]
g  = 9.81;

p  = [L1 W1 m1 L2 W2 m2 b1 b2 g];   % vettore parametri per dinamica e controllo
x0 = [0.01; 0; 0; 0];               % stato iniziale: appeso, quasi fermo

% --- LQR attorno alla posizione invertita [pi 0 0 0] ---
lc1 = L1/2;  lc2 = L2/2;
I1 = m1*(L1^2 + W1^2)/12;  I2 = m2*(L2^2 + W2^2)/12;
M0 = [I1+I2+m1*lc1^2+m2*(L1+lc2)^2,  I2+m2*(lc2^2+L1*lc2);
    I2+m2*(lc2^2+L1*lc2),          I2+m2*lc2^2];
dG = -[(m1*lc1+m2*L1)*g + m2*lc2*g,  m2*lc2*g;
    m2*lc2*g,                    m2*lc2*g];
A = [zeros(2) eye(2); -M0\dG, -M0\diag([b1 b2])];
B = [0; 0; M0\[1; 0]];
Q = diag([10 10 1 1]);  R = 1;
[K, P] = lqr(A, B, Q, R);           % tau = -K*e,  P = soluzione di Riccati

% --- Parametri swing-up e commutazione ---
kp = 20;  kd = 2*sqrt(kp);          % PD sul link 1
ke = 3;                             % guadagno energy control
dE = 0.03;                          % energia target = Etop*(1+dE), compensa l'attrito
tau_max = 20;                       % saturazione coppia [N*m]
Vin = 20;  Vout = 60;               % soglie di commutazione su e'*P*e
cpar = [kp kd ke dE tau_max Vin Vout];