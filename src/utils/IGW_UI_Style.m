function varargout = IGW_UI_Style(action, varargin)
%% SINGLE-SOURCE CROSS-PLATFORM GRAPHICS & UI STYLING CONTRACT
% File: src/utils/IGW_UI_Style.m
% Centralizes MATLAB HG2 vs GNU Octave Qt/FLTK graphics nuances so plotting scripts
% contain zero OCTAVE_VERSION or graphics_toolkit conditionals:
%   vis = IGW_UI_Style('headless_vis')            -> 'on' on Octave FLTK (requires mapped window for OpenGL capture), else 'off'
%   IGW_UI_Style('legend_alpha', lgd, alpha_val)  -> semi-transparent white legend box on MATLAB HG2 (safe no-op on Octave)
%   IGW_UI_Style('dock_north', lgd)               -> lgd.Layout.Tile = 'north' on MATLAB tiledlayout (safe no-op on Octave)
%   [x_all, x_sub] = IGW_UI_Style('bar_x', lbls)  -> categorical on MATLAB, 1:N numeric on Octave
%   IGW_UI_Style('bar_xticks', ax, lbls)          -> applies clean XTickLabels on Octave or TickLabelInterpreter='none' on MATLAB

is_oct = (exist('OCTAVE_VERSION', 'builtin') ~= 0);

switch lower(strtrim(char(action)))
    case 'headless_vis'
        vis = 'off';
        if is_oct && exist('graphics_toolkit', 'file') ~= 0 && strcmp(graphics_toolkit(), 'fltk')
            vis = 'on';
        end
        varargout{1} = vis;

    case 'fltk_export_guard'
        fig = varargin{1};
        if is_oct && ishandle(fig) && exist('graphics_toolkit', 'file') ~= 0 && strcmp(graphics_toolkit(), 'fltk')
            set(fig, 'Visible', 'on');
            drawnow();
        end

    case 'legend_alpha'
        lgd = varargin{1};
        alpha_v = 0.92;
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            alpha_v = varargin{2};
        end
        if ~is_oct && ~isempty(lgd) && isgraphics(lgd)
            try
                lgd.BoxFace.ColorType = 'truecoloralpha';
                lgd.BoxFace.ColorData = uint8(255 * [1; 1; 1; alpha_v]);
            catch
            end
        end

    case 'dock_north'
        lgd = varargin{1};
        if ~is_oct && ~isempty(lgd) && isgraphics(lgd)
            try
                lgd.Layout.Tile = 'north';
            catch
            end
        end

    case 'bar_x'
        lbls = varargin{1};
        n_l  = numel(lbls);
        if is_oct
            varargout{1} = (1:n_l)';
            varargout{2} = (1:max(0, n_l - 1))';
        else
            c_all = categorical(lbls, lbls);
            varargout{1} = c_all;
            if n_l >= 2
                varargout{2} = c_all(2:end);
            else
                varargout{2} = c_all([]);
            end
        end

    case 'bar_xticks'
        ax   = varargin{1};
        lbls = varargin{2};
        if is_oct
            set(ax, 'XTick', 1:numel(lbls), 'XTickLabel', lbls);
        else
            set(ax, 'TickLabelInterpreter', 'none');
        end

    case 'sans_font'
        font_name = 'Helvetica';
        if ~is_oct
            avail = listfonts();
            if any(strcmpi(avail, 'Inter'))
                font_name = 'Inter';
            elseif any(strcmpi(avail, 'Arial'))
                font_name = 'Arial';
            end
        end
        varargout{1} = font_name;

    case 'export_png'
        fig     = varargin{1};
        out_png = varargin{2};
        dpi_val = 220;
        if numel(varargin) >= 3 && ~isempty(varargin{3})
            dpi_val = varargin{3};
        end
        if ~is_oct
            exportgraphics(fig, out_png, 'Resolution', dpi_val, 'BackgroundColor', 'white');
        else
            if ishandle(fig) && exist('graphics_toolkit', 'file') ~= 0 && strcmp(graphics_toolkit(), 'fltk')
                set(fig, 'Visible', 'on');
                drawnow();
            end
            pos = get(fig, 'Position');
            set(fig, 'PaperUnits', 'inches', 'PaperSize', [pos(3)/110, pos(4)/110], ...
                'PaperPosition', [0, 0, pos(3)/110, pos(4)/110]);
            print(fig, out_png, '-dpng', sprintf('-r%d', dpi_val));
        end

    otherwise
        error('IGWelfare:UnknownUIStyleAction', 'Unknown IGW_UI_Style action "%s".', char(action));
end

end
