-- ========================================================================
-- Cortex Search Setup for Hotel Contract Documents
-- This script creates Cortex Search services for unstructured document analysis
-- ========================================================================

-- Ensure we're in the right context
USE ROLE Luxury_Hotel_Demo;
USE DATABASE LUXURY_HOTEL_AI_DEMO;
USE SCHEMA HOTEL_SCHEMA;

-- ========================================================================
-- CREATE STAGE FOR CONTRACT DOCUMENTS
-- ========================================================================

-- Create stage for contract documents
CREATE OR REPLACE STAGE HOTEL_CONTRACTS_STAGE
    FILE_FORMAT = (TYPE = 'PDF')
    COMMENT = 'Stage for hotel contract documents for Cortex Search'
    DIRECTORY = (ENABLE = TRUE);

-- ========================================================================
-- UPLOAD INSTRUCTIONS
-- ========================================================================
/*
Before running the Cortex Search creation commands below, upload the PDF files to the stage:

Using SnowSQL or Snowsight:
PUT file:///Users/awasserman/Luxury_Hotel_AI_DEMO/contracts/*.pdf @HOTEL_CONTRACTS_STAGE/contracts/;

Or using Snowsight UI:
1. Navigate to Data → Databases → LUXURY_HOTEL_AI_DEMO → HOTEL_SCHEMA → Stages → HOTEL_CONTRACTS_STAGE
2. Click "Upload Files" 
3. Select all PDF files from the contracts/ directory
4. Upload to the "contracts/" folder within the stage

Verify files are uploaded:
LIST @HOTEL_CONTRACTS_STAGE/contracts/;
*/

-- ========================================================================
-- CREATE CORTEX SEARCH SERVICES
-- ========================================================================

-- Create Cortex Search service for all hotel contracts
CREATE OR REPLACE CORTEX SEARCH SERVICE HOTEL_CONTRACTS_SEARCH
ON file_set_stage_name = 'HOTEL_CONTRACTS_STAGE'
WAREHOUSE = Luxury_Hotel_demo_wh
TARGET_LAG = '1 hour'
COMMENT = 'Cortex Search service for hotel industry contracts and agreements';

-- ========================================================================
-- VERIFY CORTEX SEARCH SETUP
-- ========================================================================

-- Show Cortex Search services
SHOW CORTEX SEARCH SERVICES;

-- Describe the search service
DESCRIBE CORTEX SEARCH SERVICE HOTEL_CONTRACTS_SEARCH;

-- Check service status (should show as READY after indexing completes)
SELECT 
    service_name,
    service_status,
    last_refresh_time,
    definition
FROM TABLE(INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES())
WHERE service_name = 'HOTEL_CONTRACTS_SEARCH';

-- ========================================================================
-- SAMPLE SEARCH QUERIES
-- ========================================================================

-- Once the service is READY, test with these sample queries:

/*
-- Search for payment terms across all contracts
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'payment terms and schedules'
)) 
ORDER BY score DESC
LIMIT 5;

-- Search for cancellation policies
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'cancellation policy and refund terms'
)) 
ORDER BY score DESC
LIMIT 5;

-- Search for venue capacity and room requirements
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'room capacity meeting space venue requirements'
)) 
ORDER BY score DESC
LIMIT 5;

-- Search for food and beverage related terms
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'catering menu food beverage restaurant dining'
)) 
ORDER BY score DESC
LIMIT 5;

-- Search for pricing and rate information
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'rates pricing fees charges costs'
)) 
ORDER BY score DESC
LIMIT 5;

-- Search for employee benefits and compensation
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'employee benefits wages compensation insurance vacation'
)) 
ORDER BY score DESC
LIMIT 5;

-- Search for liability and insurance requirements
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'insurance liability coverage requirements risk management'
)) 
ORDER BY score DESC
LIMIT 5;

-- Search for contract termination clauses
SELECT 
    relative_path,
    chunk,
    score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH(
    'HOTEL_CONTRACTS_SEARCH',
    'termination breach default notice period'
)) 
ORDER BY score DESC
LIMIT 5;
*/

-- ========================================================================
-- ENHANCED SEARCH FUNCTIONS
-- ========================================================================

-- Create a view to make searching easier with meaningful document names
CREATE OR REPLACE VIEW CONTRACT_SEARCH_RESULTS AS
SELECT 
    CASE 
        WHEN relative_path LIKE '%vendor_food_beverage%' THEN 'Food & Beverage Vendor Agreement'
        WHEN relative_path LIKE '%corporate_group_booking%' THEN 'Corporate Group Booking Contract'
        WHEN relative_path LIKE '%employee_union%' THEN 'Employee Union Agreement'
        WHEN relative_path LIKE '%property_management%' THEN 'Property Management Agreement'
        WHEN relative_path LIKE '%guest_wedding%' THEN 'Wedding Venue Contract'
        ELSE relative_path
    END AS document_type,
    relative_path,
    chunk AS content,
    NULL as search_query,
    NULL as score
FROM TABLE(SNOWFLAKE.CORTEX.SEARCH('HOTEL_CONTRACTS_SEARCH', ''))
WHERE FALSE; -- This is a template view, actual searches will override the WHERE clause

-- Create a function to search contracts by category
CREATE OR REPLACE FUNCTION SEARCH_HOTEL_CONTRACTS(search_term STRING)
RETURNS TABLE (
    document_type STRING,
    content STRING,
    relevance_score FLOAT
)
LANGUAGE SQL
AS
$$
    SELECT 
        CASE 
            WHEN relative_path LIKE '%vendor_food_beverage%' THEN 'Food & Beverage Vendor Agreement'
            WHEN relative_path LIKE '%corporate_group_booking%' THEN 'Corporate Group Booking Contract'
            WHEN relative_path LIKE '%employee_union%' THEN 'Employee Union Agreement'
            WHEN relative_path LIKE '%property_management%' THEN 'Property Management Agreement'
            WHEN relative_path LIKE '%guest_wedding%' THEN 'Wedding Venue Contract'
            ELSE relative_path
        END AS document_type,
        chunk AS content,
        score AS relevance_score
    FROM TABLE(SNOWFLAKE.CORTEX.SEARCH('HOTEL_CONTRACTS_SEARCH', search_term))
    ORDER BY score DESC
$$;

-- ========================================================================
-- INTEGRATION WITH INTELLIGENCE AGENT
-- ========================================================================

-- Update the Intelligence Agent to include contract search capabilities
-- (This would be added to the agent specification)

/*
Example agent enhancement to include contract search:

"semantic_objects": [
    {
        "name": "LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.PMS_SEMANTIC_VIEW",
        "description": "Property Management System data..."
    },
    {
        "name": "LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.POS_SEMANTIC_VIEW", 
        "description": "Point of Sale transaction data..."
    },
    {
        "name": "LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.CRM_SEMANTIC_VIEW",
        "description": "Customer Relationship Management data..."
    },
    {
        "name": "LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.HOTEL_CONTRACTS_SEARCH",
        "description": "Hotel contracts and agreements including vendor agreements, group booking contracts, union agreements, property management contracts, and wedding venue contracts. Use for questions about contract terms, pricing, policies, and legal obligations."
    }
]
*/

-- ========================================================================
-- MONITORING AND MAINTENANCE
-- ========================================================================

-- Create a view to monitor search service health
CREATE OR REPLACE VIEW CORTEX_SEARCH_MONITORING AS
SELECT 
    service_name,
    service_status,
    creation_time,
    last_refresh_time,
    DATEDIFF('hour', last_refresh_time, CURRENT_TIMESTAMP()) as hours_since_refresh,
    definition:file_set_stage_name::STRING as stage_name
FROM TABLE(INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES())
WHERE service_name = 'HOTEL_CONTRACTS_SEARCH';

-- ========================================================================
-- NEXT STEPS
-- ========================================================================
/*
1. Upload PDF files to the HOTEL_CONTRACTS_STAGE using the instructions above
2. Wait for the Cortex Search service to index the documents (status = 'READY')
3. Test the sample search queries
4. Integrate with the Intelligence Agent for enhanced contract querying
5. Use the SEARCH_HOTEL_CONTRACTS function for structured searches

Sample questions the enhanced system can answer:
- "What are the payment terms in our vendor agreements?"
- "What cancellation policies apply to group bookings?"  
- "What are the employee benefits outlined in the union contract?"
- "What insurance requirements are specified in our contracts?"
- "What are the venue capacity limits for wedding events?"
*/

-- Show the created objects
SHOW CORTEX SEARCH SERVICES;
SHOW STAGES LIKE 'HOTEL_CONTRACTS_STAGE';
SHOW VIEWS LIKE '%CONTRACT%';
SHOW FUNCTIONS LIKE '%CONTRACT%';
