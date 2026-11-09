#!/usr/bin/env python3
"""
rename_armada_to_te_kahui_waka.py
Context-aware refactoring of 'Armada' (and any accidental 'WakaHourua' fleet
substitutions) -> 'Te Kāhui Waka' ('TeKahuiWaka' in code) across MATLAB (.m)
scripts and Markdown (.md) documents in IGWelfare.
"""

import pathlib
import subprocess

REPO_ROOT = pathlib.Path(__file__).resolve().parent

# 1. Ordered Prose & Markdown Replacements (Applied ONLY to .md files)
MD_REPLACEMENTS = [
    # First, undo any accidental fleet-level *waka hourua* substitutions if the prior script was run
    ("Plot_Doc1D_WakaHouruaSequencing.m", "Plot_Doc1D_TeKahuiWakaSequencing.m"),
    ("Fig_Doc1D_13Wave_WakaHourua_Schedule", "Fig_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Fig_Doc1D_WakaHourua_Vs_SingleShot_JCurve", "Fig_Doc1D_TeKahuiWaka_Vs_SingleShot_JCurve"),
    ("Table23_Doc1D_13Wave_WakaHourua_Schedule", "Table23_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Table24_Doc1D_WakaHourua_Vs_SingleShot_Trajectory", "Table24_Doc1D_TeKahuiWaka_Vs_SingleShot_Trajectory"),
    (r"\Psi_{\mathrm{waka}}", r"\Psi_{\mathrm{kahui}}"),
    ("Ψ<sub>waka</sub>", "Ψ<sub>kahui</sub>"),
    ("Sequencing the *Waka Hourua* Fleet:", "Sequencing *Te Kāhui Waka*:"),
    ("echeloned *waka hourua* fleet (*Te Kāhui Waka*)", "echeloned voyaging fleet (*Te Kāhui Waka*)"),
    ("phasing a *waka hourua* fleet", "phasing *Te Kāhui Waka*"),
    ("13-Wave *Waka Hourua*", "13-Wave *Te Kāhui Waka*"),
    ("13-wave *waka hourua*", "13-wave *Te Kāhui Waka*"),
    ("The *Waka Hourua* rollout", "*Te Kāhui Waka*"),
    ("the *waka hourua* rollout", "*Te Kāhui Waka*"),
    ("our *waka hourua* fleet", "*Te Kāhui Waka*"),
    ("*Waka Hourua* Advantage", "*Te Kāhui Waka* Advantage"),
    ("*Waka Hourua* Rollout", "*Te Kāhui Waka* Rollout"),
    ("*Waka Hourua* Experience", "*Te Kāhui Waka* Experience"),
    ("*Waka Hourua* Schedule", "*Te Kāhui Waka* Schedule"),
    ("*Waka Hourua* vs", "*Te Kāhui Waka* vs"),
    ("*Waka Hourua* (`SS0", "*Te Kāhui Waka* (`SS0"),

    # Direct replacements from 'Armada' -> '*Te Kāhui Waka*'
    ("Plot_Doc1D_ArmadaSequencing.m", "Plot_Doc1D_TeKahuiWakaSequencing.m"),
    ("Fig_Doc1D_13Wave_Armada_Schedule", "Fig_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Fig_Doc1D_Armada_Vs_SingleShot_JCurve", "Fig_Doc1D_TeKahuiWaka_Vs_SingleShot_JCurve"),
    ("Table23_Doc1D_13Wave_Armada_Schedule", "Table23_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Table24_Doc1D_Armada_Vs_SingleShot_Trajectory", "Table24_Doc1D_TeKahuiWaka_Vs_SingleShot_Trajectory"),

    # LaTeX math subscripts
    (r"\Psi_{\mathrm{armada}}", r"\Psi_{\mathrm{kahui}}"),
    ("Ψ<sub>armada</sub>", "Ψ<sub>kahui</sub>"),

    # Specific Section 7.1 & 7.4 headings and literary phrases in Document 1D.md
    (
        "## 7. Sequencing the Armada: The 13-Wave Phased Rollout, Adjustment-Cost Mechanics, and Inter-Wave Learning (`Years 1–13`)",
        "## 7. Sequencing *Te Kāhui Waka*: The 13-Wave Phased Rollout, Adjustment-Cost Mechanics, and Inter-Wave Learning (`Years 1–13`)"
    ),
    (
        "## 7. Sequencing the Armada: The 13-Wave Phased Rollout, Adjustment-Cost Mechanics, and Inter-Wave Learning ( Years 1–13 )",
        "## 7. Sequencing *Te Kāhui Waka*: The 13-Wave Phased Rollout, Adjustment-Cost Mechanics, and Inter-Wave Learning (`Years 1–13`)"
    ),
    (
        "sailed in an **echeloned Armada (*Te Kāhui Waka*)**",
        "sailed in an **echeloned voyaging fleet (*Te Kāhui Waka*)**"
    ),
    (
        "sailed in an *echeloned Armada (* *Te Kāhui Waka* *)*",
        "sailed in an *echeloned voyaging fleet (Te Kāhui Waka)*"
    ),
    (
        "phasing an armada rather than firing a single-shot cannon",
        "phasing *Te Kāhui Waka* rather than firing a single-shot cannon"
    ),
    (
        "the **13-Wave Expenditure Armada** with the **Dual-Speed Revenue Armada**",
        "the **13-Wave *Te Kāhui Waka* Expenditure Rollout** with the **Dual-Speed *Te Kāhui Waka* Revenue Ramp**"
    ),
    (
        "The Dual-Speed Revenue Armada",
        "The Dual-Speed *Te Kāhui Waka* Revenue Ramp"
    ),
    (
        "while the Expenditure Armada is only at 13.3% scale",
        "while *Te Kāhui Waka*'s expenditure rollout is only at 13.3% scale"
    ),

    # General Markdown phrases (longest-first so articles like "the Armada" become "*Te Kāhui Waka*" without "the Te")
    ("the **13-Wave Armada**", "the **13-Wave *Te Kāhui Waka* Rollout**"),
    ("The **13-Wave Armada**", "The **13-Wave *Te Kāhui Waka* Rollout**"),
    ("13-Wave Armada", "13-Wave *Te Kāhui Waka*"),
    ("13-wave Armada", "13-wave *Te Kāhui Waka*"),
    ("The Armada's", "*Te Kāhui Waka*'s"),
    ("the Armada's", "*Te Kāhui Waka*'s"),
    ("The Armada", "*Te Kāhui Waka*"),
    ("the Armada", "*Te Kāhui Waka*"),
    ("our Armada", "*Te Kāhui Waka*"),
    ("Full Armada Live!", "Full *Te Kāhui Waka* Live!"),
    ("Full `SS1` Armada Complete", "Full `SS1` *Te Kāhui Waka* Complete"),
    ("Armada Advantage", "*Te Kāhui Waka* Advantage"),
    ("Armada Rollout", "*Te Kāhui Waka* Rollout"),
    ("Armada Experience", "*Te Kāhui Waka* Experience"),
    ("Armada Schedule", "*Te Kāhui Waka* Schedule"),
    ("Armada vs", "*Te Kāhui Waka* vs"),
    ("Armada (`SS0", "*Te Kāhui Waka* (`SS0"),
    ("Armada's", "*Te Kāhui Waka*'s"),
    ("Armada", "*Te Kāhui Waka*"),
]

# 2. Ordered MATLAB Code & Plot String Replacements (Applied ONLY to .m files)
M_REPLACEMENTS = [
    # Undo any prior WakaHourua code replacements if run
    ("Plot_Doc1D_WakaHouruaSequencing", "Plot_Doc1D_TeKahuiWakaSequencing"),
    ("PLOT_DOC1D_WAKAHOURUASEQUENCING", "PLOT_DOC1D_TEKAHUIWAKASEQUENCING"),
    ("Fig_Doc1D_13Wave_WakaHourua_Schedule", "Fig_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Fig_Doc1D_WakaHourua_Vs_SingleShot_JCurve", "Fig_Doc1D_TeKahuiWaka_Vs_SingleShot_JCurve"),
    ("Table23_Doc1D_13Wave_WakaHourua_Schedule", "Table23_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Table24_Doc1D_WakaHourua_Vs_SingleShot_Trajectory", "Table24_Doc1D_TeKahuiWaka_Vs_SingleShot_Trajectory"),
    ("'WakaHourua'", "'TeKahuiWaka'"),
    ("WakaHourua", "TeKahuiWaka"),
    ("Waka Hourua", "Te Kahui Waka"),

    # Function & Script Header / File Names from 'Armada'
    ("function Out = Plot_Doc1D_ArmadaSequencing", "function Out = Plot_Doc1D_TeKahuiWakaSequencing"),
    ("PLOT_DOC1D_ARMADASEQUENCING", "PLOT_DOC1D_TEKAHUIWAKASEQUENCING"),
    ("Plot_Doc1D_ArmadaSequencing", "Plot_Doc1D_TeKahuiWakaSequencing"),
    ("Fig_Doc1D_13Wave_Armada_Schedule", "Fig_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Fig_Doc1D_Armada_Vs_SingleShot_JCurve", "Fig_Doc1D_TeKahuiWaka_Vs_SingleShot_JCurve"),
    ("Table23_Doc1D_13Wave_Armada_Schedule", "Table23_Doc1D_13Wave_TeKahuiWaka_Schedule"),
    ("Table24_Doc1D_Armada_Vs_SingleShot_Trajectory", "Table24_Doc1D_TeKahuiWaka_Vs_SingleShot_Trajectory"),

    # Backward-compatible Rollout_Mode checks (accepts both 'TeKahuiWaka' and legacy 'Armada')
    (
        "Params.Rollout_Mode             = 'Armada';",
        "Params.Rollout_Mode             = 'TeKahuiWaka';"
    ),
    (
        "Params.Rollout_Mode = 'Armada';",
        "Params.Rollout_Mode = 'TeKahuiWaka';"
    ),
    (
        "strcmpi(Params.Rollout_Mode, 'Armada')",
        "any(strcmpi(Params.Rollout_Mode, {'TeKahuiWaka', 'Armada'}))"
    ),
    (
        "strcmpi(Params_SS0.Rollout_Mode, 'Armada')",
        "any(strcmpi(Params_SS0.Rollout_Mode, {'TeKahuiWaka', 'Armada'}))"
    ),

    # MATLAB Table Column Names & Struct Field Identifiers
    ("Welfare_Armada_PlanB_CE", "Welfare_TeKahuiWaka_PlanB_CE"),
    ("Welfare_Armada_PlanC_CE", "Welfare_TeKahuiWaka_PlanC_CE"),
    ("GrossInv_Armada_CE", "GrossInv_TeKahuiWaka_CE"),
    ("NetUnrecovered_Armada_CE", "NetUnrecovered_TeKahuiWaka_CE"),
    ("Actuarial_Armada_CE", "Actuarial_TeKahuiWaka_CE"),
    ("Debt_Armada_PctGDP", "Debt_TeKahuiWaka_PctGDP"),
    ("Total_Armada_Welfare_CE_Pct", "Total_TeKahuiWaka_Welfare_CE_Pct"),
    ("Total_Armada_Welfare_BNZD_Yr", "Total_TeKahuiWaka_Welfare_BNZD_Yr"),
    ("Total_Gross_Inv_Armada_CE_Pct", "Total_Gross_Inv_TeKahuiWaka_CE_Pct"),
    ("Total_Gross_Inv_Armada_BNZD_Yr", "Total_Gross_Inv_TeKahuiWaka_BNZD_Yr"),
    ("Net_Unrecovered_Outlay_Armada_CE", "Net_Unrecovered_Outlay_TeKahuiWaka_CE"),
    ("Actuarial_CBAx_Armada_CE_Pct", "Actuarial_CBAx_TeKahuiWaka_CE_Pct"),
    ("Table23_ArmadaSchedule", "Table23_TeKahuiWakaSchedule"),
    ("Fig1_ArmadaSchedule", "Fig1_TeKahuiWakaSchedule"),
    ("Fig2_ArmadaJCurve", "Fig2_TeKahuiWakaJCurve"),

    # Internal MATLAB Array / Variable Names
    ("Welf_Armada_PlanB", "Welf_Kahui_PlanB"),
    ("Welf_Armada_PlanC", "Welf_Kahui_PlanC"),
    ("GInv_Armada", "GInv_Kahui"),
    ("Unrec_Armada", "Unrec_Kahui"),
    ("Act_Armada", "Act_Kahui"),
    ("Debt_Armada", "Debt_Kahui"),
    ("Tau_Fric_Armada", "Tau_Fric_Kahui"),
    ("Eff_Yield_Armada", "Eff_Yield_Kahui"),
    ("YGr_Armada_Outlay_BNZD", "YGr_Kahui_Outlay_BNZD"),
    ("Pos_11_Armada", "Pos_11_Kahui"),
    ("Pos_12_Armada", "Pos_12_Kahui"),
    ("Neg_4Inv_Armada_CE", "Neg_4Inv_Kahui_CE"),
    ("Neg_5_Armada", "Neg_5_Kahui"),
    ("Total_Armada_CE", "Total_Kahui_CE"),
    ("Gross_Inv_Armada_CE", "Gross_Inv_Kahui_CE"),
    ("Net_Fiscal_Outlay_Armada_CE", "Net_Fiscal_Outlay_Kahui_CE"),
    ("Actuarial_CBAx_Armada_CE", "Actuarial_CBAx_Kahui_CE"),
    ("Enrolled_Share_Armada", "Enrolled_Share_Kahui"),
    ("is_armada_mode", "is_kahui_mode"),
    ("t_armada_lag", "t_kahui_lag"),
    ("remed_armada", "remed_kahui"),
    ("Psi_armada", "Psi_kahui"),

    # MATLAB Plot Titles, Legends, Axis Labels & Console Strings
    ("13-Wave Armada", "13-Wave Te Kāhui Waka"),
    ("Full Armada", "Full Te Kāhui Waka"),
    ("Armada Wave", "Te Kāhui Waka Wave"),
    ("Armada Launch", "Te Kāhui Waka Launch"),
    ("Armada +", "Te Kāhui Waka +"),
    ("Armada Effective", "Te Kāhui Waka Effective"),
    ("Armada ACC", "Te Kāhui Waka ACC"),
    ("Armada Annual", "Te Kāhui Waka Annual"),
    ("Armada Cash", "Te Kāhui Waka Cash"),
    ("Armada Upfront", "Te Kāhui Waka Upfront"),
    ("Armada Peak", "Te Kāhui Waka Peak"),
    ("Armada Debt", "Te Kāhui Waka Debt"),
    ("Armada Youth-Grant", "Te Kāhui Waka Youth-Grant"),
    ("Armada Waves", "Te Kāhui Waka Waves"),
    ("Armada Expansion", "Te Kāhui Waka Expansion"),
    ("Armada Yrs", "Te Kāhui Waka Yrs"),
    ("Armada Trajectory", "Te Kāhui Waka Trajectory"),
    ("Armada Plan", "Te Kāhui Waka Plan"),
    ("Armada S-Curve", "Te Kāhui Waka S-Curve"),
    ("Armada vs", "Te Kāhui Waka vs"),
    ("vs. Armada:", "vs. Te Kāhui Waka:"),
    ("in Armada", "in Te Kāhui Waka"),
]


def apply_replacements(path: pathlib.Path, pairs: list[tuple[str, str]]) -> bool:
    orig = path.read_text(encoding="utf-8")
    text = orig
    for old, new in pairs:
        text = text.replace(old, new)
    if text != orig:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main():
    # Step 1: git mv Plot_Doc1D_ArmadaSequencing.m (or WakaHouruaSequencing.m) -> Plot_Doc1D_TeKahuiWakaSequencing.m
    target_script = REPO_ROOT / "Plot_Doc1D_TeKahuiWakaSequencing.m"
    for candidate_name in ("Plot_Doc1D_ArmadaSequencing.m", "Plot_Doc1D_WakaHouruaSequencing.m"):
        cand = REPO_ROOT / candidate_name
        if cand.exists() and not target_script.exists():
            res = subprocess.run(["git", "mv", str(cand), str(target_script)], cwd=REPO_ROOT)
            if res.returncode != 0:
                cand.rename(target_script)
            print(f"Renamed: {cand.name} -> {target_script.name}")

    # Step 2: Update all .m files
    for m_file in sorted(REPO_ROOT.glob("*.m")):
        if apply_replacements(m_file, M_REPLACEMENTS):
            print(f"Updated MATLAB script: {m_file.name}")

    # Step 3: Update all .md files
    for md_file in sorted(REPO_ROOT.glob("*.md")):
        if apply_replacements(md_file, MD_REPLACEMENTS):
            print(f"Updated Markdown doc:  {md_file.name}")


if __name__ == "__main__":
    main()
