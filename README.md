# E-Commerce Sales Data Cleaning Project

A structured, SQL-based data cleaning workflow applied to a synthetic e-commerce sales dataset, executed end-to-end in SQLite Online.

---

## Executive Summary

This project documents a complete data cleaning pipeline applied to a 720-row, 12-column e-commerce sales dataset. The raw data was deliberately seeded with the categories of data quality issues encountered routinely in production environments: missing values, duplicate records, inconsistent text formatting, logically invalid numeric entries, and statistical outliers.

Using a twelve-step SQL pipeline built around a consistent three-part procedure — detection via diagnostic query, remediation via a defined and auditable rule, and documentation of the rationale behind each decision — the dataset was reduced from 720 to 700 rows following exact-duplicate removal, with every other identified issue either resolved directly or explicitly documented as a known limitation.

The cleaned dataset is ready to support core reporting use cases, including revenue and order-value reporting, category- and city-level sales analysis, and customer segmentation, once known limitations (below) are accounted for.

---

## Business Problem

Raw operational data — whether sourced from forms, sensors, manual entry, or system logs — rarely arrives in a state suitable for direct analysis. Left unaddressed, missing values, duplicate records, inconsistent formatting, and invalid entries propagate into downstream calculations, distorting aggregate metrics and undermining confidence in any business decision built on top of them.

This project simulates that exact scenario: a synthetic e-commerce sales dataset seeded with realistic data quality defects, cleaned using a reproducible, fully auditable SQL workflow so that revenue reporting, order-value analysis, and customer segmentation can be trusted downstream.

---

## Methodology

The project follows the standard six-stage data cleaning methodology used across the analytics industry, with every corrective decision governed by one consistent rule:

**Decision Framework — NULL vs. Drop vs. Impute**

| Treatment | When Used |
|---|---|
| **Set to NULL** | Value is missing or logically invalid, with no reliable evidence elsewhere in the row to reconstruct it |
| **Impute (rule-based)** | A deterministic relationship exists elsewhere in the same row (e.g. `state` derived from standardized `city`) |
| **Drop the row** | Reserved exclusively for exact full-row duplicates |
| **Flag / document** | The environment lacks the capability to resolve the issue reliably (e.g. mixed date formats in SQLite) |

**Pipeline stages:**

1. **Data Profiling / Baseline Assessment** — established dataset structure and a row-count control total (720 rows) prior to any modification
2. **Handling Missing Data** — column-by-column NULL/blank audit across all 12 fields, using `TRIM` checks for text columns and count-difference checks for numeric columns
3. **Data Standardization** — normalized casing, whitespace, and spelling variants (`city`, `state`, `category`, `product`, `payment_method`, `order_status`) to single canonical values via a normalize-then-map pattern
4. **Data Validation** — enforced business-logic constraints on numeric fields (`quantity`, `unit_price` must be strictly positive) and cross-referenced categorical domains
5. **Outlier Detection & Treatment** — investigated statistically extreme values (`quantity = 999`, `unit_price = 999,999`) and identified them as data-entry sentinel values rather than genuine transactions, based on the value recurring identically across unrelated products
6. **Deduplication** — grouped on all 12 columns simultaneously to identify true exact-match duplicates, retaining one canonical row per group

Every stage followed the same evidence-first principle: no value was ever fabricated or estimated. Where a reliable basis for correction did not exist, the value was preserved as `NULL` and the gap was documented rather than masked.

---

## Skills

- **SQL (SQLite dialect):** `SELECT`, `UPDATE`, `DELETE`, aggregate functions (`COUNT`, `MIN`, `MAX`), `GROUP BY` / `HAVING`, `DISTINCT`, `TRIM`, `LOWER`, `CASE`, subqueries, `rowid`-based deduplication
- **Data quality diagnostics:** null/blank detection, domain-validity checks, outlier investigation, duplicate detection
- **Data standardization:** normalize-then-map pattern for categorical text cleanup
- **Rule-based imputation:** deterministic lookup imputation (city → state) as distinct from statistical estimation
- **Documentation and auditability:** control totals, before/after reconciliation, explicit treatment of known limitations
- **Tools:** SQLite Online (browser-based SQL environment), ChatGPT (synthetic dataset generation)

---

## Results

| Metric | Result |
|---|---|
| Rows before cleaning | 720 |
| Rows after cleaning | 700 |
| Duplicate rows removed | 20 |
| Missing `state` values | 34 → resolved via city-to-state mapping |
| Missing `product` values | 34 → standardized to NULL |
| Missing `payment_method` values | 143 → standardized to NULL |
| Invalid `quantity` values corrected | 12 (zero or negative) |
| Invalid `unit_price` values corrected | 3 (negative) |
| Outlier `quantity` values corrected | 3 rows at value 999 |
| Outlier `unit_price` values corrected | 4 rows at value 999,999 |
| Text columns standardized | `customer_name`, `city`, `state`, `category`, `product`, `payment_method`, `order_status` |
| Known unresolved issue | `order_date` stored in three inconsistent formats (documented limitation) |

**Changes by stage:**

| Stage | Action | Rows Affected |
|---|---|---|
| 1 — Missing Values | Blanks converted to NULL (`state`, `product`, `payment_method`) | 34 + 34 + 143 = 211 |
| 2 — Text Standardization | Casing / whitespace / spelling normalized | All rows, 7 columns |
| 3 — Data Validation | Invalid numeric values set to NULL (`quantity` ≤ 0, `unit_price` ≤ 0) | 12 + 3 = 15 |
| 3 — Data Validation | `state` imputed from standardized `city` | 34 |
| 4 — Outlier Treatment | Sentinel values set to NULL (`quantity` = 999, `unit_price` = 999,999) | 3 + 4 = 7 |
| 5 — Deduplication | Exact-duplicate rows deleted | 20 |

---

## Business Recommendations

1. **Resolve `payment_method` gaps before payment-mix reporting.** At 143 rows (roughly 20% of the dataset), this is the single largest data quality gap and can materially understate any under-represented payment channel. In order of preference: (1) join `order_id` against payment gateway or transaction logs to recover the true value; (2) label unresolved rows explicitly as "Unknown" so reports show a labeled unattributed bucket rather than silently dropping records; (3) apply targeted imputation from a customer's most frequent historical payment method only where logs are unavailable, and flag it clearly as modeled rather than observed data.

2. **Filter or flag NULLs before aggregation.** Rows carrying a NULL in `quantity`, `unit_price`, or `payment_method` should be excluded or explicitly flagged in revenue, order-value, and channel-level calculations until resolved, to avoid silently understating totals.

3. **Migrate `order_date` parsing to an engine with native date-format support.** SQLite lacks equivalent support for MySQL's `STR_TO_DATE()`, so the three mixed date formats in this dataset could not be consolidated into a single `DATE` type. Any time-series or cohort analysis should first route through the MySQL normalization snippet included in the SQL file, or an equivalent pandas-based parser.

4. **Adopt a repeated-sentinel check as a standing outlier detection rule.** The values 999 and 999,999 recurred identically across unrelated products, a strong signal of system placeholder values rather than genuine variance. A statistical-only approach (IQR or z-score) would risk missing sentinels that fall inside normal bounds, or incorrectly flagging legitimate high-value transactions. Pairing an exact-repeat check with a statistical pass gives more reliable coverage going forward.

5. **Standardize input validation at the point of entry.** The casing, whitespace, and spelling inconsistencies found in `city`, `state`, `category`, and `product` are best prevented upstream with constrained input fields (dropdowns, autocomplete against a reference list) rather than corrected retroactively, reducing the ongoing cleaning burden on future data pulls.

---

## Repository Contents

- `README.md` — this report
- `data_cleaning_pipeline.sql` — full, ordered SQL script with inline comments covering all 12 pipeline steps
- Raw and cleaned CSV exports (uncleaned and final datasets), enabling row-by-row verification of the transformation against this documented procedure
- Project report — detailed project report describing the cleaning process, SQL queries, decisions made, issues identified, and final outcomes

---

**Author:** Chandrachud Sahi
**Dataset:** E-Commerce Sales Data (synthetic, generated with ChatGPT)
**Environment:** SQLite Online
