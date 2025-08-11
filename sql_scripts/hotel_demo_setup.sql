-- ========================================================================
-- Luxury Hotel Chain AI Demo - Complete Setup Script
-- This script creates the database, schema, tables, and loads all hotel data
-- Simplified demo focusing on PMS, POS, and CRM data sources
-- ========================================================================

-- Switch to accountadmin role to create warehouse
USE ROLE accountadmin;

-- Grant permissions for Snowflake Intelligence
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

-- Create role for the hotel demo
CREATE OR REPLACE ROLE Luxury_Hotel_Demo;

SET current_user_name = CURRENT_USER();

-- Grant the role to current user
GRANT ROLE Luxury_Hotel_Demo TO USER IDENTIFIER($current_user_name);
GRANT CREATE DATABASE ON ACCOUNT TO ROLE Luxury_Hotel_Demo;

-- Create a dedicated warehouse for the demo with auto-suspend/resume
CREATE OR REPLACE WAREHOUSE Luxury_Hotel_demo_wh 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant usage on warehouse to demo role
GRANT USAGE ON WAREHOUSE Luxury_Hotel_demo_wh TO ROLE Luxury_Hotel_Demo;

-- Set user defaults
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = Luxury_Hotel_Demo;
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = Luxury_Hotel_demo_wh;

-- Switch to demo role
USE ROLE Luxury_Hotel_Demo;

-- Create database and schema
CREATE OR REPLACE DATABASE LUXURY_HOTEL_AI_DEMO;
USE DATABASE LUXURY_HOTEL_AI_DEMO;

CREATE SCHEMA IF NOT EXISTS HOTEL_SCHEMA;
USE SCHEMA HOTEL_SCHEMA;

-- Create file format for CSV files
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a');

-- Switch to accountadmin for API integration
USE ROLE accountadmin;

-- Create API Integration for GitHub (you'll need to update this with your repo)
CREATE OR REPLACE API INTEGRATION hotel_git_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/')
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION hotel_git_api_integration TO ROLE Luxury_Hotel_Demo;

-- Switch back to demo role
USE ROLE Luxury_Hotel_Demo;

-- Create internal stage for data files
CREATE OR REPLACE STAGE HOTEL_DATA_STAGE
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Internal stage for hotel demo data files'
    DIRECTORY = ( ENABLE = TRUE)
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE');

-- ========================================================================
-- DIMENSION TABLES
-- ========================================================================

-- Property Dimension (Hotels in the chain)
CREATE OR REPLACE TABLE property_dim (
    property_key INT PRIMARY KEY,
    property_name VARCHAR(200) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(10),
    country VARCHAR(50),
    property_type VARCHAR(50),
    room_count INT,
    star_rating INT
);

-- Room Type Dimension
CREATE OR REPLACE TABLE room_type_dim (
    room_type_key INT PRIMARY KEY,
    room_type_name VARCHAR(100) NOT NULL,
    base_rate DECIMAL(10,2),
    max_occupancy INT,
    amenities VARCHAR(500)
);

-- Guest Dimension
CREATE OR REPLACE TABLE guest_dim (
    guest_key INT PRIMARY KEY,
    guest_first_name VARCHAR(100),
    guest_last_name VARCHAR(100),
    email VARCHAR(200),
    phone VARCHAR(50),
    loyalty_tier VARCHAR(50),
    join_date DATE,
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(10),
    country VARCHAR(50),
    date_of_birth DATE
);

-- Rate Code Dimension
CREATE OR REPLACE TABLE rate_code_dim (
    rate_code_key INT PRIMARY KEY,
    rate_code VARCHAR(20) NOT NULL,
    rate_description VARCHAR(200),
    discount_percent DECIMAL(5,2)
);

-- Service Category Dimension
CREATE OR REPLACE TABLE service_category_dim (
    service_category_key INT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    department VARCHAR(100)
);

-- Menu Item Dimension
CREATE OR REPLACE TABLE menu_item_dim (
    menu_item_key INT PRIMARY KEY,
    item_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10,2),
    service_category_key INT,
    description VARCHAR(500)
);

-- Campaign Dimension
CREATE OR REPLACE TABLE campaign_dim (
    campaign_key INT PRIMARY KEY,
    campaign_name VARCHAR(200) NOT NULL,
    campaign_type VARCHAR(100),
    start_date DATE,
    end_date DATE,
    target_segment VARCHAR(100)
);

-- ========================================================================
-- FACT TABLES
-- ========================================================================

-- Reservations Fact Table (PMS Data)
CREATE OR REPLACE TABLE reservations_fact (
    reservation_id INT PRIMARY KEY,
    guest_key INT NOT NULL,
    property_key INT NOT NULL,
    room_type_key INT NOT NULL,
    rate_code_key INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    nights_stayed INT NOT NULL,
    room_rate DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    booking_date DATE,
    booking_channel VARCHAR(100),
    confirmation_status VARCHAR(50)
);

-- POS Transactions Fact Table (Point of Sale Data)
CREATE OR REPLACE TABLE pos_transactions_fact (
    transaction_id INT PRIMARY KEY,
    reservation_id INT,
    guest_key INT,
    property_key INT NOT NULL,
    menu_item_key INT NOT NULL,
    service_category_key INT NOT NULL,
    transaction_date DATE NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50),
    server_id INT
);

-- Guest Preferences Fact Table (CRM Data)
CREATE OR REPLACE TABLE guest_preferences_fact (
    preference_id INT PRIMARY KEY,
    guest_key INT NOT NULL,
    property_key INT NOT NULL,
    preference_type VARCHAR(100),
    preference_value VARCHAR(200),
    created_date DATE,
    last_updated DATE
);

-- Marketing Campaigns Fact Table (CRM Data)
CREATE OR REPLACE TABLE marketing_campaigns_fact (
    campaign_fact_id INT PRIMARY KEY,
    campaign_key INT NOT NULL,
    guest_key INT NOT NULL,
    property_key INT NOT NULL,
    contact_date DATE,
    response_date DATE,
    response_type VARCHAR(100),
    booking_generated INT,
    revenue_generated DECIMAL(12,2),
    channel VARCHAR(100)
);

-- Guest Satisfaction Fact Table (CRM Data)
CREATE OR REPLACE TABLE guest_satisfaction_fact (
    satisfaction_id INT PRIMARY KEY,
    reservation_id INT NOT NULL,
    guest_key INT NOT NULL,
    property_key INT NOT NULL,
    survey_date DATE,
    overall_rating INT,
    service_rating INT,
    room_rating INT,
    dining_rating INT,
    value_rating INT,
    recommend_likelihood INT,
    comments VARCHAR(1000)
);

-- ========================================================================
-- LOAD DATA FROM INTERNAL STAGE (Manual Upload Required)
-- ========================================================================
-- Note: You'll need to upload the CSV files to the stage manually
-- Then uncomment and run these COPY INTO statements

/*
-- Load Dimension Data
COPY INTO property_dim FROM @HOTEL_DATA_STAGE/property_dim.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO room_type_dim FROM @HOTEL_DATA_STAGE/room_type_dim.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO guest_dim FROM @HOTEL_DATA_STAGE/guest_dim.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO rate_code_dim FROM @HOTEL_DATA_STAGE/rate_code_dim.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO service_category_dim FROM @HOTEL_DATA_STAGE/service_category_dim.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO menu_item_dim FROM @HOTEL_DATA_STAGE/menu_item_dim.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO campaign_dim FROM @HOTEL_DATA_STAGE/campaign_dim.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';

-- Load Fact Data
COPY INTO reservations_fact FROM @HOTEL_DATA_STAGE/reservations_fact.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO pos_transactions_fact FROM @HOTEL_DATA_STAGE/pos_transactions_fact.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO guest_preferences_fact FROM @HOTEL_DATA_STAGE/guest_preferences_fact.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO marketing_campaigns_fact FROM @HOTEL_DATA_STAGE/marketing_campaigns_fact.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO guest_satisfaction_fact FROM @HOTEL_DATA_STAGE/guest_satisfaction_fact.csv FILE_FORMAT = CSV_FORMAT ON_ERROR = 'CONTINUE';
*/

-- ========================================================================
-- SEMANTIC VIEWS FOR CORTEX ANALYST
-- ========================================================================

-- PMS (Property Management System) Semantic View
CREATE OR REPLACE SEMANTIC VIEW LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.PMS_SEMANTIC_VIEW
    TABLES (
        RESERVATIONS as RESERVATIONS_FACT primary key (RESERVATION_ID) with synonyms=('bookings','reservations','stays') comment='Hotel reservations and booking data',
        GUESTS as GUEST_DIM primary key (GUEST_KEY) with synonyms=('customers','guests','travelers') comment='Guest profile information',
        PROPERTIES as PROPERTY_DIM primary key (PROPERTY_KEY) with synonyms=('hotels','properties','locations') comment='Hotel properties in the chain',
        ROOM_TYPES as ROOM_TYPE_DIM primary key (ROOM_TYPE_KEY) with synonyms=('rooms','room categories') comment='Different room types and rates',
        RATE_CODES as RATE_CODE_DIM primary key (RATE_CODE_KEY) with synonyms=('rates','pricing','discounts') comment='Rate codes and pricing structures'
    )
    RELATIONSHIPS (
        RESERVATIONS_TO_GUESTS as RESERVATIONS(GUEST_KEY) references GUESTS(GUEST_KEY),
        RESERVATIONS_TO_PROPERTIES as RESERVATIONS(PROPERTY_KEY) references PROPERTIES(PROPERTY_KEY),
        RESERVATIONS_TO_ROOM_TYPES as RESERVATIONS(ROOM_TYPE_KEY) references ROOM_TYPES(ROOM_TYPE_KEY),
        RESERVATIONS_TO_RATES as RESERVATIONS(RATE_CODE_KEY) references RATE_CODES(RATE_CODE_KEY)
    )
    FACTS (
        RESERVATIONS.RESERVATION_AMOUNT as total_amount comment='Total reservation amount in dollars',
        RESERVATIONS.NIGHTS_STAYED as nights_stayed comment='Number of nights stayed',
        RESERVATIONS.ROOM_RATE as room_rate comment='Nightly room rate',
        RESERVATIONS.RESERVATION_RECORD as 1 comment='Count of reservations'
    )
    DIMENSIONS (
        RESERVATIONS.CHECK_IN_DATE as check_in_date with synonyms=('arrival date','start date') comment='Guest check-in date',
        RESERVATIONS.CHECK_OUT_DATE as check_out_date with synonyms=('departure date','end date') comment='Guest check-out date',
        RESERVATIONS.BOOKING_DATE as booking_date with synonyms=('reservation date') comment='Date reservation was made',
        RESERVATIONS.BOOKING_CHANNEL as booking_channel with synonyms=('channel','source') comment='How reservation was booked',
        GUESTS.GUEST_FIRST_NAME as guest_first_name with synonyms=('first name') comment='Guest first name',
        GUESTS.GUEST_LAST_NAME as guest_last_name with synonyms=('last name') comment='Guest last name',
        GUESTS.LOYALTY_TIER as loyalty_tier with synonyms=('loyalty level','membership tier') comment='Guest loyalty program tier',
        PROPERTIES.PROPERTY_NAME as property_name with synonyms=('hotel name','property') comment='Name of the hotel property',
        PROPERTIES.CITY as city comment='Hotel city location',
        PROPERTIES.STATE as state comment='Hotel state location',
        ROOM_TYPES.ROOM_TYPE_NAME as room_type with synonyms=('room category') comment='Type of room booked',
        RATE_CODES.RATE_CODE as rate_code comment='Rate code used for booking',
        RATE_CODES.RATE_DESCRIPTION as rate_description comment='Description of the rate code'
    )
    METRICS (
        RESERVATIONS.TOTAL_REVENUE as SUM(reservations.total_amount) comment='Total revenue from reservations',
        RESERVATIONS.AVERAGE_DAILY_RATE as AVG(reservations.room_rate) comment='Average daily room rate (ADR)',
        RESERVATIONS.TOTAL_NIGHTS as SUM(reservations.nights_stayed) comment='Total nights booked',
        RESERVATIONS.TOTAL_RESERVATIONS as COUNT(reservations.reservation_record) comment='Total number of reservations',
        RESERVATIONS.AVERAGE_LENGTH_OF_STAY as AVG(reservations.nights_stayed) comment='Average length of stay'
    )
    COMMENT='Semantic view for Property Management System (PMS) data analysis';

-- POS (Point of Sale) Semantic View
CREATE OR REPLACE SEMANTIC VIEW LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.POS_SEMANTIC_VIEW
    TABLES (
        TRANSACTIONS as POS_TRANSACTIONS_FACT primary key (TRANSACTION_ID) with synonyms=('sales','purchases','orders') comment='Point of sale transaction data',
        MENU_ITEMS as MENU_ITEM_DIM primary key (MENU_ITEM_KEY) with synonyms=('products','items','offerings') comment='Menu items and services offered',
        SERVICE_CATEGORIES as SERVICE_CATEGORY_DIM primary key (SERVICE_CATEGORY_KEY) with synonyms=('departments','categories') comment='Service categories and departments',
        GUESTS as GUEST_DIM primary key (GUEST_KEY) with synonyms=('customers','guests') comment='Guest information for transactions',
        PROPERTIES as PROPERTY_DIM primary key (PROPERTY_KEY) with synonyms=('hotels','locations') comment='Hotel properties'
    )
    RELATIONSHIPS (
        TRANSACTIONS_TO_MENU_ITEMS as TRANSACTIONS(MENU_ITEM_KEY) references MENU_ITEMS(MENU_ITEM_KEY),
        TRANSACTIONS_TO_SERVICE_CATEGORIES as TRANSACTIONS(SERVICE_CATEGORY_KEY) references SERVICE_CATEGORIES(SERVICE_CATEGORY_KEY),
        TRANSACTIONS_TO_GUESTS as TRANSACTIONS(GUEST_KEY) references GUESTS(GUEST_KEY),
        TRANSACTIONS_TO_PROPERTIES as TRANSACTIONS(PROPERTY_KEY) references PROPERTIES(PROPERTY_KEY)
    )
    FACTS (
        TRANSACTIONS.TRANSACTION_AMOUNT as total_amount comment='Transaction amount in dollars',
        TRANSACTIONS.QUANTITY as quantity comment='Quantity of items purchased',
        TRANSACTIONS.UNIT_PRICE as unit_price comment='Unit price of item',
        TRANSACTIONS.TRANSACTION_RECORD as 1 comment='Count of transactions'
    )
    DIMENSIONS (
        TRANSACTIONS.TRANSACTION_DATE as transaction_date with synonyms=('sale date','purchase date') comment='Date of transaction',
        TRANSACTIONS.PAYMENT_METHOD as payment_method comment='Method of payment used',
        MENU_ITEMS.ITEM_NAME as item_name with synonyms=('product name','service name') comment='Name of item or service',
        MENU_ITEMS.CATEGORY as item_category comment='Category of menu item',
        SERVICE_CATEGORIES.CATEGORY_NAME as service_category with synonyms=('department') comment='Service category or department',
        SERVICE_CATEGORIES.DEPARTMENT as department comment='Operating department',
        GUESTS.GUEST_FIRST_NAME as guest_first_name with synonyms=('first name') comment='Guest first name',
        GUESTS.GUEST_LAST_NAME as guest_last_name with synonyms=('last name','customer name') comment='Guest last name',
        PROPERTIES.PROPERTY_NAME as property_name with synonyms=('hotel name') comment='Hotel property name'
    )
    METRICS (
        TRANSACTIONS.TOTAL_REVENUE as SUM(transactions.total_amount) comment='Total revenue from all transactions',
        TRANSACTIONS.AVERAGE_TRANSACTION as AVG(transactions.total_amount) comment='Average transaction amount',
        TRANSACTIONS.TOTAL_TRANSACTIONS as COUNT(transactions.transaction_record) comment='Total number of transactions',
        TRANSACTIONS.TOTAL_QUANTITY as SUM(transactions.quantity) comment='Total quantity of items sold'
    )
    COMMENT='Semantic view for Point of Sale (POS) system data analysis';

-- CRM (Customer Relationship Management) Semantic View
CREATE OR REPLACE SEMANTIC VIEW LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.CRM_SEMANTIC_VIEW
    TABLES (
        CAMPAIGNS as MARKETING_CAMPAIGNS_FACT primary key (CAMPAIGN_FACT_ID) with synonyms=('marketing','promotions') comment='Marketing campaign performance data',
        CAMPAIGN_DETAILS as CAMPAIGN_DIM primary key (CAMPAIGN_KEY) with synonyms=('campaign info') comment='Campaign details and descriptions',
        SATISFACTION as GUEST_SATISFACTION_FACT primary key (SATISFACTION_ID) with synonyms=('reviews','feedback','surveys') comment='Guest satisfaction and survey data',
        PREFERENCES as GUEST_PREFERENCES_FACT primary key (PREFERENCE_ID) with synonyms=('guest preferences','customer preferences') comment='Guest preferences and special requests',
        GUESTS as GUEST_DIM primary key (GUEST_KEY) with synonyms=('customers','guests') comment='Guest profile information',
        PROPERTIES as PROPERTY_DIM primary key (PROPERTY_KEY) with synonyms=('hotels','properties') comment='Hotel properties'
    )
    RELATIONSHIPS (
        CAMPAIGNS_TO_DETAILS as CAMPAIGNS(CAMPAIGN_KEY) references CAMPAIGN_DETAILS(CAMPAIGN_KEY),
        CAMPAIGNS_TO_GUESTS as CAMPAIGNS(GUEST_KEY) references GUESTS(GUEST_KEY),
        CAMPAIGNS_TO_PROPERTIES as CAMPAIGNS(PROPERTY_KEY) references PROPERTIES(PROPERTY_KEY),
        SATISFACTION_TO_GUESTS as SATISFACTION(GUEST_KEY) references GUESTS(GUEST_KEY),
        SATISFACTION_TO_PROPERTIES as SATISFACTION(PROPERTY_KEY) references PROPERTIES(PROPERTY_KEY),
        PREFERENCES_TO_GUESTS as PREFERENCES(GUEST_KEY) references GUESTS(GUEST_KEY),
        PREFERENCES_TO_PROPERTIES as PREFERENCES(PROPERTY_KEY) references PROPERTIES(PROPERTY_KEY)
    )
    FACTS (
        CAMPAIGNS.REVENUE_GENERATED as revenue_generated comment='Revenue generated from campaign',
        CAMPAIGNS.BOOKING_GENERATED as booking_generated comment='Whether campaign generated a booking',
        CAMPAIGNS.CAMPAIGN_RECORD as 1 comment='Count of campaign interactions',
        SATISFACTION.OVERALL_RATING as overall_rating comment='Overall satisfaction rating (1-5)',
        SATISFACTION.SERVICE_RATING as service_rating comment='Service quality rating (1-5)',
        SATISFACTION.ROOM_RATING as room_rating comment='Room quality rating (1-5)',
        SATISFACTION.DINING_RATING as dining_rating comment='Dining experience rating (1-5)',
        SATISFACTION.VALUE_RATING as value_rating comment='Value for money rating (1-5)',
        SATISFACTION.RECOMMEND_LIKELIHOOD as recommend_likelihood comment='Likelihood to recommend (1-10)',
        SATISFACTION.SATISFACTION_RECORD as 1 comment='Count of satisfaction surveys',
        PREFERENCES.PREFERENCE_RECORD as 1 comment='Count of guest preferences'
    )
    DIMENSIONS (
        CAMPAIGNS.CONTACT_DATE as contact_date comment='Date guest was contacted',
        CAMPAIGNS.RESPONSE_DATE as response_date comment='Date guest responded',
        CAMPAIGNS.RESPONSE_TYPE as response_type comment='Type of response from guest',
        CAMPAIGNS.CHANNEL as marketing_channel comment='Marketing channel used',
        CAMPAIGN_DETAILS.CAMPAIGN_NAME as campaign_name comment='Name of marketing campaign',
        CAMPAIGN_DETAILS.CAMPAIGN_TYPE as campaign_type comment='Type of marketing campaign',
        CAMPAIGN_DETAILS.TARGET_SEGMENT as target_segment comment='Target customer segment',
        SATISFACTION.SURVEY_DATE as survey_date comment='Date satisfaction survey was completed',
        SATISFACTION.COMMENTS as comments comment='Guest comments and feedback',
        PREFERENCES.PREFERENCE_TYPE as preference_type comment='Type of guest preference',
        PREFERENCES.PREFERENCE_VALUE as preference_value comment='Specific preference details',
        GUESTS.GUEST_FIRST_NAME as guest_first_name with synonyms=('first name') comment='Guest first name',
        GUESTS.GUEST_LAST_NAME as guest_last_name with synonyms=('last name','customer name') comment='Guest last name',
        GUESTS.LOYALTY_TIER as loyalty_tier comment='Guest loyalty program tier',
        PROPERTIES.PROPERTY_NAME as property_name comment='Hotel property name'
    )
    METRICS (
        CAMPAIGNS.TOTAL_CAMPAIGN_REVENUE as SUM(campaigns.revenue_generated) comment='Total revenue from marketing campaigns',
        CAMPAIGNS.CAMPAIGN_CONVERSION_RATE as AVG(campaigns.booking_generated) comment='Campaign conversion rate',
        CAMPAIGNS.TOTAL_CAMPAIGNS as COUNT(campaigns.campaign_record) comment='Total number of campaign interactions',
        SATISFACTION.AVERAGE_OVERALL_RATING as AVG(satisfaction.overall_rating) comment='Average overall satisfaction rating',
        SATISFACTION.AVERAGE_SERVICE_RATING as AVG(satisfaction.service_rating) comment='Average service rating',
        SATISFACTION.AVERAGE_ROOM_RATING as AVG(satisfaction.room_rating) comment='Average room rating',
        SATISFACTION.AVERAGE_DINING_RATING as AVG(satisfaction.dining_rating) comment='Average dining rating',
        SATISFACTION.AVERAGE_VALUE_RATING as AVG(satisfaction.value_rating) comment='Average value rating',
        SATISFACTION.AVERAGE_RECOMMEND_LIKELIHOOD as AVG(satisfaction.recommend_likelihood) comment='Average likelihood to recommend',
        SATISFACTION.TOTAL_SURVEYS as COUNT(satisfaction.satisfaction_record) comment='Total number of satisfaction surveys'
    )
    COMMENT='Semantic view for Customer Relationship Management (CRM) data analysis';

-- ========================================================================
-- VERIFICATION
-- ========================================================================

-- Show all tables
SHOW TABLES IN SCHEMA HOTEL_SCHEMA;

-- Show semantic views
SHOW SEMANTIC VIEWS;

-- Verify table structures
SELECT 'DIMENSION TABLES' as category, '' as table_name, NULL as row_count
UNION ALL
SELECT '', 'property_dim', COUNT(*) FROM property_dim
UNION ALL
SELECT '', 'room_type_dim', COUNT(*) FROM room_type_dim
UNION ALL
SELECT '', 'guest_dim', COUNT(*) FROM guest_dim
UNION ALL
SELECT '', 'rate_code_dim', COUNT(*) FROM rate_code_dim
UNION ALL
SELECT '', 'service_category_dim', COUNT(*) FROM service_category_dim
UNION ALL
SELECT '', 'menu_item_dim', COUNT(*) FROM menu_item_dim
UNION ALL
SELECT '', 'campaign_dim', COUNT(*) FROM campaign_dim
UNION ALL
SELECT '', '', NULL
UNION ALL
SELECT 'FACT TABLES', '', NULL
UNION ALL
SELECT '', 'reservations_fact', COUNT(*) FROM reservations_fact
UNION ALL
SELECT '', 'pos_transactions_fact', COUNT(*) FROM pos_transactions_fact
UNION ALL
SELECT '', 'guest_preferences_fact', COUNT(*) FROM guest_preferences_fact
UNION ALL
SELECT '', 'marketing_campaigns_fact', COUNT(*) FROM marketing_campaigns_fact
UNION ALL
SELECT '', 'guest_satisfaction_fact', COUNT(*) FROM guest_satisfaction_fact;

-- ========================================================================
-- NEXT STEPS
-- ========================================================================
-- 1. Upload CSV files to @HOTEL_DATA_STAGE
-- 2. Uncomment and run the COPY INTO statements above
-- 3. Create Cortex Search services for unstructured documents
-- 4. Create Snowflake Intelligence Agent with the three semantic views
-- ========================================================================
