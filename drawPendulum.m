function drawPendulum(q1, q2, L1, W1, L2, W2)
% Disegna il doppio pendolo.
% q1: angolo assoluto link 1 dalla verticale verso il basso (CCW +) [rad]
% q2: angolo relativo link 2 rispetto al link 1 [rad]
% L1,W1,L2,W2: lunghezza e larghezza dei link [m]

persistent fig ax hL1 hL2 hJ1 hJ2 hTxt

% Crea la figura alla prima chiamata (o se è stata chiusa)
if isempty(fig) || ~isgraphics(fig)
    fig = figure('Name','Doppio pendolo','NumberTitle','off','Color','w');
    ax  = axes('Parent',fig);
    hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'on');
    xlabel(ax,'x [m]'); ylabel(ax,'y [m]');
    hL1 = patch(ax,'XData',zeros(4,1),'YData',zeros(4,1), ...
        'FaceColor',[0.20 0.45 0.80],'EdgeColor','k','FaceAlpha',0.9);
    hL2 = patch(ax,'XData',zeros(4,1),'YData',zeros(4,1), ...
        'FaceColor',[0.85 0.35 0.20],'EdgeColor','k','FaceAlpha',0.9);
    hJ1 = plot(ax,0,0,'ko','MarkerFaceColor','k','MarkerSize',8);  % joint attuato (base)
    hJ2 = plot(ax,0,0,'ko','MarkerFaceColor','w','MarkerSize',7);  % joint passivo
    hTxt = title(ax,'');
end

% Limiti assi in base alle lunghezze correnti
R = 1.15*(L1 + L2) + max(W1,W2);
set(ax,'XLim',[-R R],'YLim',[-R R]);

% Angoli assoluti dei due link
th1 = q1;
th2 = q1 + q2;

% Link 1: dalla base (0,0) al joint 2
p0 = [0; 0];
[X1,Y1,p1] = linkRect(p0, th1, L1, W1);
% Link 2: dal joint 2 alla punta
[X2,Y2,~]  = linkRect(p1, th2, L2, W2);

set(hL1,'XData',X1,'YData',Y1);
set(hL2,'XData',X2,'YData',Y2);
set(hJ1,'XData',p0(1),'YData',p0(2));
set(hJ2,'XData',p1(1),'YData',p1(2));
uistack(hJ1,'top'); uistack(hJ2,'top');
set(hTxt,'String',sprintf('q_1 = %6.1f°   q_2 = %6.1f°', rad2deg(q1), rad2deg(q2)));

drawnow limitrate
end

function [X,Y,pEnd] = linkRect(p0, th, L, W)
% Rettangolo di lunghezza L e larghezza W che parte da p0 con angolo th
u = [ sin(th); -cos(th)];   % direzione lungo il link (th=0 -> verso il basso)
n = [ cos(th);  sin(th)];   % normale al link
pEnd = p0 + L*u;
C = [p0 + n*W/2, p0 - n*W/2, pEnd - n*W/2, pEnd + n*W/2];
X = C(1,:)'; Y = C(2,:)';
end