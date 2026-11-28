function T_Wedge = Compute_Wedge_Additionality_Table(Profile_Name, Write_CSV, Out_Dir)
% COMPUTE_WEDGE_ADDITIONALITY_TABLE
% Pure post-hoc ledger operator computing scale-free Hulten Leverage Ratios
% (Realized SS2 CE% / Steady-State Gross Mirror Outlay s_B) and regional
% Lee-Seshadri conversion contrasts across MATLAB and GNU Octave.

    if nargin < 2 || isempty(Write_CSV), Write_CSV = false; end
    if nargin < 3, Out_Dir = ''; end

    Out_Dir = Resolve_IGW_OutputDir(Out_Dir, Profile_Name);

    f19E = require_single_csv(Out_Dir, 'Table19E_ArtsEnabled_Synergy_Wedges_*.csv');
    f20  = require_single_csv(Out_Dir, 'Table20_Annual_MirrorInvestments_*.csv');
    f5   = require_single_csv(Out_Dir, 'Table5_4Region_LeeSeshadri_Output_Welfare.csv');

    % Parse Table 19E (col 1 = Layer_Code, col 7 = SS1_Nat, col 12 = SS2_Nat)
    lines19 = strsplit(strtrim(fileread(f19E)), "\n");
    n19 = numel(lines19) - 1;
    SS1_CE = zeros(n19, 1);
    SS2_CE = zeros(n19, 1);
    for i = 1:n19
        tok = strsplit(strtrim(lines19{i+1}), ',');
        SS1_CE(i) = str2double(tok{7});
        SS2_CE(i) = str2double(tok{12});
    end

    % Parse Table 20 (Year 0 = row 2; Year 60 steady state = end)
    lines20 = strsplit(strtrim(fileread(f20)), "\n");
    row0  = str2double(strsplit(strtrim(lines20{2}), ','));
    row60 = str2double(strsplit(strtrim(lines20{end}), ','));

    sB_ECE     = -row60(6);
    sB_Ment    = -row60(7);
    sB_Youth   = -row60(8);
    sB_Geo_Yr0 = -row0(9);
    sB_Geo_SS  = -row60(9);
    sB_Pkg     = -row60(10);
    sB_Arts    = -row60(24);

    Levers = {
        'L01_Universal_ECE_Iso',           sB_ECE,            SS2_CE(1);
        'L02_Tuakana_Mentoring_Iso',       sB_Ment,           SS2_CE(2);
        'L01_L02_Wedge1_DualGate_HC',      sB_ECE + sB_Ment,  sum(SS2_CE(1:3));
        'L05_Youth_Grant_Age20_Iso',       sB_Youth,          SS2_CE(5);
        'L06_Geo_Income_Transfer_vs_Yr0',  sB_Geo_Yr0,        SS2_CE(6);
        'L06_Geo_Income_Transfer_vs_Yr60', sB_Geo_SS,         SS2_CE(6);
        'L03E_11E_Arts_Civic_Seed_Cap',    sB_Arts,           sum(SS2_CE(12:15));
        'Full_7Seg_Package_Base',          sB_Pkg,            row60(2);
        'Full_Arts_Enabled_Package',       sB_Pkg + sB_Arts,  row60(23)
    };

    s_B_pct      = cell2mat(Levers(:, 2));
    SS2_Gain_pct = cell2mat(Levers(:, 3));
    Lambda_Y     = SS2_Gain_pct ./ s_B_pct;

    % Parse Table 5 regional conversion contrast
    lines5 = strsplit(strtrim(fileread(f5)), "\n");
    hdr5 = strsplit(strtrim(lines5{1}), ',');
    reg4_name = strrep(hdr5{9}, 'Ebar_LR_', '');
    n5 = numel(lines5) - 1;
    CF_Rows = cell(n5, 1);
    Ebar_LR_Reg1 = zeros(n5, 1);
    Ebar_LR_Reg4 = zeros(n5, 1);
    CE_LR_Reg1   = zeros(n5, 1);
    CE_LR_Reg4   = zeros(n5, 1);
    for i = 1:n5
        tok = strsplit(strtrim(lines5{i+1}), ',');
        CF_Rows{i}      = tok{1};
        Ebar_LR_Reg1(i) = str2double(tok{6});
        Ebar_LR_Reg4(i) = str2double(tok{9});
        CE_LR_Reg1(i)   = str2double(tok{10});
        CE_LR_Reg4(i)   = str2double(tok{13});
    end

    if Write_CSV
        csv_out = fullfile(Out_Dir, sprintf('Table25_Wedge_Additionality_Audit_%s.csv', Profile_Name));
        fid = fopen(csv_out, 'w');
        fprintf(fid, 'Lever_Code,Gross_Outlay_sB_PctCE,Realized_SS2_Gain_PctCE,Hulten_Leverage_Ratio\n');
        for k = 1:numel(Lambda_Y)
            fprintf(fid, '%s,%.6f,%.6f,%.6f\n', Levers{k,1}, s_B_pct(k), SS2_Gain_pct(k), Lambda_Y(k));
        end
        fclose(fid);
    end

    T_Wedge = struct( ...
        'Profile',      Profile_Name, ...
        'LeverNames',   {Levers(:, 1)}, ...
        's_B_pct',      s_B_pct, ...
        'SS2_Gain_pct', SS2_Gain_pct, ...
        'Lambda_Y',     Lambda_Y, ...
        'Reg4_Name',    reg4_name, ...
        'CF_Rows',      {CF_Rows}, ...
        'Ebar_LR_Reg1', Ebar_LR_Reg1, ...
        'Ebar_LR_Reg4', Ebar_LR_Reg4, ...
        'CE_LR_Reg1',   CE_LR_Reg1, ...
        'CE_LR_Reg4',   CE_LR_Reg4);
end

function fpath = require_single_csv(Out_Dir, pattern)
    d = dir(fullfile(Out_Dir, pattern));
    if isempty(d)
        error('IGWelfare:MissingPrerequisiteCSV', ...
            'Required CSV "%s" not found in "%s".', pattern, Out_Dir);
    end
    fpath = fullfile(Out_Dir, d(1).name);
end
