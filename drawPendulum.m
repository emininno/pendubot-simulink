function drawPendulum(q1, q2, L1, W1, L2, W2, tau, tauMax)
% Draws the double pendulum with a torque gauge and optionally records an animated GIF.
% q1: absolute angle of link 1 from the downward vertical (CCW +) [rad]
% q2: angle of link 2 relative to link 1 [rad]
% L1,W1,L2,W2: link lengths and widths [m]
% tau: torque applied at joint 1 [N m], tauMax: gauge full scale [N m]
% Add "clear drawPendulum" to the model StartFcn to restart the GIF on every run.

% --- GIF recording settings
recordGif = true;                   % set to true to record
gifFile   = 'docs/animation.gif';    % output file
gifEvery  = 2;                       % keep one frame every gifEvery calls
Ts_anim   = 0.02;                    % sample time of the animation block [s]

% --- Torque gauge geometry (annular sector around the base joint)
rOut = 0.20*(L1 + L2);               % outer radius [m]
rIn  = 0.14*(L1 + L2);               % inner radius [m]
a0   = pi/2;                         % start angle: pointing up

persistent fig ax hL1 hL2 hJ1 hJ2 hTxt hGauge hTauTxt k
% Create the figure on the first call (or if it has been closed)
if isempty(fig) || ~isgraphics(fig)
    fig = figure('Name','Double pendulum','NumberTitle','off','Color','w');
    ax  = axes('Parent',fig);
    hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'on');
    xlabel(ax,'x [m]'); ylabel(ax,'y [m]');
    % Gauge background ring (drawn first, so it stays behind the links)
    [Xr,Yr] = annularSector(rIn, rOut, 0, 2*pi);
    patch(ax,'XData',Xr,'YData',Yr,'FaceColor',[0.92 0.92 0.92],'EdgeColor','none');
    plot(ax,[0 0],[rIn rOut]*1.0,'Color',[0.6 0.6 0.6],'LineWidth',1);   % zero mark
    hGauge = patch(ax,'XData',NaN,'YData',NaN,'FaceColor',[0.2 0.7 0.3], ...
        'EdgeColor','none','FaceAlpha',0.85);
    hTauTxt = text(ax,0,-(rOut + 0.04*(L1+L2)),'', ...
        'HorizontalAlignment','center','VerticalAlignment','top','FontWeight','bold');
    % Links and joints
    hL1 = patch(ax,'XData',zeros(4,1),'YData',zeros(4,1), ...
        'FaceColor',[0.20 0.45 0.80],'EdgeColor','k','FaceAlpha',0.9);
    hL2 = patch(ax,'XData',zeros(4,1),'YData',zeros(4,1), ...
        'FaceColor',[0.85 0.35 0.20],'EdgeColor','k','FaceAlpha',0.9);
    hJ1 = plot(ax,0,0,'ko','MarkerFaceColor','k','MarkerSize',8);  % actuated joint (base)
    hJ2 = plot(ax,0,0,'ko','MarkerFaceColor','w','MarkerSize',7);  % passive joint
    hTxt = title(ax,'');
    k = 0;                                                         % restart frame counter
end
if isempty(k), k = 0; end
k = k + 1;                                                         % call counter

% Axis limits based on the current link lengths
R = 1.15*(L1 + L2) + max(W1,W2);
set(ax,'XLim',[-R R],'YLim',[-R R]);

% --- Torque gauge: sector span proportional to tau, CCW for tau > 0
r    = max(min(tau/tauMax, 1), -1);              % normalized and clipped torque
span = r*pi;                                     % +-180 deg at full scale
if abs(span) > 1e-3
    [Xg,Yg] = annularSector(rIn, rOut, a0, a0 + span);
else
    Xg = NaN; Yg = NaN;                          % nothing to draw near zero
end
col = (1 - abs(r))*[0.20 0.70 0.30] + abs(r)*[0.85 0.15 0.15];   % green -> red
set(hGauge,'XData',Xg,'YData',Yg,'FaceColor',col);
set(hTauTxt,'String',sprintf('\\tau = %+5.2f N m', tau));

% Absolute angles of the two links
th1 = q1;
th2 = q1 + q2;
% Link 1: from the base (0,0) to joint 2
p0 = [0; 0];
[X1,Y1,p1] = linkRect(p0, th1, L1, W1);
% Link 2: from joint 2 to the tip
[X2,Y2,~]  = linkRect(p1, th2, L2, W2);
set(hL1,'XData',X1,'YData',Y1);
set(hL2,'XData',X2,'YData',Y2);
set(hJ1,'XData',p0(1),'YData',p0(2));
set(hJ2,'XData',p1(1),'YData',p1(2));
uistack(hJ1,'top'); uistack(hJ2,'top');
set(hTxt,'String',sprintf('q_1 = %6.1f°   q_2 = %6.1f°', rad2deg(q1), rad2deg(q2)));

if recordGif && mod(k-1, gifEvery) == 0
    drawnow                                     % full redraw before capturing
    % Capture the frame
    frame = getframe(fig);
    [imind, cm] = rgb2ind(frame2im(frame), 256);
    % Create or append to the GIF (delay matches simulated time)
    delay = gifEvery*Ts_anim;
    if k == 1
        [d,~,~] = fileparts(gifFile);
        if ~isempty(d) && ~isfolder(d), mkdir(d); end
        imwrite(imind, cm, gifFile, 'gif', 'Loopcount', inf, 'DelayTime', delay);
    else
        imwrite(imind, cm, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
    end
else
    drawnow limitrate
end
end

function [X,Y,pEnd] = linkRect(p0, th, L, W)
% Rectangle of length L and width W starting at p0 with angle th
u = [ sin(th); -cos(th)];   % direction along the link (th=0 -> pointing down)
n = [ cos(th);  sin(th)];   % normal to the link
pEnd = p0 + L*u;
C = [p0 + n*W/2, p0 - n*W/2, pEnd - n*W/2, pEnd + n*W/2];
X = C(1,:)'; Y = C(2,:)';
end

function [X,Y] = annularSector(rIn, rOut, a1, a2)
% Annular sector between radii rIn and rOut, from angle a1 to a2 (standard x-y angles)
n = max(2, ceil(abs(a2 - a1)/(pi/60)) + 1);  % about 3 deg per segment
a = linspace(a1, a2, n);
X = [rOut*cos(a), fliplr(rIn*cos(a))]';
Y = [rOut*sin(a), fliplr(rIn*sin(a))]';
end