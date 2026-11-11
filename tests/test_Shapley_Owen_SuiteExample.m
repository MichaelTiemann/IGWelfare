function test_Shapley_Owen_SuiteExample()
% TEST_SHAPLEY_OWEN_SUITEEXAMPLE
% Worked example on the suite's own typed numbers (national SS2 long-run CE %, +24.70% headline).
% Throws on the first failure and prints nothing on success. No toolboxes; MATLAB and Octave.
%
% SOURCES (constants below are copied, not recomputed; the .m scripts themselves are not run).
% Values are those typed in the scripts at upstream commit c23787e:
%   Raw_Nat_11     Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m line 55, "Raw_Nat_11" (two-decimal values of the
%                  national column of Table A.1, Document 3.md lines 247-261, and of Document 1A.md lines 582-593).
%   Pop_Weights    same file, line 36;  SS2_Target_Reg  same file, line 38.
%   Raw_Mat_4x4    same file, lines 331-335 (rescaled there to SS2_Nat, lines 337-339).
%   H_Comp         Plot_Hierarchical_Complementarity_Wedges.m lines 98-104 (older 12-layer build, +20.49% total).
% Rounding: the eleven typed values sum to 24.71, SS2_Nat computed from the regional values is 24.70 (24.6996).
%
% WHICH COALITIONS OF THE 7 LEVERS THE SUITE ACTUALLY VALUES.  Lever numbering used here:
%   1 ECE_1 (L01)   2 Tuakana (L02)   3 Estate/Property rebalance (L04)   4 Youth Grant E (L05)
%   5 Geo transfer (L06)   6 Debt-sinking (L09)   7 PAYE cut + Super 64 (L10)
% Document 2B s7.4 / Document 1B define the four wedges through these coalition values:
%   v({i})            = the 7 isolated layers                         (7 values)
%   v({1,2})          = L01+L02+Wedge1  (joint Dual-Gate model run)
%   v({3,4,5})        = L04+L05+L06+Wedge2  (CE of Phi_Spatial)
%   v({1,2,3,4,5})    = v({1,2}) + v({3,4,5}) + Wedge3  (CE of Phi_HC u Phi_Spatial)
%   v({1..7})         = 24.71 (sum of the typed layers), with Wedge4 the closing residual
%   v({})             = 0 (SS0 baseline)
% That is 12 of the 2^7 = 128 coalition values. The Doc 3 "8 scenarios" are mostly not lever subsets:
% 1 = grand coalition, 7 = baseline under LTFM drift, 4 and 5 = {1,2} and {3,4,5} netted against drift
% (scenarios 2, 3a, 3b, 6, 8 are shocks, time-paths or a different policy).

addpath(fileparts(fileparts(mfilename('fullpath'))));
tol = 1e-9;

L = [2.46; 1.56; 3.32; 2.24; 0.89; 0.15; 2.33; 5.20; 1.25; 2.69; 2.62];   % Raw_Nat_11, layers L01..L11
iso_rows = [1 2 4 5 6 9 10];   wedge_rows = [3 7 8 11];
Pop_Weights    = [0.160, 0.240, 0.259, 0.341];
SS2_Target_Reg = [20.628, 22.984, 24.574, 27.913];
SS2_Nat        = sum(SS2_Target_Reg .* Pop_Weights);

% =========================================================================
% 1. HEADLINE ARITHMETIC: THE TOTAL WEDGE SHARE IS ORDER-INVARIANT
% =========================================================================
% Sum of wedges = v(N) - sum_i v({i}) whenever the 7 isolated layers are the singleton values, so the
% 54.5% total does not depend on any ordering; only its split across Wedges 1-4 and levers does.
total = sum(L);
check(abs(total - 24.71) < tol, 'typed layers sum to 24.71');
check(abs(SS2_Nat - 24.70) < 5e-3 && abs(total - SS2_Nat) < 0.02, 'SS2_Nat is 24.70; typed layers within two-decimal rounding of it');
check(abs(sum(L(iso_rows)) - 11.24) < tol && abs(sum(L(wedge_rows)) - 13.47) < tol, 'iso 11.24 / wedges 13.47');
check(abs(sum(L(wedge_rows)) - (total - sum(L(iso_rows)))) < tol, 'wedge total = v(N) - sum of singletons');
check(abs(100 * sum(L(wedge_rows)) / total - 54.5123) < 1e-3, 'wedge share 54.5%');

% =========================================================================
% 2. COMPLETE SUB-LATTICES: 2 LEVERS (DUAL GATE) AND 2 BLOCKS (HC STACK, SPATIAL STACK)
% =========================================================================
% 2^2 lattice over {ECE_1, Tuakana}: v = [{} {1} {2} {1,2}] = [0, 2.46, 1.56, 2.46+1.56+3.32].
vg = [0, L(1), L(2), L(1) + L(2) + L(3)];
[pg, ig] = Shapley_Owen_Attribution(vg, 2);
check(abs(ig.interactions(1, 2) - L(3)) < tol, 'two-way interaction equals typed Wedge 1 (3.32)');
check(max(abs(pg - [L(1) + L(3) / 2; L(2) + L(3) / 2])) < tol, 'Shapley splits Wedge 1 equally');
check(abs(pg(1) - 4.12) < tol && abs(pg(2) - 3.22) < tol, 'Dual-Gate Shapley = [4.12 3.22]');

% 2^2 lattice over the two stacks {HC = levers 1,2 ; Spatial = levers 3,4,5}.
v_hc = L(1) + L(2) + L(3);                    % 7.34 (Document 3 prints the Tier-1 subtotal as 7.33 after rounding)
v_sp = L(4) + L(5) + L(6) + L(7);             % 5.61 (Document 3 prints the Tier-2 subtotal as 5.60 after rounding)
vb   = [0, v_hc, v_sp, v_hc + v_sp + L(8)];   % 18.15 (Document 1A.md prints the cumulative at L08 as 18.14)
[pb, ib] = Shapley_Owen_Attribution(vb, 2);
check(abs(ib.interactions(1, 2) - L(8)) < tol, 'two-way interaction equals typed Wedge 3 (5.20)');
check(abs(pb(1) - 9.94) < tol && abs(pb(2) - 8.21) < tol, 'Stack Shapley = [9.94 8.21]');

% =========================================================================
% 3. WHY SINGLE-PATH WEDGES ARE PATH-DEPENDENT (3-PLAYER ILLUSTRATION, SAME GAME AS THE UNIT TEST)
% =========================================================================
% Staircase wedge at step k = v(S_k) - v(S_{k-1}) - v({k-th lever}) along ONE build order.
v3 = [0 4 6 14 0 6 9 18];                                     % mask 0..7 = {} A B AB C AC BC ABC
w_abc = [v3(4) - v3(2) - v3(3),  v3(8) - v3(4) - v3(5)];     % build A, B, C
w_cba = [v3(7) - v3(3) - v3(5),  v3(8) - v3(7) - v3(2)];     % build C, B, A
check(isequal(w_abc, [4 4]) && isequal(w_cba, [3 5]), 'staircase wedges differ by build order');
check(sum(w_abc) == sum(w_cba), 'but their total is order-invariant');

% =========================================================================
% 4. PAIRWISE-ONLY ACCOUNTING OF THE SUITE'S OWN MATRICES (SHAPLEY = DIAGONAL + HALF EACH WEDGE)
% =========================================================================
% The 4x4 coalition matrix (Table 22, Plot_Doc3_...m lines 331-372) is a quadratic game: v(S) = sum diag(S) + sum of wedges inside S.
% Assumption flagged: no 3-way or higher dividend beyond what the matrix entries already absorb.
Raw_Mat_4x4    = [7.52 2.15 1.95 1.45; 2.15 5.06 1.15 0.65; 1.95 1.15 2.10 0.65; 1.45 0.65 0.65 0.95];
Mat            = Raw_Mat_4x4 * SS2_Nat / (trace(Raw_Mat_4x4) + sum(sum(triu(Raw_Mat_4x4, 1))));
off            = Mat - diag(diag(Mat));
v4 = quadratic_game(diag(Mat), Mat);
p4 = Shapley_Owen_Attribution(v4, 4);
check(max(abs(p4 - (diag(Mat) + 0.5 * sum(off, 2)))) < tol, '4x4: Shapley = diag + half of each wedge');
check(abs(sum(p4) - SS2_Nat) < tol, '4x4: Shapley sums to the national total');
check(isequal(round(100 * p4'), [1076 735 415 243]), '4x4: equal-split values 10.76 / 7.35 / 4.15 / 2.43');
p4o = Shapley_Owen_Attribution(v4, 4, {[1 2], [3 4]});
check(max(abs(p4o - p4)) < tol, '4x4: pairwise game, so Owen == Shapley for any partition');
full_row = diag(Mat) + sum(off, 2);                            % the "own base + 3 neighbour wedges" row totals
check(abs(sum(full_row) - (SS2_Nat + sum(sum(triu(off)))) ) < tol, '4x4: row totals count every wedge twice');
check(isequal(round(100 * full_row'), [1366 942 611 387]), '4x4: row totals 13.66 / 9.42 / 6.11 / 3.87');
check(round(100 * sum(full_row)) == 3306 && sum(full_row) > SS2_Nat + 8, '4x4: row totals sum to 33.06, above the national total');

H = [4.65 1.42 0.95 0.55 0.42 0.28 0.00; 1.42 1.15 0.57 0.25 0.08 0.04 0.00; 0.95 0.57 1.45 0.20 0.05 0.03 0.00; ...
     0.55 0.25 0.20 1.20 0.00 0.00 0.00; 0.42 0.08 0.05 0.00 1.45 1.10 0.00; 0.28 0.04 0.03 0.00 1.10 1.90 0.00; ...
     0.00 0.00 0.00 0.00 0.00 0.00 2.75];
check(isequal(H, H'), 'H_Comp is symmetric');
v7 = quadratic_game(diag(H), H);
p7 = Shapley_Owen_Attribution(v7, 7);
check(abs(sum(p7) - 20.49) < tol, '7x7: Shapley sums to the 12-layer total 20.49');
check(abs(sum(sum(triu(H(1:4, 1:4), 1))) - 3.94) < tol && abs(H(5, 6) - 1.10) < tol && abs(sum(sum(H(1:4, 5:6))) - 0.90) < tol, ...
      '7x7: cohort wedge totals 3.94 / 1.10 / 0.90 as labelled in the script');
check(max(abs(Shapley_Owen_Attribution(v7, 7, {1:4, 5:6, 7}) - p7)) < tol, '7x7: Owen(cohorts) == Shapley (pairwise game)');

% =========================================================================
% 5. WHAT IS MISSING FOR A FULL 7-LEVER SHAPLEY AND FOR OWEN WITH UNIONS
% =========================================================================
V = NaN(128, 1);
V(1)                       = 0;
iso = L([1 2 4 5 6 9 10]);
for k = 1:7, V(2^(k - 1) + 1) = iso(k); end
V(bitmask([1 2]) + 1)       = v_hc;
V(bitmask([3 4 5]) + 1)     = v_sp;
V(bitmask(1:5) + 1)         = v_hc + v_sp + L(8);
V(bitmask(1:7) + 1)         = total;
known = find(~isnan(V)) - 1;
check(numel(known) == 12, '12 of 128 coalition values exist');
check(abs(V(bitmask(1:5) + 1) - 18.15) < tol, 'v({1..5}) = 18.15');

unions4 = {[1 2], [4 5], 3, [6 7]};     % Document 3 coalitions: C1 Barnardos, C2 WellBeing, C3 GrowthNZ, C4 Fiscal
unions3 = {[1 2], [3 4 5], [6 7]};      % the suite's own HC / Spatial / Fiscal stacks
stub = @(mask) 0;
[~, iS]  = Shapley_Owen_Attribution(stub, 7);
[~, iO4] = Shapley_Owen_Attribution(stub, 7, unions4);
[~, iO3] = Shapley_Owen_Attribution(stub, 7, unions3);
check(numel(iS.masks_needed) == 128 && sum(~ismember(iS.masks_needed, known)) == 116, 'Shapley: 116 new coalition runs');
check(numel(iO4.masks_needed) == 64 && sum(~ismember(iO4.masks_needed, known)) == 52, 'Owen, 4 coalitions: 52 new runs');
check(numel(iO3.masks_needed) == 48 && sum(~ismember(iO3.masks_needed, known)) == 36, 'Owen, 3 stacks: 36 new runs');
check(all(ismember(known, iO4.masks_needed)) && all(ismember(known, iO3.masks_needed)), 'all 12 existing values are reused');
pairs = [];
for i = 1:7
    for j = i + 1:7
        pairs(end + 1) = 2^(i - 1) + 2^(j - 1); %#ok<AGROW>
    end
end
check(numel(pairs) == 21 && sum(~ismember(pairs, known)) == 20, 'pair-complete table: 20 new runs');

% With only the 12 known values the call refuses rather than guessing.
check(fails_with(@() Shapley_Owen_Attribution(V, 7), 'Shapley_Owen_Attribution:missingValues'), 'partial lattice errors');
check(fails_with(@() Shapley_Owen_Attribution(V, 7, unions4), 'Shapley_Owen_Attribution:missingValues'), 'partial lattice errors (Owen)');
end

% -------------------------------------------------------------------------
function v = quadratic_game(a, M)
% v(S) = sum_{i in S} a_i + sum_{i<j in S} M_ij, for all 2^n coalitions (index = mask + 1).
n = numel(a);
v = zeros(2^n, 1);
for mask = 0:2^n - 1
    in = logical(bitget(mask, 1:n));
    v(mask + 1) = sum(a(in)) + sum(sum(triu(M(in, in), 1)));
end
end

function mk = bitmask(members)
mk = sum(2 .^ (members - 1));
end

function tf = fails_with(f, id)
tf = false;
try
    f();
catch err
    tf = strcmp(err.identifier, id);
end
end

function check(cond, msg)
if ~cond, error('test_Shapley_Owen_SuiteExample:failed', 'FAILED: %s', msg); end
end
