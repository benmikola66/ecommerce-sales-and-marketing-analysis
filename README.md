# Marketing Analytics Dashboard Project

This project demonstrates an end-to-end marketing analytics workflow using SQL data cleaning, structured data preparation, and final analysis through an Excel dashboard.

[View Dashboard Screenshot](dashboard_two.PNG)

---

## Business Problems Solved

This project addresses core marketing analytics questions that businesses face:

1. **Which channels are driving the most revenue?**  
   Standardized UTM fields and channel taxonomy allow accurate attribution across paid search, paid social, email, and other channels.

2. **How much does it cost to acquire a customer (CAC)?**  
   Cleaned ad spend and customer-level data enables precise CAC calculations by channel.

3. **Which channels deliver the highest ROAS?**  
   Unified ad spend, revenue, and order data makes ROAS comparable across campaigns and channels.

4. **Are marketing dollars being spent efficiently over time?**  
   Monthly spend, revenue, and conversion trends highlight performance swings and budget efficiency.

5. **How do customers behave across the funnel?**  
   Clean session, email event, and order data reveal acquisition paths, engagement signals, and conversion insights.

6. **Is the underlying data trustworthy enough for decision-making?**  
   The SQL cleaning pipeline removes inconsistencies, fixes formatting issues, normalizes categories, and ensures proper data types — creating reliable data for analysis.

---

## Project Overview

The workflow includes:

1. **SQL Data Cleaning**  
   - Cleaned and standardized all staging tables (`stg_*`)  
   - Normalized inconsistent fields (emails, UTM parameters, devices, product names, campaign names)  
   - Converted currency strings to numeric types  
   - Standardized dates and category labels  
   - Checked and resolved duplicate IDs  
   - Created raw snapshots for data lineage  

2. **Data Preparation**  
   - Ensured consistent data types across all tables  
   - Created clean join keys (customer → orders → products → sessions)  
   - Standardized marketing taxonomy (paid social, paid search, email, etc.)  
   - Validated schema with system metadata checks  

3. **Excel Dashboard**  
   Final visuals include:
   - CAC by channel  
   - ROAS by channel  
   - Monthly revenue trends  
   - Spend by channel  
   - Conversion rates  
   - Customer lookup tool  
   - Supporting sheets with email, session, order, and product details  

```

## Skills Demonstrated

- SQL data cleaning & transformation  
- UTM/channel taxonomy standardization  
- Preparing analytic datasets for BI tools  
- Excel dashboard creation  
- Marketing analytics (CAC, ROAS, spend analysis, revenue trends)


