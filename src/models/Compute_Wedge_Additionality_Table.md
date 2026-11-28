function T_Wedge = Compute_Wedge_Additionality_Table(Profile_Name)
% COMPUTE_WEDGE_ADDITIONALITY_TABLE
% Computes scale-free Hulten Leverage Ratios (SS2 CE Gain / Steady-State Gross
% Mirror Outlay s_B) and Lee-Seshadri regional output/welfare wedges directly
% from exported Table19E, Table20, and Table5 CSVs in output/<Profile_Name>/.

    out_dir = fullfile('output', Profile_Name);
    f19E = glob(fullfile(out_dir, 'Table19E_ArtsEnabled_Synergy_Wedges_*.csv'));
    f20  = glob(fullfile(out_dir, 'Table20_Annual_MirrorInvestments_*.csv'));
    f5   = glob(fullfile(out_dir, 'Table5_4Region_LeeSeshadri_Output_Welfare.csv'));

    % Parse Table 19E (col 1 = Layer_Code, col 7 = SS1_Nat, col 12 = SS2_Nat)
    raw19 = fileread(f19E{1});
    lines19 = strsplit(strtrim(raw19), "\n");
    n19 = numel(lines19) - 1;
    Layer_Code = cell(n19, 1);
    SS1_CE = zeros(n19, 1);
    SS2_CE = zeros(n19, 1);
    for i = 1:n19
        tok = strsplit(strtrim(lines19{i+1}), ',');
        Layer_Code{i} = tok{1};
        SS1_CE(i)     = str2double(tok{7});
        SS2_CE(i)     = str2double(tok{12});
    end

    % Parse Table 20 steady-state row (Year 60 = final row; Year 0 = row 2)
    raw20 = fileread(f20{1});
    lines20 = strsplit(strtrim(raw20), "\n");
    row0  = str2double(strsplit(strtrim(lines20{2}), ','));
    row60 = str2double(strsplit(strtrim(lines20{end}), ','));

    % Steady-state gross mirror outlays s_B (% CE, positive sign convention)
    sB_ECE      = -row60(6);   % MirrorInv1_Universal_ECE_CE
    sB_Ment     = -row60(7);   % MirrorInv2_Tuakana_Mentoring_CE
    sB_Youth    = -row60(8);   % MirrorInv3_YouthGrant_CE
    sB_Geo_Yr0  = -row0(9);    % MirrorInv4_GeoTransfer_CE (initial)
    sB_Geo_SS   = -row60(9);   % MirrorInv4_GeoTransfer_CE (Year 60)
    sB_Pkg      = -row60(10);  % Total_Gross_Inv_Mirror_CE_Pct
    sB_Arts     = -row60(24);  % MirrorInv2E_JoinerPassport_CE

    % Map isolated & synergy-paired SS2 gains
    CE_ECE      = SS2_CE(1);
    CE_Ment     = SS2_CE(2);
    CE_HC_Stack = SS2_CE(1) + SS2_CE(2) + SS2_CE(3);
    CE_Youth    = SS2_CE(5);
    CE_Geo      = SS2_CE(6);
    CE_Arts_Cap = sum(SS2_CE(12:15));
    CE_Pkg_Base = row60(2);
    CE_Pkg_Arts = row60(23);

    Levers = {
        'L01 Universal ECE (Iso)',          sB_ECE,            CE_ECE;
        'L02 Tuakana Mentoring (Iso)',      sB_Ment,           CE_Ment;
        'L01+L02+Wedge1 Dual-Gate HC',      sB_ECE + sB_Ment,  CE_HC_Stack;
        'L05 Youth Grant Age 20 (Iso)',     sB_Youth,          CE_Youth;
        'L06 Geo Income Transfer (vs Yr0)', sB_Geo_Yr0,        CE_Geo;
        'L06 Geo Income Transfer (vs Yr60)',sB_Geo_SS,         CE_Geo;
        'L03E-11E Arts/Civic Seed Cap',     sB_Arts,           CE_Arts_Cap;
        'Full 7-Seg Package (Base)',        sB_Pkg,            CE_Pkg_Base;
        'Full Arts-Enabled Package',        sB_Pkg + sB_Arts,  CE_Pkg_Arts
    };

    fprintf('\n### Wedge Additionality Audit: %s\n\n', Profile_Name);
    fprintf('| Policy Lever / Stack | Gross Outlay s_B (%% CE) | Realized SS2 Wedge (%% CE) | Hulten Ratio (Gain / s_B) |\n');
    fprintf('|---|---:|---:|---:|\n');
    for k = 1:size(Levers, 1)
        ratio = Levers{k,3} / Levers{k,2};
        fprintf('| %-33s | %8.3f%% | %+8.3f%% | %8.2fx |\n', ...
            Levers{k,1}, Levers{k,2}, Levers{k,3}, ratio);
    end

    % Parse Table 5 regional Ebar_LR and CE_LR contrast
    raw5 = fileread(f5{1});
    lines5 = strsplit(strtrim(raw5), "\n");
    hdr5 = strsplit(strtrim(lines5{1}), ',');
    reg4_name = strrep(hdr5{9}, 'Ebar_LR_', '');
    fprintf('\n#### Table 5 Regional Conversion Check (%s: Rural vs. %s)\n', Profile_Name, reg4_name);
    fprintf('| Counterfactual | Ebar_LR Rural | Ebar_LR %s | CE_LR Rural | CE_LR %s |\n', reg4_name, reg4_name);
    fprintf('|---|---:|---:|---:|---:|\n');
    for i = 2:numel(lines5)
        tok = strsplit(strtrim(lines5{i}), ',');
        fprintf('| %-16s | %+7.3f%% | %+7.3f%% | %+7.3f%% | %+7.3f%% |\n', ...
            tok{1}, str2double(tok{6}), str2double(tok{9}), str2double(tok{10}), str2double(tok{13}));
    end

    T_Wedge = struct('Profile', Profile_Name, 'Levers', {Levers});
end