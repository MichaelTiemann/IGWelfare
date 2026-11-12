classdef MD_Sync_Skill
    % MD_Sync_Skill: Reusable Statistical, Table, & Reference Sync Engine for Markdown Files
    methods (Static)
        function S = load_metrics(out_dir)
            if nargin < 1 || isempty(out_dir), out_dir = 'Output_NZ_4Region_Intergen'; end
            S.pop_w = Params.Pop_Weights_4;

            % Load Table 1 (Multiphase 4-Region Decomposition)
            t1_f = fullfile(out_dir, 'Table1_Multiphase_WelfareDecomposition_4Region.csv');
            if isfile(t1_f)
                T1 = readtable(t1_f);
                S.r_mat = [T1.Rural_CE_Pct, T1.Small_CE_Pct, T1.Large_CE_Pct, T1.Auckland_CE_Pct];
            else
                S.r_mat = [ 2.0163,  2.1464,  2.5056,  3.2097;  6.2319,  6.2786,  6.7684,  7.7093; ...
                           11.9452, 13.7391, 14.8883, 17.5151;  5.6376,  5.8241,  6.2614,  6.9250; ...
                           12.7000, 12.9066, 13.6057, 14.5876; 20.6280, 22.9836, 24.5742, 27.9127];
            end
            S.nat_t1  = S.r_mat * S.pop_w';
            S.ss1_reg = S.r_mat(3, :);
            S.ss2_reg = S.r_mat(6, :);
            S.ss1_nat = S.nat_t1(3);
            S.ss2_nat = S.nat_t1(6);

            % Load Table 19 (11-Layer Constructive Synergy Attribution)
            t19_f = fullfile(out_dir, 'Table19_Constructive_Synergy_Wedges_Dunedin_22.csv');
            assert(isfile(t19_f), 'Missing %s!', t19_f);
            S.T19     = readtable(t19_f);
            S.iso_idx = [1, 2, 4, 5, 6, 9, 10];
            S.wed_idx = [3, 7, 8, 11];
            S.s2_nat  = S.T19.SS2_National_CE;
            S.iso_tot = sum(S.s2_nat(S.iso_idx));
            S.wed_tot = sum(S.s2_nat(S.wed_idx));
            S.nat_tot = sum(S.s2_nat);
            S.iso_shr = 100 * S.iso_tot / S.nat_tot;
            S.wed_shr = 100 * S.wed_tot / S.nat_tot;

            % Fiscal & Demographic Anchor Metrics (with 85% Transfer_Geo Retirement)
            S.ltfm_sink  = -16.21;
            S.def_sink   = -21.69;
            S.swing_ltfm = S.nat_tot - S.ltfm_sink; % +40.91 pp
            S.swing_def  = S.nat_tot - S.def_sink;  % +46.39 pp
            S.ce_def_3pct= S.nat_tot - 3.52;        % +21.18% CE under 3% GDP defense
            S.paye_cut64 = -3.75;
            S.paye_rate64= 18.25;
            S.paye_cut65 = -4.03;
            S.paye_rate65= 17.97;
            S.ce_age65   = S.nat_tot - 0.17;        % +24.53% CE at Age 65
        end

        function [txt, has_crlf] = read_md(fname)
            raw = fileread(fname);
            has_crlf = contains(raw, sprintf('\r\n'));
            txt = strrep(raw, sprintf('\r\n'), sprintf('\n'));
        end

        function write_md(fname, txt, has_crlf)
            if has_crlf, txt = strrep(txt, sprintf('\n'), sprintf('\r\n')); end
            fid = fopen(fname, 'w'); fwrite(fid, txt); fclose(fid);
            fprintf('[SAVED] %s\n', fname);
        end

        function md = render_table(headers, align, rows)
            % Programmatically formats a 2D cell array `rows` into a Markdown table
            ncol = numel(headers);
            sep  = cell(1, ncol);
            for c = 1:ncol
                switch lower(align{c})
                    case 'c', sep{c} = ':---:';
                    case 'r', sep{c} = '---:';
                    otherwise, sep{c} = ':---';
                end
            end
            lines = cell(size(rows, 1) + 2, 1);
            lines{1} = ['| ', strjoin(headers, ' | '), ' |'];
            lines{2} = ['| ', strjoin(sep, ' | '), ' |'];
            for r = 1:size(rows, 1)
                lines{r+2} = ['| ', strjoin(rows(r, :), ' | '), ' |'];
            end
            md = [strjoin(lines, sprintf('\n')), sprintf('\n')];
        end

        function txt = patch_line(txt, anchor, old_tok, new_tok)
            pos = strfind(txt, anchor);
            assert(~isempty(pos), sprintf('Anchor not found: "%s"', anchor));

            cands = {old_tok, strrep(old_tok, '*', '**'), strrep(old_tok, '–', '-'), ...
                strrep(old_tok, '-', '–'), strrep(old_tok, '%', '\%')};

            already_done = false;
            for idx = 1:numel(pos)
                p = pos(idx);
                nl1 = find(txt(1:p) == sprintf('\n'), 1, 'last');
                s = 1; if ~isempty(nl1), s = nl1 + 1; end
                nl2 = find(txt(p:end) == sprintf('\n'), 1, 'first');
                e = length(txt); if ~isempty(nl2), e = p + nl2 - 2; end

                % Expand to full paragraph (\n\n) unless it is a table row (|) or heading (#)
                if txt(s) ~= '|' && txt(s) ~= '#'
                    p_start = strfind(txt(1:p), sprintf('\n\n'));
                    if ~isempty(p_start), s = p_start(end) + 2; end
                    p_end = strfind(txt(p:end), sprintf('\n\n'));
                    if ~isempty(p_end), e = p + p_end(1) - 2; end
                end
                ln = txt(s:e);

                for c = 1:numel(cands)
                    if contains(ln, cands{c})
                        txt = [txt(1:s-1), strrep(ln, cands{c}, new_tok), txt(e+1:end)];
                        fprintf('[OK] "%s" -> "%s" (@ "%s" #%d)\n', cands{c}, new_tok, anchor, idx);
                        return;
                    end
                    % Whitespace/newline-agnostic fallback for hard-wrapped Markdown lines:
                    pat = regexptranslate('escape', cands{c});
                    pat = regexprep(pat, '\s+', '\\s+');
                    [m_start, m_end] = regexp(ln, pat, 'once');
                    if ~isempty(m_start)
                        ln_new = [ln(1:m_start-1), new_tok, ln(m_end+1:end)];
                        txt = [txt(1:s-1), ln_new, txt(e+1:end)];
                        fprintf('[OK-wrap] "%s" -> "%s" (@ "%s" #%d)\n', cands{c}, new_tok, anchor, idx);
                        return;
                    end
                end
                if contains(ln, new_tok), already_done = true; end
            end

            if already_done
                fprintf('[SKIP] Already updated (@ "%s")\n', anchor);
            else
                error('Token "%s" not found at any of %d occurrence(s) of anchor "%s":\n  %s', ...
                    old_tok, numel(pos), anchor, ln);
            end
        end

        function txt = replace_block(txt, start_anchor, end_anchor, new_block)
            idx_s = strfind(txt, start_anchor);
            idx_e = strfind(txt, end_anchor);
            assert(~isempty(idx_s), sprintf('Start anchor missing: "%s"', start_anchor));
            assert(~isempty(idx_e), sprintf('End anchor missing: "%s"', end_anchor));
            p_s = idx_s(1);
            p_e = idx_e(find(idx_e > p_s, 1, 'first'));
            nl1 = find(txt(1:p_s) == sprintf('\n'), 1, 'last');
            s = 1; if ~isempty(nl1), s = nl1 + 1; end
            nl2 = find(txt(1:p_e) == sprintf('\n'), 1, 'last');
            e = p_e; if ~isempty(nl2), e = nl2; end
            txt = [txt(1:s-1), new_block, txt(e+1:end)];
            fprintf('[OK] Replaced block "%s" .. "%s"\n', start_anchor, end_anchor);
        end
    end
end
