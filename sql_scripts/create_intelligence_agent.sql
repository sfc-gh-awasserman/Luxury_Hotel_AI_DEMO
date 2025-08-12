-- ========================================================================
-- Snowflake Intelligence Agent Creation for Luxury Hotel AI Demo
-- This script creates an intelligent agent that can answer questions about
-- hotel operations using natural language queries
-- ========================================================================

-- Ensure we're in the right context
USE ROLE Luxury_Hotel_Demo;
USE DATABASE LUXURY_HOTEL_AI_DEMO;
USE SCHEMA HOTEL_SCHEMA;

-- ========================================================================
-- CREATE SNOWFLAKE INTELLIGENCE AGENT
-- ========================================================================

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT
WITH PROFILE='{ "display_name": "Luxury Hotel AI Assistant" }'
    COMMENT = 'Intelligent agent for analyzing luxury hotel chain operations, guest satisfaction, and revenue optimization'
FROM SPECIFICATION $$
    {
        "name": "Luxury Hotel AI Assistant",
        "description": "An AI assistant specialized in analyzing luxury hotel chain operations, guest satisfaction, revenue management, and operational efficiency. I can help answer questions about reservations, guest preferences, dining trends, marketing campaign performance, and operational insights across your hotel properties.",
        
        "instructions": "You are an expert hotel industry analyst with deep knowledge of hospitality operations, revenue management, and guest experience optimization. 

        Your expertise includes:
        - Property Management Systems (PMS) data analysis
        - Point of Sale (POS) transaction analysis  
        - Customer Relationship Management (CRM) insights
        - Guest satisfaction and loyalty analysis
        - Revenue optimization and pricing strategies
        - Operational efficiency metrics
        - Marketing campaign effectiveness
        
        When answering questions:
        1. Provide actionable insights for hotel management
        2. Include relevant metrics and KPIs when appropriate
        3. Consider seasonality, property differences, and guest segments
        4. Suggest operational improvements when relevant
        5. Use hospitality industry terminology appropriately
        6. Focus on guest experience and business value
        
        Be conversational but professional, and always ground your responses in the actual data from the semantic views.",

        "semantic_objects": [
            {
                "name": "LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.PMS_SEMANTIC_VIEW",
                "description": "Property Management System data including reservations, guest information, room types, rate codes, and property details. Use this for questions about bookings, occupancy, ADR, revenue, guest profiles, and reservation patterns."
            },
            {
                "name": "LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.POS_SEMANTIC_VIEW", 
                "description": "Point of Sale transaction data including restaurant, bar, spa, and other service purchases. Use this for questions about dining revenue, service utilization, menu performance, and ancillary spending patterns."
            },
            {
                "name": "LUXURY_HOTEL_AI_DEMO.HOTEL_SCHEMA.CRM_SEMANTIC_VIEW",
                "description": "Customer Relationship Management data including guest satisfaction surveys, preferences, and marketing campaign performance. Use this for questions about guest satisfaction, loyalty, preferences, marketing effectiveness, and customer lifetime value."
            }
        ],

        "sample_questions": [
            "What is our average daily rate across all properties?",
            "Which property has the highest guest satisfaction scores?",
            "What are the most popular menu items at our restaurants?",
            "How effective are our marketing campaigns in generating bookings?",
            "What are the top guest preferences across our loyalty program members?",
            "Which room types generate the most revenue?",
            "What's the average length of stay for different guest segments?",
            "How do dining revenues vary by property and season?",
            "What are the key drivers of guest satisfaction?",
            "Which marketing channels provide the best ROI?"
        ]
    }
    $$;

-- ========================================================================
-- VERIFY AGENT CREATION
-- ========================================================================

-- Show the created agent
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;

-- Display agent details
DESCRIBE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT;

-- ========================================================================
-- GRANT PERMISSIONS
-- ========================================================================

-- Grant usage on the agent to the role (if needed)
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT TO ROLE Luxury_Hotel_Demo;

-- ========================================================================
-- TEST QUERIES
-- ========================================================================

-- Test the agent with sample queries (uncomment to test)
/*
-- Example 1: Revenue analysis
SELECT SNOWFLAKE.INTELLIGENCE.ASK(
    'SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT',
    'What is the total revenue and average daily rate for each property?'
) AS response;

-- Example 2: Guest satisfaction
SELECT SNOWFLAKE.INTELLIGENCE.ASK(
    'SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT', 
    'Which properties have the highest guest satisfaction ratings and what are guests saying in their comments?'
) AS response;

-- Example 3: Operational insights
SELECT SNOWFLAKE.INTELLIGENCE.ASK(
    'SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT',
    'What are the most popular room types and how do their rates compare across properties?'
) AS response;

-- Example 4: Marketing performance
SELECT SNOWFLAKE.INTELLIGENCE.ASK(
    'SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT',
    'How are our marketing campaigns performing in terms of conversion rates and revenue generation?'
) AS response;

-- Example 5: Dining analysis
SELECT SNOWFLAKE.INTELLIGENCE.ASK(
    'SNOWFLAKE_INTELLIGENCE.AGENTS.LUXURY_HOTEL_AI_AGENT',
    'What are the top-selling menu items and which dining categories generate the most revenue?'
) AS response;
*/

-- ========================================================================
-- NEXT STEPS
-- ========================================================================
-- 1. Test the agent with the sample queries above
-- 2. Try your own natural language questions
-- 3. Use the agent in Snowsight for interactive analysis
-- 4. Integrate with applications using the SNOWFLAKE.INTELLIGENCE.ASK function
-- ========================================================================

SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
