# Business Problem Statement

## Background

The dataset covers a multi-sided marketplace: ~99K orders, ~3,100 sellers, ~99K unique customers, order items, payments, reviews, products, and a 1M-row geolocation table mapping zip prefixes to lat/long. Most public analyses of this dataset stop at "late delivery hurts review score" — that story is real but already well covered and doesn't tell the business anything it can act on beyond "ship faster." A quick pass through the numbers surfaces three sharper, less-explored risks sitting underneath the surface metrics:

- The **top 10% of sellers generate 67.5% of platform revenue**, and the top 1% alone account for 25.7% — a concentration level that makes the marketplace structurally dependent on a small seller base.
- **63.8% of orders ship cross-state**, and freight cost exceeds 50% of item price on **16.8% of orders** (median freight-to-price ratio: 23%) — a logistics cost problem independent of delivery speed.
- Only **0.74% of orders contain more than one product category** — basket composition is almost entirely single-category, meaning the platform is not capturing cross-sell value it likely has access to.

These are commercial and operational risk questions, not just fulfillment questions, and they haven't been picked apart as often.

## Business Objective

Quantify the platform's dependency on a concentrated seller base, the cost inefficiency of its cross-state logistics footprint, and the untapped cross-sell opportunity in customer baskets — then turn those into concrete, prioritized recommendations for seller management, logistics/pricing policy, and merchandising.

## Workstreams

**Problem 1 — Seller Concentration & Revenue Dependency Risk**
Measure how much of GMV, order volume, and category coverage sits with the top decile of sellers, and identify which categories or regions have the thinnest seller bench (single-seller or near-monopoly exposure).

**Problem 2 — Cross-State Freight Cost Inefficiency**
Using the geolocation table to compute seller-to-customer distance, quantify how freight cost and freight-to-price ratio scale with distance and cross-state shipping, and flag routes/categories where freight economics are structurally broken (freight exceeding item value).

**Problem 3 — Installment Payment Risk Exposure**
Profile how order value, category, and customer region relate to installment count (payments split up to 24x), and estimate the platform's exposure to deferred-revenue risk versus upfront-paid orders.

**Problem 4 — Cross-Sell / Basket Concentration Gap**
Quantify how rarely orders span multiple categories (0.74%) versus how often a customer's *lifetime* purchase history spans categories, to test whether the gap is a real merchandising opportunity or just how the marketplace naturally behaves.

## Final Deliverable

- **SQL analysis** (`marketplace_analysis.sql`) — seller concentration (Pareto/decile), freight-to-price and cross-state shipment metrics, installment distribution by order value/category, basket category counts per order and per customer.
- **Python EDA & statistics** (`marketplace_eda.ipynb`) — distance calculation from geolocation coordinates, correlation and outlier analysis on freight vs. distance, hypothesis testing on installment risk by category/region.
- **Dashboard** (`Marketplace_Risk_Dashboard.pbix`) — seller concentration view, freight inefficiency map, installment risk breakdown, cross-sell opportunity view.
- **Business conclusion report** (`Marketplace_Risk_Report.pdf`) — full write-up with recommendations on seller diversification, freight/pricing policy, and merchandising strategy.
