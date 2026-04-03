# POS Terminal

Works on **Linux | Windows | MacOS**

### Technical Stack
- **Framework:** Compiled and tested using **Qt 6.10**
- **Local Database:** **SQLite3** for data storage

### Key Features
- **Single-user POS terminal** for customer service.
- **Cloud Integration:** Supports data exchange with cloud services for online monitoring.
- **Printing:** Generates non-fiscal receipts and invoices.
- **Document Format:** All printable documents are generated as **.pdf**.
- **Fiscalization:** Includes optional integration with the **CashDesk** service.
- **Ready to Use:** Can be deployed for currency exchange offices out-of-the-box (without fiscalization).

### Retail Requirements
To use this terminal in a retail store environment, the following modules are required:
*   **vkArticle:** Products/items management (adding, naming, monitoring).
*   **vkRater:** Pricing, discounts, and promotions (setup and monitoring).

### Directory Structure
For **Linux** and **Windows**, the working directory structure is:
```text
./
└── app/
    ├── data/
    └── report/
