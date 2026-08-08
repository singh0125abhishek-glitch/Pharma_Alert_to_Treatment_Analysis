# ProcDNA Case Study: Nexavir | PrimeRx Flow
### Alert-to-Treatment & Commercial Opportunity Analysis (2026–27)


A pharma commercial analytics case study analyzing HCP (doctor) clinical alert, prescription, and account affiliation data to identify missed treatment opportunities and build a data-driven sales prioritization strategy for **Nexavir (DRG001)**.

---

## 📑 Table of Contents

- [Business Context](#-business-context)
- [Problem Statement](#-problem-statement)
- [Datasets](#️-datasets)
- [Analysis Questions & Methodology](#-analysis-questions--methodology)
- [Tools & Skills Demonstrated](#️-tools--skills-demonstrated)
- [Key Deliverables](#-key-deliverables)
- [Repository Structure](#-repository-structure)
- [How to Run](#-how-to-run)
- [Executive Summary](#-executive-summary)

---

## 📌 Business Context

**PrimeRx** is a pharmaceutical company operating across the U.S. healthcare landscape. Its flagship product, **Nexavir (DRG001)**, is a treatment designed for a high clinical need condition with broad prescriber adoption potential.

The core commercial challenge: doctors (HCPs) are diagnosing patients who may need treatment — evidenced by clinical alerts — but **not all of them are prescribing Nexavir**. Some prescribe competitor drugs, some prescribe nothing at all, and some accounts (hospitals/clinics) systematically underconvert relative to their diagnostic activity.

This project simulates being handed 18 months of real-world clinical and commercial data and asked to turn it into a prioritized, capacity-aware go-to-market action plan for the sales organization.

## 🧩 Problem Statement

> Doctors are seeing clinical need (via alerts), but prescribing behavior doesn't always follow. Using clinical alert, doctor affiliation, and prescription sales data, identify **which HCPs and accounts represent the biggest commercial opportunity**, and translate that into a **concrete, resource-constrained sales action plan**.

Specifically, the analysis needed to surface:
- HCPs and accounts with high prescription *and* alert activity
- Doctors receiving strong clinical signals but writing few or no prescriptions
- Accounts with low prescription activity relative to their doctor base
- A prioritized shortlist of HCPs/accounts for the sales team to target

---

## 🗂️ Datasets

Three datasets capture different stages of the patient treatment journey, all linkable via `HCP_ID`:

### 1. Alerts (9,537 rows)
Clinical signals generated at the doctor level indicating a patient likely needs treatment.

| Column | Description |
|---|---|
| `Alert_ID` | Unique identifier for each alert |
| `Alert_Date` | Date the alert was generated |
| `HCP_ID` | Doctor associated with the alert |
| `Lab_Result` | Outcome of the clinical signal — `positive` / `negative` |

### 2. Sales (5,917 rows)
Prescription activity across doctors and therapies (our drug + competitors).

| Column | Description |
|---|---|
| `Prescription_ID` | Unique prescription event |
| `Prescription_Date` | Date the prescription was written |
| `HCP_ID` | Prescribing doctor |
| `Drug_Name` / `Drug_ID` | Drug prescribed (Nexavir = `DRG001`, or a competitor) |
| `Prescription_Volume` | Units/scripts prescribed |

### 3. Affiliation (216 rows)
Maps doctors to their hospital/clinic/account.

| Column | Description |
|---|---|
| `HCP_ID` | Doctor identifier |
| `Account_ID` | Affiliated hospital/clinic/account |
| `Account_Name` | Account display name |

**Join key across all three tables:** `HCP_ID`

---

## 🎯 Analysis Questions & Methodology

### Q1 — Who are the most active doctors, and are they helping our product?
**Scope:** Only doctors with ≥1 alert record (the "alerts universe").
- **Ranking 1:** Top 10 HCPs by total alert volume
- **Ranking 2:** Top 10 HCPs (from the same universe) by total prescription volume in Sales

This establishes two lenses on "activity" — clinical signal strength vs. actual prescribing — and sets up the gap analysis in later questions.

### Q2 — Which doctors see the need but don't act on it?
- Filter the alerts universe to HCPs with **at least one positive lab alert**
- For each, check for **any prescription (any drug)** within a **30-day window** after their **first** positive alert
- Among HCPs with **zero** prescribing activity in that window, rank the **Top 10 by total positive alert volume**
- Build a **conversion funnel**:
  1. HCPs with ≥1 positive alert
  2. HCPs with multiple positive alerts
  3. HCPs with multiple positive alerts **but zero** prescriptions within 30 days

This isolates the highest-signal, lowest-conversion doctors — prime targets for outreach.

### Q3 — Among our top doctors, how much business is going to competitors?
Using the **Top 10 by alert volume** from Q1:
- Calculate each HCP's prescription volume split between **Our Drug (DRG001)** and **all competitor drugs**
- Identify the single **competitor drug** capturing the largest share of prescription volume among these high-alerting doctors

This quantifies "share of voice" loss among the doctors who matter most.

### Q4 — Which hospitals are sitting on the biggest untapped opportunity?
Using the Affiliation table, roll alert activity up to the **account (hospital/clinic)** level:
- Top 10 accounts by total alert volume (summed across affiliated doctors)
- For each: **Total Alert Count**, **Our Drug Prescription Count**, and a **Conversion Ratio**:

```
Conversion Ratio = Our Drug Prescription Count / Total Alert Count
```

- Rank by **lowest** conversion ratio → high-signal, low-conversion accounts

### Q5 — Which accounts represent the largest untapped prescription opportunity?
- Determine total affiliated doctors per account
- Determine **active prescribers** (doctors who wrote ≥1 prescription for Our Drug) per account
- Calculate account-level prescription volume for Our Drug
- Rank Top 10 accounts by **lowest Prescriptions-per-Active-Doctor ratio**:

```
Prescriptions per Active Doctor = Our Drug Prescription Volume / # Active Prescribers
```

- Visualize as a **scatter plot**: account size (affiliated doctors) vs. efficiency ratio, to flag large-but-underperforming accounts

### Q6 — Did alerts actually change doctor behavior? (Before vs. After)
**Part A — Basic Lift**
- Define a 90-day window **before** and 90-day window **after** each doctor's first positive alert
- Compare Our Drug prescription volume in each window
- Rank Top 10 HCPs by **Lift %**:

```
Lift % = (Post-Alert Volume − Pre-Alert Volume) / Pre-Alert Volume × 100
```

**Part B — Segment the Lift**
Bucket all HCPs into three behavioral segments:

| Segment | Definition |
|---|---|
| **New Starters** | Pre-alert volume = 0, Post-alert volume > 0 |
| **Growers** | Pre-alert volume > 0 **and** Lift % ≥ +20% |
| **Non-Responders** | Everything else (flat or declining) |

Compare average lift by segment to identify which group shows the strongest commercial response to alerts.

### Q7 — Commercial HCP Prioritization (Capacity-Constrained Planning)
Given field-force constraints:
- ~8 effective HCP calls per rep per day
- ~20 field days per rep per month
- 40 sales reps nationally

```
Total Quarterly Call Capacity = 40 reps × 20 days/month × 3 months × 8 calls/day
                               = 19,200 calls/quarter
```

Using the segments from Q6 (New Starters, Growers, Non-Responders), allocate this fixed capacity across segments — balancing:
- **Growth opportunity** (headroom to convert)
- **Conversion likelihood** (demonstrated responsiveness to alerts)
- **Effort required** (calls needed to move the needle)

Deliverable: a segment-level table of suggested **% of rep calls**, **estimated quarterly calls**, and **estimated rep allocation**.

---

## 🛠️ Tools & Skills Demonstrated

| Category | Details |
|---|---|
| **Data Wrangling** | Multi-table joins on `HCP_ID`, deduplication, date-window filtering |
| **Analytical Techniques** | Top-N ranking, funnel/cohort analysis, before/after lift analysis, rule-based segmentation |
| **Business Metrics Design** | Conversion ratio, prescriptions-per-active-doctor, lift %, capacity allocation modeling |
| **Visualization** | Funnel chart, scatter plot (account size vs. efficiency), before/after comparison charts |
| **Storytelling** | Translating raw metrics into a prioritized, resource-constrained commercial action plan |

> *Add the specific tools you used — e.g., Python (Pandas, NumPy, Matplotlib/Seaborn), SQL, Excel, Power BI/Tableau, Jupyter Notebook.*

---

## 📊 Key Deliverables

- ✅ Top 10 HCP rankings by alert volume and by prescription volume
- ✅ Positive-alert → prescription conversion funnel + non-converting HCP shortlist
- ✅ Competitive share-of-voice breakdown among top-alerting HCPs
- ✅ Account-level conversion ratio rankings (alert-based)
- ✅ Account-level prescription efficiency rankings + scatter plot
- ✅ 90-day before/after lift analysis with 3-way behavioral segmentation
- ✅ Quarter-level, capacity-constrained sales rep call-allocation plan
- ✅ Executive summary with strategic recommendations for leadership

---

## 📁 Repository Structure

```
├── data/
│   ├── alerts.csv          # Clinical alert records
│   ├── sales.csv           # Prescription transaction records
│   └── affiliation.csv     # HCP-to-account mapping
├── notebooks/
│   └── analysis.ipynb      # End-to-end analysis (Q1–Q7)
├── outputs/
│   ├── charts/              # Funnel, scatter, lift charts
│   └── tables/               # Exported ranking tables (CSV/XLSX)
├── PrimeRx_Case_Study.pptx   # Final presentation deck
└── README.md
```

---

## 🚀 How to Run

```bash
# Clone the repo
git clone <your-repo-url>
cd <repo-name>

# Install dependencies
pip install -r requirements.txt

# Run the analysis
jupyter notebook notebooks/analysis.ipynb
```

> *Update the run instructions above to match your actual environment (Python/SQL/Excel/BI tool).*

---

## 📈 Executive Summary

*Add your final strategic recommendations here once the analysis is complete. Suggested structure:*
- **Headline finding** — the single biggest commercial opportunity uncovered
- **Segment-level insights** — which HCP/account segments matter most and why
- **Recommended actions** — prioritized outreach plan and expected impact
- **Next steps / limitations** — data gaps, follow-on analysis needed

---


*This case study was completed as part of the ProcDNA analytics case study series (2026–27).*
