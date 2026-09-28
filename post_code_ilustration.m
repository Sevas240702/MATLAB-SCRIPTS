%% ============ ANIMACIÓN DE SEÑALES DE SIMULINK — ESTILO LIMPIO (para LinkedIn) ============
% Muestra TODAS las señales que guardó el Scope, animadas al mismo tiempo, con un
% diseño limpio: fondo blanco, sin cuadros ni cuadrícula, ejes con flecha.
% Puede exportar directamente un video MP4 listo para publicar.
%
% Cómo usarlo:
%   1) En el Scope: engranaje -> pestaña Logging -> "Log data to workspace",
%      Variable name: ScopeData. Formato: "Structure With Time" o "Dataset".
%   2) Simula el modelo.
%   3) Ejecuta este script (F5).
% Al ejecutarse, imprime en la ventana de comandos la lista de señales detectadas.
% =========================================================================================
 
%% ------------------------------- CONFIGURACIÓN ---------------------------------------
cfg.variable   = 'ScopeData';  % nombre con el que el Scope guarda los datos
cfg.modo       = 'scope';      % 'scope'     = una gráfica por cada entrada del Scope
                               % 'juntas'    = todas las señales en una sola gráfica
                               % 'separadas' = una gráfica por cada señal
cfg.titulo     = 'Controlled half-wave rectifier';   % '' = sin título
cfg.marca      = 'Ing. Sevastian Holguin';           % texto pequeño abajo (marca de agua), ej. '@sevas.automation'
cfg.nombres    = {'v_{AC}(t)', 'i_{charge}(t)', 'i_{freeDiode}(t)','i_{charge}(t)', 'v_{charge}(t)', 'Thi1_{+}(t)', 'Thi1_{-}(t)', 'D1_{+}(t)', 'D1_{-}(t)'};           % {} = etiquetas del Scope. Acepta subíndices estilo TeX:
                               %      {'v_{AC}(t)', 'i_{carga}(t)', 'v_{carga}(t)'}
cfg.unidades   = {'V', 'A', 'V'};           % {} = sin unidades; ej. {'V','A','V'}
cfg.paleta     = [0.12 0.47 0.71;   % azul
                  0.96 0.52 0.10;   % naranja
                  0.20 0.63 0.30;   % verde
                  0.10 0.10 0.10;   % negro
                  0.84 0.15 0.16;   % rojo
                  0.58 0.40 0.74;   % morado
                  0.55 0.34 0.29;   % café
                  0.89 0.47 0.76];  % rosa  (si hay más señales se generan colores extra)
cfg.duracion   = 6;       % segundos que dura la animación
cfg.fps        = 30;      % cuadros por segundo
cfg.ventana    = [];      % []   = se dibuja todo el tiempo de simulación
                          % 0.02 = ventana deslizante de 20 ms (efecto osciloscopio)
 
% --- Exportar ---
cfg.formato      = 'linkedin';  % 'linkedin' (4:5, ideal para el feed), 'cuadrado',
                                % 'vertical' (9:16, TikTok/Reels), 'horizontal' (16:9)
cfg.guardarVideo = false;       % true = guarda un MP4 (tarda un poco más que verlo)
cfg.archivoVideo = 'senales_animadas.mp4';
cfg.anchoVideo   = 1080;        % ancho del video en píxeles
cfg.pausaFinal   = 2;           % segundos que el video se queda en la imagen final
cfg.guardarGif   = true;
cfg.archivoGif   = 'senales_animadas.gif';
 
%% ------------------------------- ESTILO ----------------------------------------------
% Colores en RGB de 0 a 1 (un color 0-255 se divide entre 255: [18 18 30]/255).
est.fondo       = [1 1 1];            % fondo único (blanco)
est.ejes        = [0.15 0.15 0.15];   % ejes, flechas y título
est.textoSec    = [0.50 0.50 0.50];   % textos secundarios (escala, marca de agua)
est.grosorLinea = 1.8;
est.fuente      = 'Arial';
est.tamTitulo   = 22;
est.tamEtiqueta = 12;                 % nombres de las señales y la "t" del eje
est.tamEscala   = 9;                  % valores máx/mín junto al eje vertical
est.escala      = true;               % false = sin valores en el eje (aún más limpio)
est.punto       = true;               % punto que va trazando cada curva
est.valorEnVivo = false;              % true = muestra el valor instantáneo junto al nombre
 
% Tema oscuro (copia y pega sobre lo de arriba si lo prefieres):
%   est.fondo = [0.07 0.07 0.09]; est.ejes = [0.88 0.88 0.90]; est.textoSec = [0.55 0.55 0.60];
%   cfg.paleta = [0.30 0.70 1.00; 1.00 0.62 0.25; 0.40 0.85 0.45; 0.95 0.95 0.95];
 
%% ------------------------------- OBTENER DATOS ---------------------------------------
sd = [];
if exist('out','var') && isa(out,'Simulink.SimulationOutput') && any(strcmp(out.who, cfg.variable))
    sd = out.get(cfg.variable);
elseif exist(cfg.variable,'var')
    sd = eval(cfg.variable);
end
 
S = struct('t', {}, 'y', {}, 'nombre', {}, 'grupo', {}, 'grupoNombre', {});
 
if isempty(sd)
    warning('No encontré "%s" en el workspace. Usando señales de ejemplo.', cfg.variable);
    t   = (0:1e-5:0.05)';
    vac = 311*sin(2*pi*60*t);
    S = agregarEntrada(S, t, vac,                        'Ejemplo: Vac', 1, 'Ejemplo: Vac');
    S = agregarEntrada(S, t, max(vac,0)/10,              'Ejemplo: CT',  2, 'Ejemplo: CT');
    S = agregarEntrada(S, t, [max(vac,0) max(-vac,0)],   'Ejemplo: VT',  3, 'Ejemplo: 2 señales juntas');
 
elseif isa(sd, 'Simulink.SimulationData.Dataset')          % formato Dataset
    for j = 1:sd.numElements
        el = sd.getElement(j);
        nombre = el.Name;
        if isempty(nombre), nombre = sprintf('Entrada %d', j); end
        S = agregarEntrada(S, el.Values.Time, el.Values.Data, nombre, j, nombre);
    end
 
elseif isstruct(sd) && isfield(sd, 'signals')              % Structure (With Time)
    if ~isfield(sd, 'time') || isempty(sd.time)
        error('Usa el formato "Structure With Time" en el Logging del Scope.');
    end
    for j = 1:numel(sd.signals)
        nombre = '';
        if isfield(sd.signals(j), 'label'), nombre = sd.signals(j).label; end
        titulo = '';
        if isfield(sd.signals(j), 'title'), titulo = sd.signals(j).title; end
        if isempty(nombre), nombre = titulo; end
        if isempty(nombre), nombre = sprintf('Entrada %d', j); end
        if isempty(titulo), titulo = nombre; end
        S = agregarEntrada(S, sd.time, sd.signals(j).values, nombre, j, titulo);
    end
else
    error('No reconozco el formato de "%s".', cfg.variable);
end
 
nS = numel(S);
 
% Nombres y unidades (en el orden de la lista impresa)
for k = 1:nS
    S(k).etq = texEsc(S(k).nombre);              % nombres del Scope: texto literal
    if numel(cfg.nombres) >= k && ~isempty(cfg.nombres{k})
        S(k).nombre = cfg.nombres{k};
        S(k).etq    = cfg.nombres{k};            % nombres propios: se interpretan como TeX
    end
    if numel(cfg.unidades) >= k, S(k).unidad = cfg.unidades{k}; else, S(k).unidad = ''; end
end
 
% Agrupación según el modo
switch lower(cfg.modo)
    case 'juntas',    grupo = ones(1, nS);
    case 'separadas', grupo = 1:nS;
    otherwise,        grupo = [S.grupo];
end
[~, ~, gi] = unique(grupo, 'stable');
gi = gi(:)';
nG = max(gi);
 
fprintf('\nSeñales detectadas: %d  |  Gráficas: %d  (modo "%s")\n', nS, nG, cfg.modo);
for k = 1:nS
    fprintf('  [%d] %s  -> gráfica %d\n', k, S(k).nombre, gi(k));
end
 
% Colores: la paleta y, si no alcanza, colores extra generados
if nS <= size(cfg.paleta,1)
    colores = cfg.paleta(1:nS,:);
else
    colores = [cfg.paleta; 0.8*hsv(nS - size(cfg.paleta,1))];
end
 
tIni = min(arrayfun(@(s) s.t(1),   S));
tFin = max(arrayfun(@(s) s.t(end), S));
 
%% ------------------------------- FIGURA ----------------------------------------------
switch lower(cfg.formato)
    case 'cuadrado',   tam = [620 620];
    case 'vertical',   tam = [450 800];
    case 'horizontal', tam = [960 540];
    otherwise,         tam = [560 700];      % linkedin 4:5
end
 
fig = figure('Color', est.fondo, 'Units', 'pixels', 'Position', [80 40 tam], ...
             'Name', 'Señales animadas', 'NumberTitle', 'off', 'Resize', 'off', ...
             'MenuBar', 'none', 'ToolBar', 'none', ...
             'InvertHardcopy', 'off', 'PaperPositionMode', 'auto');
tl = tiledlayout(fig, nG, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
 
if ~isempty(cfg.titulo)
    title(tl, cfg.titulo, 'FontSize', est.tamTitulo, 'FontName', est.fuente, ...
          'Color', est.ejes, 'FontWeight', 'normal');
end
if ~isempty(cfg.marca)
    tl.OuterPosition = [0 0.04 1 0.96];
    annotation(fig, 'textbox', [0 0 1 0.04], 'String', cfg.marca, 'EdgeColor', 'none', ...
               'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
               'Color', est.textoSec, 'FontSize', 10, 'FontName', est.fuente, ...
               'Interpreter', 'none');
end
 
ax = gobjects(1,nG); hL = gobjects(1,nS); hP = gobjects(1,nS);
D = cell(1,nG); miembros = cell(1,nG);
ce = est.ejes;
 
for g = 1:nG
    m = find(gi == g); miembros{g} = m;
    ax(g) = nexttile(tl); hold(ax(g), 'on');
    set(ax(g), 'Visible', 'off', 'Clipping', 'off');     % sin caja, sin cuadrícula, sin números
 
    ymin = min(arrayfun(@(s) min(s.y), S(m)));
    ymax = max(arrayfun(@(s) max(s.y), S(m)));
    if ymax - ymin < eps, ymax = ymin + 1; end
    rango = ymax - ymin;
 
    d = struct();
    d.yb      = max(min(0, ymax), ymin);    % altura del eje horizontal (el cero)
    d.yAbajo  = ymin - 0.08*rango;
    d.yArriba = ymax + 0.22*rango;
    ylim(ax(g), [ymin - 0.12*rango, ymax + 0.26*rango]);
 
    % Ejes dibujados a mano, con flecha
    d.hX  = plot(ax(g), NaN, NaN, '-', 'Color', ce, 'LineWidth', 1);
    d.hXf = plot(ax(g), NaN, NaN, '>', 'Color', ce, 'MarkerFaceColor', ce, 'MarkerSize', 5);
    d.hY  = plot(ax(g), NaN, NaN, '-', 'Color', ce, 'LineWidth', 1);
    d.hYf = plot(ax(g), NaN, NaN, '^', 'Color', ce, 'MarkerFaceColor', ce, 'MarkerSize', 5);
    d.hT  = text(ax(g), NaN, NaN, 't', 'FontName', est.fuente, 'FontSize', est.tamEtiqueta, ...
                 'FontAngle', 'italic', 'Color', ce, ...
                 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
    d.hLab = text(ax(g), NaN, NaN, '', 'Interpreter', 'tex', 'FontName', est.fuente, ...
                  'FontSize', est.tamEtiqueta, ...
                  'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
 
    % Escala: valor máximo (y mínimo si es negativo) junto al eje vertical
    d.esc = gobjects(0); d.escY = [];
    if est.escala
        vals = ymax; if ymin < 0, vals(end+1) = ymin; end
        for v = vals
            d.esc(end+1) = plot(ax(g), NaN, NaN, '-', 'Color', ce, 'LineWidth', 1);
            d.esc(end+1) = text(ax(g), NaN, NaN, strtrim(sprintf('%.4g %s', v, S(m(1)).unidad)), ...
                                'FontName', est.fuente, 'FontSize', est.tamEscala, ...
                                'Color', est.textoSec, 'HorizontalAlignment', 'right', ...
                                'VerticalAlignment', 'middle', 'Interpreter', 'none');
            d.escY(end+1) = v;
        end
    end
    D{g} = d;
 
    % Curvas
    for k = m
        c = colores(k,:);
        hL(k) = plot(ax(g), NaN, NaN, '-', 'Color', c, 'LineWidth', est.grosorLinea);
        if est.punto
            hP(k) = plot(ax(g), NaN, NaN, 'o', 'MarkerSize', 6, 'MarkerFaceColor', c, ...
                         'MarkerEdgeColor', est.fondo, 'LineWidth', 1);
        end
    end
    set(d.hLab, 'String', etiqueta(S, m, colores, NaN(1,nS), false));
end
 
% Posición inicial de los ejes
xb0 = tFin; if ~isempty(cfg.ventana), xb0 = tIni + cfg.ventana; end
for g = 1:nG, colocarEjes(ax(g), D{g}, tIni, xb0); end
 
%% ------------------------------- ANIMACIÓN -------------------------------------------
nCuadros = max(2, round(cfg.duracion * cfg.fps));
tCuadros = linspace(tIni, tFin, nCuadros);
grabando = cfg.guardarVideo || cfg.guardarGif;
res      = round(cfg.anchoVideo * get(groot, 'ScreenPixelsPerInch') / tam(1));
tamFrame = [];
valores  = NaN(1, nS);
F        = [];
 
vw = [];
if cfg.guardarVideo
    try
        vw = VideoWriter(cfg.archivoVideo, 'MPEG-4');
    catch
        [~, base] = fileparts(cfg.archivoVideo);
        vw = VideoWriter([base '.avi'], 'Motion JPEG AVI');
        warning('Este equipo no permite MP4; se guardará como AVI.');
    end
    vw.FrameRate = cfg.fps;
    if isprop(vw, 'Quality'), vw.Quality = 95; end
    open(vw);
    fprintf('Grabando video...\n');
end
 
for n = 1:nCuadros
    if ~isvalid(fig), break; end
    tic;
    tc = tCuadros(n);
    if isempty(cfg.ventana), xa = tIni; else, xa = max(tIni, tc - cfg.ventana); end
 
    for k = 1:nS
        t = S(k).t;
        i = find(t <= tc, 1, 'last');
        if isempty(i), continue; end
        if isempty(cfg.ventana), i0 = 1; else, i0 = find(t >= xa, 1); end
        set(hL(k), 'XData', t(i0:i), 'YData', S(k).y(i0:i));
        if est.punto, set(hP(k), 'XData', t(i), 'YData', S(k).y(i)); end
        v = S(k).y(i);
        if abs(v) < 1e-6 * max(abs(S(k).y)), v = 0; end   % evita residuos tipo 2.3e-13
        valores(k) = v;
    end
 
    if ~isempty(cfg.ventana)
        for g = 1:nG, colocarEjes(ax(g), D{g}, xa, xa + cfg.ventana); end
    end
    if est.valorEnVivo
        for g = 1:nG
            set(D{g}.hLab, 'String', etiqueta(S, miembros{g}, colores, valores, true));
        end
    end
    drawnow;
 
    if grabando
        F = capturar(fig, res, tamFrame, est.fondo);
        if isempty(tamFrame), tamFrame = [size(F,1) size(F,2)]; end
        if ~isempty(vw), writeVideo(vw, F); end
        if cfg.guardarGif, escribirGif(F, cfg.archivoGif, n == 1, 1/cfg.fps); end
    else
        pause(max(0, 1/cfg.fps - toc));
    end
end
 
% Imagen final (sin los puntos) sostenida unos segundos en el video
if grabando && isvalid(fig) && ~isempty(F)
    if est.punto, set(hP(isgraphics(hP)), 'Visible', 'off'); drawnow; end
    F = capturar(fig, res, tamFrame, est.fondo);
    if ~isempty(vw)
        for j = 1:round(cfg.pausaFinal * cfg.fps), writeVideo(vw, F); end
    end
    if cfg.guardarGif
        escribirGif(F, cfg.archivoGif, false, cfg.pausaFinal);
        fprintf('GIF guardado: %s\n', fullfile(pwd, cfg.archivoGif));
    end
end
if ~isempty(vw)
    close(vw);
    fprintf('Video guardado: %s\n', fullfile(vw.Path, vw.Filename));
end
 
%% ------------------------------- FUNCIONES AUXILIARES --------------------------------
function S = agregarEntrada(S, t, datos, nombre, grupo, grupoNombre)
% Agrega las señales de una entrada del Scope. Si la entrada trae varias
% columnas (Mux o bus), cada columna es una señal, pero todas quedan en el
% mismo grupo para dibujarse juntas en la misma gráfica.
    t = double(t(:));
    v = double(squeeze(datos));
    if isvector(v), v = v(:); end
    if size(v,1) ~= numel(t) && size(v,2) == numel(t), v = v.'; end
    nCol = size(v,2);
    for c = 1:nCol
        if nCol > 1, n = sprintf('%s (%d)', nombre, c); else, n = nombre; end
        S(end+1).t = t;             %#ok<AGROW>
        S(end).y           = v(:,c);
        S(end).nombre      = n;
        S(end).grupo       = grupo;
        S(end).grupoNombre = grupoNombre;
    end
end
 
function colocarEjes(ax, d, xa, xb)
% Ubica los ejes con flecha, la "t", el nombre de las señales y la escala.
    span = xb - xa;
    xr   = xb + 0.05*span;                       % punta de la flecha horizontal
    xlim(ax, [xa - 0.13*span, xr]);              % margen izquierdo para la escala
    alto = d.yArriba - d.yAbajo;
    set(d.hX,  'XData', [xa xr], 'YData', [d.yb d.yb]);
    set(d.hXf, 'XData', xr,      'YData', d.yb);
    set(d.hY,  'XData', [xa xa], 'YData', [d.yAbajo d.yArriba]);
    set(d.hYf, 'XData', xa,      'YData', d.yArriba);
    set(d.hT,   'Position', [xr, d.yb - 0.04*alto, 0]);
    set(d.hLab, 'Position', [xa + 0.02*span, d.yArriba, 0]);
    for j = 1:numel(d.escY)
        y = d.escY(j);
        set(d.esc(2*j-1), 'XData', [xa - 0.012*span, xa], 'YData', [y y]);
        set(d.esc(2*j),   'Position', [xa - 0.02*span, y, 0]);
    end
end
 
function s = etiqueta(S, m, colores, valores, conValor)
% Nombres de las señales, cada uno en su color: "v_a(t),  i(t),  v_c(t)"
    partes = {};
    for k = m(1:min(end, 6))
        txt = S(k).etq;
        if conValor && ~isnan(valores(k))
            txt = strtrim(sprintf('%s = %.4g %s', txt, valores(k), texEsc(S(k).unidad)));
        end
        c = colores(k,:);
        partes{end+1} = sprintf('\\color[rgb]{%.3f,%.3f,%.3f}%s', c(1), c(2), c(3), txt); %#ok<AGROW>
    end
    
    sep = [char(92) 'color[rgb]{0.5,0.5,0.5},   '];
    s = partes{1};
    for j = 2:numel(partes), s = [s sep partes{j}]; end
    
    if numel(m) > 6, s = sprintf('%s  (+%d)', s, numel(m) - 6); end
end
 
function s = texEsc(s)
% Evita que "_" o "^" de los nombres del Scope se lean como subíndices.
    s = regexprep(char(s), '([\\_^{}])', '\\$1');
end
 
function F = capturar(fig, res, tamFrame, fondo)
% Captura la figura en alta resolución y la ajusta a un tamaño fijo (par).
    F = print(fig, '-RGBImage', sprintf('-r%d', res));
    if isempty(tamFrame)
        h = 2*floor(size(F,1)/2); w = 2*floor(size(F,2)/2);
    else
        h = tamFrame(1); w = tamFrame(2);
    end
    G  = repmat(reshape(uint8(round(255*fondo)), 1, 1, 3), h, w);
    hh = min(h, size(F,1)); ww = min(w, size(F,2));
    G(1:hh, 1:ww, :) = F(1:hh, 1:ww, :);
    F = G;
end
 
function escribirGif(F, archivo, primero, retardo)
    [A, map] = rgb2ind(F, 256);
    if primero
        imwrite(A, map, archivo, 'gif', 'LoopCount', Inf, 'DelayTime', retardo);
    else
        imwrite(A, map, archivo, 'gif', 'WriteMode', 'append', 'DelayTime', retardo);
    end
end
 