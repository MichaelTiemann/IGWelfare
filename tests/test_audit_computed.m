% test_audit_computed.m
% Checks that every number printed by Audit_GUiNZ_vs_Dunedin_4Region is computed
% from its inputs (defaults reproduce the documented 3.84x; changing an input
% changes the printed output). Throws on failure, prints nothing on success.
% Runs under MATLAB and GNU Octave; no toolboxes, no GPU.

function test_audit_computed()

addpath(fileparts(fileparts(mfilename('fullpath'))));

NoCsv = struct('OutFile', ''); % never write the CSV from a test

% --- Defaults: 35.25 / 9.18 = 3.8399... prints as 3.84x
txt = evalc('R = Audit_GUiNZ_vs_Dunedin_4Region([], [], NoCsv);');
check(abs(R.ActuarialMult_Dunedin - 35.25 / 9.18) < 1e-12, 'default ratio is not 35.25/9.18');
check(abs(printed(txt, 'Year-5 ACC Actuarial Return Multiple', 1) - 3.84) < 1e-9, 'default Dunedin multiple does not print 3.84x');
check(abs(printed(txt, 'Year-5 ACC Actuarial Return Multiple', 2) - round(100 * R.ActuarialMult_GUiNZ) / 100) < 1e-9, 'printed GUiNZ multiple differs from returned value');
check(isequal(printed(txt, 'Private-Rental Transience Haircut', 1:3), [-6.0, -25.0, 0.0]), 'default haircut row changed');
check(isequal(printed(txt, 'Dimension 5: Abroad', 1:3), [19.3, 23.4, 7.6]), 'default Abroad row changed');
check(isequal(printed(txt, '2050 Steady-State PAYE', 1:3), [28.2, 30.4, 18.5]), 'default PAYE row changed');

% --- Empty / absent inputs behave identically (backward compatible signature)
txt_empty = evalc('Audit_GUiNZ_vs_Dunedin_4Region([], [], NoCsv);');
check(strcmp(txt, txt_empty), 'empty inputs differ from defaults');

% --- Changing Params changes the printed output
txt2 = evalc('R2 = Audit_GUiNZ_vs_Dunedin_4Region([], [], struct(''OutFile'', '''', ''Cost_5Yr_Package'', 7.05));');
check(abs(printed(txt2, 'Year-5 ACC Actuarial Return Multiple', 1) - 5.00) < 1e-9, 'Cost_5Yr_Package=7.05 did not print 5.00x');
check(~strcmp(txt, txt2), 'printed output did not change with Cost_5Yr_Package');

txt3 = evalc('Audit_GUiNZ_vs_Dunedin_4Region([], [], struct(''OutFile'', '''', ''NPV_Dunedin'', 18.36));');
check(abs(printed(txt3, 'Year-5 ACC Actuarial Return Multiple', 1) - 2.00) < 1e-9, 'NPV_Dunedin=18.36 did not print 2.00x');

txt4 = evalc('Audit_GUiNZ_vs_Dunedin_4Region([], [], struct(''OutFile'', '''', ''Abroad_Drain_Pct'', [1.5 2.5 3.5], ''PAYE_Drift_Pct'', [11.1 22.2 33.3]));');
check(isequal(printed(txt4, 'Dimension 5: Abroad', 1:3), [1.5, 2.5, 3.5]), 'Abroad_Drain_Pct did not drive its row');
check(isequal(printed(txt4, '2050 Steady-State PAYE', 1:3), [11.1, 22.2, 33.3]), 'PAYE_Drift_Pct did not drive its row');

txt5 = evalc('Audit_GUiNZ_vs_Dunedin_4Region([], [], struct(''OutFile'', '''', ''National_Drag_Target'', 35.4));');
check(abs(printed(txt5, 'National Remediation Drag', 1) - 35.4) < 1e-9, 'National_Drag_Target did not drive the Dunedin drag');

% --- StationaryDist inputs drive the corner shares (all mass in vigintile 1)
mass = zeros(20, 1);
mass(1) = 1;
txt6 = evalc('R6 = Audit_GUiNZ_vs_Dunedin_4Region(mass, mass, NoCsv);');
check(abs(R6.CornerShare_Dunedin - 0.95) < 1e-12 && abs(R6.CornerShare_GUiNZ - 0.99) < 1e-12 && abs(R6.CornerShare_SS2 - 0.08) < 1e-12, 'StationaryDist inputs did not drive corner shares');
check(isequal(printed(txt6, 'Stone-Geary Corner Share', 1:3), [95.0, 99.0, 8.0]), 'printed corner shares did not follow StationaryDist inputs');

% --- A mis-sized input falls back to the defaults (warning silenced)
wid = 'Audit_GUiNZ_vs_Dunedin_4Region:input';
warning('off', wid);
txt7 = evalc('Audit_GUiNZ_vs_Dunedin_4Region(ones(3, 3), [], NoCsv);');
warning('on', wid);
check(strcmp(txt, txt7), 'mis-sized StationaryDist_SS0 did not fall back to defaults');

end

function check(cond, msg)
if ~cond
    error('test_audit_computed:fail', '%s', msg);
end
end

function v = printed(txt, label, cols)
% Numbers (as doubles) in the printed row whose label starts with `label`, columns `cols`
lines = strsplit(txt, sprintf('\n'));
row = '';
for k = 1:numel(lines)
    if ~isempty(strfind(lines{k}, label))
        row = lines{k};
        break
    end
end
check(~isempty(row), ['row not printed: ' label]);
cells = strsplit(row, '|');
cells = cells(2:end); % drop the label cell
v = zeros(1, numel(cols));
for j = 1:numel(cols)
    tok = regexp(cells{cols(j)}, '-?\d+\.\d+', 'match');
    check(~isempty(tok), ['no number in column ' num2str(cols(j)) ' of: ' label]);
    v(j) = str2double(tok{1});
end
end
