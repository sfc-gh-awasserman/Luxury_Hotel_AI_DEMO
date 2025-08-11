# Luxury Hotel Chain AI Demo - Setup Guide

## Quick Start

This simplified Snowflake Intelligence demo is designed specifically for a luxury hotel chain and focuses on three core data sources:
- **PMS (Property Management System)** - Reservations and guest data
- **POS (Point of Sale)** - Restaurant, bar, spa, and service transactions  
- **CRM (Customer Relationship Management)** - Guest satisfaction, preferences, and marketing

## What's Included

### 📊 Data Files (12 CSV files)
**Dimension Tables:**
- `property_dim.csv` - 8 luxury hotel properties
- `room_type_dim.csv` - 8 room types from Standard to Presidential Suite
- `guest_dim.csv` - 10 guest profiles with loyalty tiers
- `rate_code_dim.csv` - 10 rate codes and discount structures
- `service_category_dim.csv` - 12 service categories across departments
- `menu_item_dim.csv` - 18 menu items and service offerings
- `campaign_dim.csv` - 10 marketing campaigns

**Fact Tables:**
- `reservations_fact.csv` - 15 hotel reservations (PMS data)
- `pos_transactions_fact.csv` - 20 point of sale transactions (POS data)
- `guest_preferences_fact.csv` - 15 guest preferences (CRM data)
- `marketing_campaigns_fact.csv` - 15 campaign interactions (CRM data)
- `guest_satisfaction_fact.csv` - 15 satisfaction surveys (CRM data)

### 🗄️ SQL Setup Script
- `hotel_demo_setup.sql` - Complete database setup with 3 semantic views

### 📚 Documentation
- `README.md` - Comprehensive demo overview
- `SETUP_GUIDE.md` - This setup guide
- Hotel operations documents for Cortex Search

## Step-by-Step Setup

### 1. Create Database and Tables
```sql
-- Run the complete setup script in Snowflake
-- File: /sql_scripts/hotel_demo_setup.sql
```

This creates:
- `LUXURY_HOTEL_AI_DEMO` database
- `HOTEL_SCHEMA` schema  
- All dimension and fact tables
- Three semantic views (PMS, POS, CRM)
- Internal stage for data loading

### 2. Upload Data Files
1. In Snowflake, navigate to Data > Databases > LUXURY_HOTEL_AI_DEMO > HOTEL_SCHEMA
2. Click on Stages > HOTEL_DATA_STAGE
3. Upload all 12 CSV files from the `/demo_data/` folder
4. Uncomment and run the COPY INTO statements in the setup script

### 3. Verify Data Load
```sql
-- Check table row counts
SELECT 'property_dim' as table_name, COUNT(*) as rows FROM property_dim
UNION ALL
SELECT 'reservations_fact', COUNT(*) FROM reservations_fact
-- ... etc for all tables
```

Expected row counts:
- Dimension tables: 7-18 rows each
- Fact tables: 15-20 rows each

### 4. Create Cortex Search Services (Optional)
```sql
-- Example for hotel operations documents
CREATE CORTEX SEARCH SERVICE hotel_operations_search
    ON content
    ATTRIBUTES file_path, title
    WAREHOUSE = Luxury_Hotel_demo_wh
    TARGET_LAG = '30 day'
    AS (
        SELECT file_path, title, content 
        FROM parsed_hotel_documents
    );
```

### 5. Configure Snowflake Intelligence Agent
Create an agent with access to the three semantic views:
- `PMS_SEMANTIC_VIEW` - Property management and reservations
- `POS_SEMANTIC_VIEW` - Point of sale transactions  
- `CRM_SEMANTIC_VIEW` - Customer relationship management

## Sample Questions to Test

### PMS Questions
- "What is our revenue by property for 2025?"
- "Which room types generate the highest revenue?"
- "Show me booking trends by month"

### POS Questions  
- "What is our restaurant revenue across all properties?"
- "Which spa services are most popular?"
- "Show me F&B revenue trends"

### CRM Questions
- "What are our guest satisfaction scores by property?"
- "Which marketing campaigns generated the most bookings?"
- "Show me loyalty program performance"

### Cross-Domain Questions
- "Calculate total revenue per guest including room and services"
- "Show me the complete guest journey from booking to checkout"
- "Which properties have the best guest satisfaction and revenue?"

## Key Hotel Industry Metrics

The demo calculates standard hospitality KPIs:
- **ADR (Average Daily Rate)** - Average room revenue per occupied room
- **RevPAR (Revenue per Available Room)** - Total room revenue ÷ available rooms
- **Occupancy Rate** - Percentage of rooms occupied
- **Total Revenue per Guest** - Room + F&B + other services
- **Guest Satisfaction Score** - Average ratings across touchpoints

## Troubleshooting

### Common Issues
1. **File Upload Errors**: Ensure CSV files are properly formatted and uploaded to correct stage
2. **Permission Errors**: Verify role has necessary permissions for database and warehouse
3. **Semantic View Errors**: Check that all referenced tables exist and contain data

### Verification Queries
```sql
-- Check semantic views exist
SHOW SEMANTIC VIEWS;

-- Test semantic view access
SELECT * FROM PMS_SEMANTIC_VIEW LIMIT 5;

-- Verify stage contents  
LIST @HOTEL_DATA_STAGE;
```

## Next Steps After Setup

1. **Test Basic Queries** - Verify each semantic view returns data
2. **Create Cortex Search** - Upload and index hotel policy documents  
3. **Configure Agent** - Set up Snowflake Intelligence Agent with all tools
4. **Run Demo Scenarios** - Test with sample questions from different domains
5. **Customize Data** - Modify sample data to match your specific hotel requirements

## Support and Customization

This demo provides a foundation that can be extended:
- Add more properties to the chain
- Include additional service categories
- Expand guest preference tracking
- Add more sophisticated marketing attribution
- Include operational metrics (staff productivity, energy usage, etc.)

The simplified three-source approach makes it easy to understand data relationships while demonstrating powerful cross-domain analytics capabilities.

---

*For questions or customization assistance, refer to the main README.md file for detailed architecture information.*
