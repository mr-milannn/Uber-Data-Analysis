# 🚗 Uber Rides Service Performance Analysis

[**TRY THE LIVE DASHBOARD HERE**](https://app.powerbi.com/view?r=eyJrIjoiZDdmNzNjOGYtZmIwMC00NjI2LTk4ZTUtYzRmMzNkYzRjMzRjIiwidCI6IjdlZTg0MzQ3LWM5MmMtNDFiMi1hYTIyLWNiZDM1NGFiZjcwNSJ9)

This project executes a full business intelligence pipeline to transform raw ride-hailing booking data into an actionable, high-contrast dashboard for executive-level performance monitoring using Power BI.

***

## 📁 Project Directory Layout

The project structure organizes source files, scripts, and documentation:
```
uber-analysis/
├── analysis-dashboard.pbix   
├── README.md                 
├── data/                     
│   └── ncr_bookings_import.csv
├── sql/                      
│   └── create_views.sql
├── resources/                
│   ├── logo.png
│   └── background.png                  
└── Scripts/
    └──Bookings_Cleaning.py
```

***

## 🎯 Project Goals

The analysis provides deep insights into core service challenges:

1.  **Service Reliability:** Analyze and identify drivers behind **customer and driver cancellation rates**.
2.  **Operational Metrics:** Tracking of **Vehicle Turnaround Time (VTAT)** and **Customer Turnaround Time (CTAT)** to pinpoint service bottlenecks.
3.  **Financial Segmentation:** Analysis of **Average Booking Value** and **Revenue Contribution** segmented by vehicle type and payment method.

***

## 🛠️ Technology Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Data Source** | Local CSV (`ncr_bookings_import.csv`) | Raw data containing 150,000+ ride records. |
| **Data Wrangling** | **MySQL** | Core ETL for cleansing, aggregation, and structural transformation. |
| **Data Modeling** | **MySQL Views** & **Power Query** | Creation of efficient **Star Schema** components. |
| **Visualization** | **Power BI** | Building the final interactive executive dashboard with advanced analytics. |

***

## ⚙️ Methodology and Data Preparation

The project pipeline focused on maximizing data quality and report efficiency:

### 1. Complex Data Transformation (SQL)
* **Problem:** The raw timestamp data was non-standard (`DD-MM-YYYY HH:MM:SS`) and contained non-breaking space characters (`\xa0`), causing conversion failures during import.
* **Solution:** Used a complex nested function within the `LOAD DATA INFILE` command: `STR_TO_DATE(REPLACE(TRIM(@timestamp_var), ' ', ' '), '%d-%m-%Y %H:%i:%s')`. This ensured reliable splitting of the single timestamp column into separate `Ride_Date`, `Ride_Time`, and `Ride_Timestamp` fields.
* **Aggregation:** Created two distinct SQL Views: `vw_global_kpis` (for high-level, static performance metrics) and `vw_aggregated_rides` (the main fact table, pre-aggregated by all dimensions for fast query performance).

### 2. Data Modeling (Power BI)
* The model strictly adheres to a **Star Schema** using a central fact table (`vw_aggregated_rides`) connected to small, unique Dimension Tables (`Dim_Location`, `Dim_Payment`, `Dim_Vehicle`) via **One-to-Many ($\mathbf{1} \to \mathbf{*}$) relationships**.

***

## 📊 Dashboard & Advanced Features

The final Power BI dashboard utilizes a **high-contrast, dark theme** for optimal readability and includes specialized interactive features:

### 1. Core Visualizations
* **Global KPI Panel:** Displays six core, unfiltered metrics (e.g., Total Rides, Avg. Value, Success Rate) from the **`vw_global_kpis`** view.
* **Demand Analysis:** Features **Bar Charts** for **Peak Hour** demand and **Stacked Column Charts** for segment analysis by Vehicle Type.
* **Financial Breakdown:** Includes **Waterfall Charts** and **Clustered Bar Charts** to analyze revenue contribution and average booking value by segment.

### 2. Interactive Tooltips (Dynamic Analytics)
The dashboard uses advanced page-level tooltips that activate on hover to provide instant root-cause analysis:

* **Key Influencers Tooltip:** Dynamically identifies the **top factors** (e.g., specific `Pickup_Zone` or `Payment_Method`) that drive outcomes like high cancellation volumes.
* **Decomposition Tree Tooltip:** Allows users to perform an immediate **hierarchical drill-down** of any key measure (like `Total_Rides`) across multiple dimensions defined in the model.

***

## 🤝 Getting Started

To replicate or review this project:

1.  **Database Setup:** Create a MySQL database and execute the necessary SQL scripts to load data into the `rides` table and create the analytical views.
2.  **Load into Power BI:** Connect Power BI to the MySQL database and load the required fact and view tables.
3.  **Build Model:** Replicate the **Star Schema** relationships defined between the Dimension and Fact tables.
