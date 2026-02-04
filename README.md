# Funes workshop

A host application that demonstrates the [`funes-rails`](https://github.com/funes-org/funes) gem.

## Getting started

To see the core concepts in action, start with:

- [`app/projections/virtual_debt_projection.rb`](app/projections/virtual_debt_projection.rb) — a projection that derives debt state from events
- [`test/projections/virtual_debt_projection_test.rb`](test/projections/virtual_debt_projection_test.rb) — tests that illustrate how the projection behaves

## Use case

The problem being solved as demonstration. **Disclaimer:** this is an over simplification for didactic purposes.  

### Debt life-cycle management

- Simple interest (only over the principal balance) accrued daily
- Fixed annual interest rate
- Non pre-established repayment scheduling
    - Payments anytime with any value
    - All payments pays interest first, principal later
    - Payments, to be considered valid, must cover at least the accrued interest

**Interest formula:** `accrued_interest = principal × (annual_rate / 365) × days_elapsed`

#### Interest accrual without payment

$ 10.000 as principal and 10% as annual interest.

| Date       | Days elapsed | Principal   | Acc interest | Payment | Present value |
|:-----------|:------------|:------------|:-------------|:--------|:--------------|
| 01/01/2025 | 0           | $ 10,000.00 | $ 0.00       | $ 0.00  | $ 10,000.00   |
| 01/01/2026 | 365         | $ 10,000.00 | $ 1,000.00   | $ 0.00  | $ 11,000.00   |

![](https://raw.github.com/viniciusalmeida/funes_workshop/main/chart.png)

#### Interest accrual with payment

$ 10.000 as principal and 10% as annual interest. With payment ~6 months after the contract date. 

| OBS             | Date       | Days elapsed | Principal   | Acc interest | Payment     | Present value |
|:----------------|:-----------|:-----|:------------|:-------------|:------------|:--------------|
|                 | 01/01/2025 | 0    | $ 10,000.00 | $ 0.00       | $ 0.00      | $ 10,000.00   |
| Payment         | 07/01/2025 | 181  | $ 10,000.00 | $ 495.89     | $ -5,000.00 | $ 10,495.89   |
| Post pay. state | 07/01/2025 | 0    | $ 5,495.89  | $ 0.00       | $ 0.00      | $ 5,495.89    |
|                 | 01/01/2026 | 184  | $ 5,495.89  | $ 277.05     | $ 0.00      | $ 5,772.94    |

![](https://raw.github.com/viniciusalmeida/funes_workshop/main/chart-2.png)

#### Interest accrual with payment and final repayment

$ 10.000 as principal and 10% as annual interest. With payment ~6 months after the contract date and final repayment 1 year after the contract date.

| OBS                 | Date       | Days elapsed | Principal   | Acc interest | Payment     | Present value |
|:--------------------|:-----------|:-----|:------------|:-------------|:------------|:--------------|
|                     | 01/01/2025 | 0    | $ 10,000.00 | $ 0.00       | $ 0.00      | $ 10,000.00   |
| 1st payment         | 07/01/2025 | 181  | $ 10,000.00 | $ 495.89     | $ -5,000.00 | $ 10,495.89   |
| Post 1st pay. state | 07/01/2025 | 0    | $ 5,495.89  | $ 0.00       | $ 0.00      | $ 5,495.89    |
| 2nd payment         | 01/01/2026 | 184  | $ 5,495.89  | $ 277.05     | $ -5,772.94 | $ 5,772.94    |
| Post 2nd pay. state | 01/01/2026 | 0    | $ 0.00      | $ 0.00       | $ 0.00      | $ 0.00        |

![](https://raw.github.com/viniciusalmeida/funes_workshop/main/chart-3.png)
