# 💎 MĀLIYAH (مَالِيّة)

### Next-Generation Privacy-First Personal Finance & Wealth Operating System

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-teal?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State Management](https://img.shields.io/badge/State-BLoC%20%2F%20HydratedBloc-blueviolet?style=for-the-badge)](https://bloclibrary.dev)
[![ML Engine](https://img.shields.io/badge/AI%20OCR-Google%20ML%20Kit-orange?style=for-the-badge)](https://developers.google.com/ml-kit)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

---

## 🌟 Overview

**MĀLIYAH** is an ultra-premium, privacy-centric personal finance and asset management app built from the ground up to redefine how modern individuals track, analyze, and scale their financial wealth.

Unlike conventional finance apps that sell user transaction data to third-party brokers, MĀLIYAH operates on a **100% on-device, multi-tenant offline-first philosophy**. Your financial ledger, receipt images, and Khata debts never leave your hardware.

---

## ✨ Key Capabilities

### 🤖 1. On-Device AI Receipt & UPI Screenshot OCR Scanner

- Instant, zero-latency text extraction powered by **Google ML Kit Vision Text Recognition**.
- Smart heuristic extraction engine that automatically detects payment amounts, counterparty/merchant names, transaction categories, and timestamps from UPI payment screenshots (GPay, PhonePe, Paytm) and store invoices.
- Compressed on-device image caching with zero external server dependencies.

### 🤝 2. Debts & Khata Ledger (Lent & Borrowed Tracker)

- Dedicated dual-sided counterparty ledger for personal loans, informal peer-to-peer lending, and borrowed funds.
- Record counterparties, expected return dates, payment status, and settlement histories.
- Real-time impact calculation on total net worth.

### 🔁 3. Intelligent EMI & Recurring Subscriptions Engine

- Automated monthly recurring expense scheduler with configurable day-of-month execution.
- Loan maturity tracker supporting remaining installments, tenure duration, and principal tracking.
- Seamless conversion of monthly transactions into standing automated records.

### 📊 4. Real-Time Budgeting & Health Thresholds

- Dynamic budget limiters categorized across Food, Transit, Utilities, Entertainment, and Shopping.
- Visual threshold indicators that shift color dynamically (Green → Amber → Crimson) based on burn rate.
- Real-time runway calculations indicating remaining monthly allowances and days left.

### 📈 5. Interactive Wealth Analytics

- Multi-period breakdown (Today, This Week, This Month, This Year) powered by **FL Chart**.
- Dynamic expense trend bar charts with normalized Y-axis scaling.
- Donut category distribution with instant percentage allocation breakdown.
- Net savings rate metric to measure financial health over time.

---

## 🏛️ Architecture & Clean Design System

MĀLIYAH is structured following **Domain-Driven Design (DDD)** and **Clean Architecture**:
