# scripts/augment_commitment_catalog_mirage_cols.py
from pathlib import Path
import pandas as pd

csv_path = Path("profiles/NZ_Dunedin1972/policies/commitment_catalog.csv")
df = pd.read_csv(csv_path)
assert len(df) == 18 and df["Commitment_ID"].iloc[7] == "C08_smokefree_public_health_excise"

aug = [
    ("Landlord Interest Deductibility",        2.90, -1.00,  5.5, 2),
    ("Callaghan & Science Wind-Down",          0.65,  1.00,  7.5, 1),
    ("Core Public Service Redundancies",       1.50,  1.00,  4.5, 1),
    ("iReX Rail-Ferry Cancellation",           0.80,  0.35,  5.5, 1),
    ("Dunedin Hospital & Clinical Deferral",   0.55,  1.00,  6.5, 1),
    ("Pay Equity Repeal & ECE Squeeze",        1.40,  1.00, 10.0, 1),
    ("Tertiary Fees-Free Repeal",              0.85,  1.00,  6.5, 1),
    ("Tobacco Freeze & Smokefree Repeal",      0.30,  1.00,  8.0, 1),
    ("Working-Age Tax Threshold Relief",      14.70, -1.00,  3.5, 2),
    ("Active Investor Plus Visa Inflow",       4.40,  0.08,  6.0, 3),
    ("20% Immediate Asset Expensing",          1.70, -1.00,  4.5, 3),
    ("Educator Real Pay Compression",          0.75,  1.00,  9.0, 1),
    ("KiwiSaver Match Cut & 30% Social IRR",   2.60,  1.00, 10.5, 1),
    ("Three Waters Devolution & Rates Cap",    1.20,  0.80,  7.0, 1),
    ("Grassroots Arts, Sport & Civic Cuts",    0.35,  1.00,  8.5, 1),
    ("Paris NDC Shortfall & Clean-Car Repeal", 0.95,  0.45,  5.5, 1),
    ("Distressed Network/Grid Privatization",  3.20,  1.00,  6.5, 1),
    ("Unfunded 3.0% GDP Defence Posture",      8.00, -1.00,  3.0, 1),
]
df["Short_Label"]        = [r[0] for r in aug]
df["Claimed_4Yr_BNZD"]   = [r[1] for r in aug]
df["Fiscal_Mirage_Sign"] = [r[2] for r in aug]
df["Tau_Onset_Yrs"]      = [r[3] for r in aug]
df["Mirage_Category"]    = [r[4] for r in aug]
df.to_csv(csv_path, index=False, lineterminator="\n")
print(f"Updated {csv_path} ({len(df)} rows).")