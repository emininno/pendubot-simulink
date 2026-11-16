% Symbolic derivation of the double pendulum (q1 actuated, q2 passive)
clear; clc
syms q1 q2 dq1 dq2 tau real
syms L1 lc1 m1 I1 L2 lc2 m2 I2 b1 b2 g real

q  = [q1; q2];   dq = [dq1; dq2];
x  = [q; dq];                                   % state vector
pv = [L1 lc1 m1 I1 L2 lc2 m2 I2 b1 b2 g];      % same order as parameter vector p

% --- Geometry: center-of-mass positions (q1 from downward vertical, y pointing up)
r1 = lc1*[sin(q1); -cos(q1)];
r2 = L1*[sin(q1); -cos(q1)] + lc2*[sin(q1+q2); -cos(q1+q2)];
v1 = jacobian(r1, q)*dq;
v2 = jacobian(r2, q)*dq;

% --- Energies
T = 1/2*m1*(v1.'*v1) + 1/2*I1*dq1^2 ...
  + 1/2*m2*(v2.'*v2) + 1/2*I2*(dq1 + dq2)^2;   % I2 rotates with absolute angle q1+q2
V = m1*g*r1(2) + m2*g*r2(2);
T = simplify(T);
E = simplify(T + V);                            % total energy (= Hamiltonian)

% --- Model matrices:  M*ddq + C*dq + G + F = [tau; 0]
M = simplify(hessian(T, dq));                   % T = 1/2 dq' M dq
G = simplify(jacobian(V, q).');
C = sym(zeros(2));                              % Christoffel symbols
for k = 1:2, for j = 1:2, for i = 1:2
    C(k,j) = C(k,j) + 1/2*( diff(M(k,j), q(i)) + diff(M(k,i), q(j)) ...
                          - diff(M(i,j), q(k)) )*dq(i);
end, end, end
C = simplify(C);
F = [b1*dq1; b2*dq2];                           % viscous friction

% --- Hamiltonian in canonical variables (for completeness)
syms p1 p2 real
pm = [p1; p2];
H  = simplify(1/2*pm.'*(M\pm) + V);             % H(q,p); with p = M*dq, H = E

% --- Linearization about the upright equilibrium [pi 0 0 0]
f  = [dq; M \ ([tau; 0] - C*dq - G - F)];       % xdot = f(x, tau)
A  = simplify(subs(jacobian(f, x),   [x; tau], [pi; 0; 0; 0; 0]));
B  = simplify(subs(jacobian(f, tau), [x; tau], [pi; 0; 0; 0; 0]));

% --- Automatic code generation (compatible with MATLAB Function blocks)
matlabFunction(E,    'File', 'pend_E',   'Vars', {x, pv});
matlabFunction(M,    'File', 'pend_M',   'Vars', {x, pv});
matlabFunction(C*dq, 'File', 'pend_Cdq', 'Vars', {x, pv});
matlabFunction(G,    'File', 'pend_G',   'Vars', {x, pv});
matlabFunction(A, B, 'File', 'pend_AB',  'Vars', {pv}, 'Outputs', {'A','B'});

disp('M ='), disp(M)
disp('E ='), disp(E)