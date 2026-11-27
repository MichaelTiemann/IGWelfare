function test_headless_plotting_and_super_age()
has_base_od = evalin('base', 'exist(''OutputDir'', ''var'')');
if has_base_od
    saved_base_od = evalin('base', 'OutputDir');
    evalin('base', 'clear OutputDir');
    restore_od = onCleanup(@() assignin('base', 'OutputDir', saved_base_od));
end
saved_app_od = getappdata(0, 'IGW_OUTPUT_DIR');
if ~isempty(saved_app_od)
    rmappdata(0, 'IGW_OUTPUT_DIR');
    restore_app_od = onCleanup(@() setappdata(0, 'IGW_OUTPUT_DIR', saved_app_od));
end
%TEST_HEADLESS_PLOTTING_AND_SUPER_AGE Sanity-check eval_super_age_point and headless
%   Plot_ActuarialContinuationValuation under both calibration anchors in a temp workspace.

origDir = pwd();
tmpDir  = tempname();
outDir  = fullfile(tmpDir, 'output', 'NZ_Dunedin1972');
outGui  = fullfile(tmpDir, 'output', 'NZ_GUiNZ2009');
mkdir(tmpDir);
mkdir(outDir);
mkdir(outGui);
origVis = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');
cleanupObj = onCleanup(@() restore_env(origDir, tmpDir, origVis));

% -------------------------------------------------------------------------
% PART A: Headless Plot_ActuarialContinuationValuation ('Dunedin_22' & 'MetroSqueeze_GUiNZ')
% -------------------------------------------------------------------------
cd(tmpDir);
for anchor = {'Dunedin_22', 'MetroSqueeze_GUiNZ'}
    P_plot = struct('Calibration_Anchor', anchor{1});
    Out = Plot_ActuarialContinuationValuation([], P_plot, 'All4');
    close all force;

    check(isstruct(Out) && strcmp(Out.Calibration_Anchor, anchor{1}), ...
        sprintf('Plot_ActuarialContinuationValuation failed anchor %s', anchor{1}));
end
pngs = [dir(fullfile(outDir, '*.png')); dir(fullfile(outGui, '*.png')); dir(fullfile(tmpDir, '*.png'))];
check(numel(pngs) >= 8, ...
    sprintf('Expected at least 8 PNG artifacts across both anchors, found %d', numel(pngs)));
cd(origDir);

% -------------------------------------------------------------------------
% PART B: eval_super_age_point statutory age < 65 vs == 65 vs > 65 (SS1 & SS2)
% -------------------------------------------------------------------------
n_a1 = 3; n_h = 7; n_th = 2; n_z = 2; J = 16;
h_vec = [0.45; 0.65; 0.85; 1.00; 1.20; 1.45; 1.80]; % Canonical 7-node human capital grid
j_fert_vec = [2, 3, 4];
sj_ref = 0.985 .^ ((0:(J - 1))' * 0.25);            % 16 five-year cohorts (ages 20..99)

Params = struct();
Params.Super_Age_Base           = 65.0;
Params.eta_elder_whanau         = 0.08;
Params.kappa_kuia_max           = 0.15;
Params.tau_kuia_sat             = 3.0;
Params.dt                       = 5.0;
Params.Jr                       = 10;
Params.tau_l                    = 0.22;
Params.theta_healthy_wrk_65     = 0.55;
Params.lambda_health_decay_65   = 0.09;
Params.phi_geriatric_leak_base  = 1.25;
Params.phi_geriatric_leak_slope = 0.04;
Params.psi_sandwich_wrk_drag    = 0.18;
Params.lambda_offset_decay_u65  = 0.12;
Params.omega_acc_offset_under65 = 0.30;
Params.nu_peak_earn_u65         = 1.15;
Params.nu_peak_earn_slope_u65   = 0.03;
Params.Dep_Ratio_Anchor    = 28.5;
Params.beta_aging_tax_drift     = 0.35;
Params.beta_exits_skill_div     = 0.12;
Params.psi_austerity_tax_drag   = 0.08;
Params.ss2_harvest_div_base     = 1.40;
Params.G_ece_stage1             = struct('HH_Rural', 0.05, 'HH_Small', 0.05, 'HH_Large', 0.055, 'HH_Auckland', 0.06);
Params.G_ece_stage2             = struct('HH_Rural', 0.06, 'HH_Small', 0.06, 'HH_Large', 0.065, 'HH_Auckland', 0.07);

Dist_Reg_Cell = cell(1, 4);
for r = 1:4
    D_raw = reshape(linspace(0.5, 1.5, n_a1 * n_h * n_th * n_z * J), [n_a1, n_h, n_th, n_z, J]);
    Dist_Reg_Cell{r} = D_raw / sum(D_raw(:));
end

w_Reg_Vec          = [0.95, 1.00, 1.08, 1.18];
Q_Base_Vec         = [0.95, 1.10, 1.35, 1.65];
K_base_vec         = [0.15, 0.13, 0.11, 0.09];
base_struggle_vec  = [16.0, 15.0, 14.0, 18.0];
Reg_HH_Shares      = [0.18, 0.22, 0.27, 0.33];
base_struggle_mean = sum(Reg_HH_Shares .* base_struggle_vec);
Q_mult             = [1.0, 1.0, 1.0, 1.0];

% Evaluate across under-65 (62), anchor (65), and over-65 (68) in both SS1 and SS2
[tfr62, diff62, str62, dep62, tax62] = eval_super_age_point( ...
    62.0, 0.85, 0.10, Params.G_ece_stage1, Params.G_ece_stage2, Q_mult, 0.20, false, ...
    Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, ...
    sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean);

[tfr65, diff65, str65, dep65, tax65] = eval_super_age_point( ...
    65.0, 0.85, 0.10, Params.G_ece_stage1, Params.G_ece_stage2, Q_mult, 0.20, false, ...
    Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, K_base_vec * 0 + base_struggle_vec, ...
    sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean);

[tfr68, diff68, str68, dep68, tax68_ss2] = eval_super_age_point( ...
    68.0, 0.85, 0.10, Params.G_ece_stage1, Params.G_ece_stage2, Q_mult, 0.20, true, ...
    Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, ...
    sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean);

for vec = {tfr62, diff62, str62, tfr65, diff65, str65, tfr68, diff68, str68}
    check(isequal(size(vec{1}), [1, 4]) && all(isfinite(vec{1})), ...
        'eval_super_age_point returned non-finite or misshapen regional row');
end
check(all(isfinite([dep62, tax62, dep65, tax65, dep68, tax68_ss2])), ...
    'eval_super_age_point returned non-finite dependency ratio or tax rate');
check(dep62 > dep65 && dep65 > dep68, ...
    sprintf('Expected dep_ratio to decline 62 (%.2f) > 65 (%.2f) > 68 (%.2f)', dep62, dep65, dep68));
end

function restore_env(origDir, tmpDir, origVis)
close all force;
set(0, 'DefaultFigureVisible', origVis);
cd(origDir);
if exist(tmpDir, 'dir') == 7
    rmdir(tmpDir, 's');
end
end

function check(cond, msg)
if ~cond
    error('tests:fail', '%s', msg);
end


end
