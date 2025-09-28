USE uber;

CREATE TABLE rides (
    -- Derived Temporal Columns (Handled via transformation during import)
    Ride_Date DATE,
    Ride_Time TIME,

    -- New Temporal/Categorical Columns
    Ride_Timestamp DATETIME,  -- Use DATETIME to store the original timestamp
    Hour_of_Day INT,          -- The hour (0-23)
    Day_of_Week VARCHAR(15),  -- e.g., 'Monday'
    Month_Name VARCHAR(15),   -- e.g., 'January'
    Is_Peak_Hour BOOLEAN,     -- TRUE/FALSE flag

    -- Core Booking Identifiers & Status
    Booking_ID VARCHAR(50),
    Booking_Status VARCHAR(50),
    Customer_ID VARCHAR(50),
    Vehicle_Type VARCHAR(50),
    Payment_Method VARCHAR(50),

    -- Location & Zones
    Pickup_Location TEXT,
    Drop_Location TEXT,
    Pickup_Zone VARCHAR(100), -- New zone columns
    Drop_Zone VARCHAR(100),

    -- Time & Rating Metrics (Matching your original types)
    Avg_VTAT DOUBLE,
    Avg_CTAT DOUBLE,
    Driver_Ratings FLOAT,
    Customer_Rating FLOAT,

    -- Financial & Distance Metrics
    Booking_Value INT,
    Ride_Distance FLOAT,
    Price_Per_KM FLOAT,       -- New derived metric
    Efficiency_Ratio FLOAT,   -- New derived metric

    -- Cancellation & Incomplete Flags & Reasons
    Is_Cancelled_Customer BOOLEAN, -- New flag
    Is_Cancelled_Driver BOOLEAN,   -- New flag
    Trip_Incomplete BOOLEAN,       -- New flag

    -- Legacy/Count Columns (Matching your original types)
    Cancelled_Rides_By_Customer INT,
    Cancelled_Rides_By_Driver INT,
    Incomplete_Rides INT,
    Reason_For_Cancelling_By_Customer TEXT,
    Driver_Cancellation_Reason TEXT,
    Incomplete_Rides_Reason TEXT
);

SET GLOBAL LOCAL_INFILE=1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
LOAD DATA LOCAL INFILE 'D:/Projects/PowerBi Projects/Uber/ncr_bookings_import.csv' INTO TABLE rides
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES; -- USED IN CMD with

select * from rides;
SELECT COUNT(*) FROM rides;
SHOW WARNINGS LIMIT 10;

SELECT
    Payment_Method,
    AVG(Booking_Value) AS Avg_Booking_Value,
    COUNT(Booking_ID) AS Total_Rides
FROM
    rides
GROUP BY
    Payment_Method
ORDER BY
    Avg_Booking_Value DESC;
    
    -- Run this query to update your table
UPDATE rides
SET
    Avg_VTAT = COALESCE(Avg_VTAT, 0),
    Avg_CTAT = COALESCE(Avg_CTAT, 0),
    Driver_Ratings = COALESCE(Driver_Ratings, 0),
    Customer_Rating = COALESCE(Customer_Rating, 0),
    Booking_Value = COALESCE(Booking_Value, 0),
    Ride_Distance = COALESCE(Ride_Distance, 0)
WHERE
    Avg_VTAT IS NULL OR Avg_CTAT IS NULL OR Driver_Ratings IS NULL OR
    Customer_Rating IS NULL OR Booking_Value IS NULL OR Ride_Distance IS NULL;
    
SELECT
    -- Dimensions (Slicers/Axes)
    Ride_Date,                   -- For time series analysis
    Day_of_Week,
    Hour_of_Day,
    Month_Name,
    Vehicle_Type,
    Payment_Method,
    Pickup_Zone,
    Drop_Zone,

    -- Measures (Values)
    COUNT(Booking_ID) AS Total_Rides,
    SUM(Booking_Value) AS Total_Booking_Value,
    AVG(Customer_Rating) AS Avg_Customer_Rating,
    AVG(Driver_Ratings) AS Avg_Driver_Rating,
    SUM(Cancelled_Rides_By_Customer) AS Total_Customer_Cancellations,
    SUM(Cancelled_Rides_By_Driver) AS Total_Driver_Cancellations,
    SUM(CASE WHEN Is_Peak_Hour = 1 THEN 1 ELSE 0 END) AS Peak_Hour_Rides
FROM
    rides
GROUP BY
    Ride_Date, Day_of_Week, Hour_of_Day, Month_Name, Vehicle_Type, Payment_Method, Pickup_Zone, Drop_Zone
ORDER BY
    Ride_Date, Hour_of_Day;
    
SELECT
    -- --- [ Existing KPIs for reference ] ---
    SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) AS Total_Completed_Rides,
    (SUM(Cancelled_Rides_By_Customer) * 1.0 / COUNT(Booking_ID)) AS Customer_Cancellation_Rate,
    (SUM(Cancelled_Rides_By_Driver) * 1.0 / COUNT(Booking_ID)) AS Driver_Cancellation_Rate,
    AVG(Booking_Value) AS Average_Booking_Value,
    AVG(Ride_Distance) AS Average_Ride_Distance,
    AVG(Avg_VTAT) AS Avg_Vehicle_Turnaround_Time,
    AVG(Avg_CTAT) AS Avg_Customer_Turnaround_Time,

    -- --- [ NEW KPIs ] ---

    -- 1. Incomplete Trip Rate (Service Reliability)
    -- Measures trips that were neither cancelled nor completed (e.g., system failure, mid-ride drop)
    (SUM(Incomplete_Rides) * 1.0 / COUNT(Booking_ID)) AS Incomplete_Ride_Rate,
    
    -- 2. Average Price Efficiency (Financial KPI)
    -- Measures the average price charged per kilometer driven.
    AVG(Price_Per_KM) AS Avg_Price_Per_Kilometer,

    -- 3. Vehicle Efficiency Ratio (Operational Efficiency)
    -- Measures how effectively the vehicle was utilized (e.g., time waiting vs. time moving)
    AVG(Efficiency_Ratio) AS Avg_Efficiency_Ratio,

    -- 4. Successful Ride Percentage (Service Quality)
    -- The opposite of the total cancellation rate (Customer + Driver cancellations + Incomplete)
    (1.0 - (SUM(Cancelled_Rides_By_Customer + Cancelled_Rides_By_Driver + Incomplete_Rides) * 1.0 / COUNT(Booking_ID))) AS Successful_Ride_Percentage,
    
    -- 5. Total Unsuccessful Rides (Volume of Issues)
    -- A simple count of all rides that resulted in a problem.
    SUM(Cancelled_Rides_By_Customer + Cancelled_Rides_By_Driver + Incomplete_Rides) AS Total_Unsuccessful_Rides,
    
    -- 6. Average Final Rating (Overall Quality)
    -- The average of both customer and driver ratings.
    (AVG(Customer_Rating) + AVG(Driver_Ratings)) / 2 AS Average_Final_Rating

FROM
    rides;
SELECT
    Vehicle_Type,
    COUNT(Booking_ID) AS Total_Rides,
    AVG(Booking_Value) AS Average_Booking_Value,
    AVG(Customer_Rating) AS Average_Customer_Rating,
    (SUM(Cancelled_Rides_By_Customer + Cancelled_Rides_By_Driver) * 1.0 / COUNT(Booking_ID)) AS Total_Cancellation_Rate
FROM
    rides
GROUP BY
    Vehicle_Type
ORDER BY
    Total_Rides DESC;
CREATE VIEW vw_Global_KPIs AS
SELECT
    -- Total Volumes
    COUNT(Booking_ID) AS Total_Rides,
    SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) AS Total_Completed_Rides,

    -- Cancellation & Incomplete Rates (Operational Reliability)
    (SUM(Cancelled_Rides_By_Customer) * 1.0 / COUNT(Booking_ID)) AS Customer_Cancellation_Rate,
    (SUM(Cancelled_Rides_By_Driver) * 1.0 / COUNT(Booking_ID)) AS Driver_Cancellation_Rate,
    (SUM(Incomplete_Rides) * 1.0 / COUNT(Booking_ID)) AS Incomplete_Ride_Rate,
    (1.0 - (SUM(Cancelled_Rides_By_Customer + Cancelled_Rides_By_Driver + Incomplete_Rides) * 1.0 / COUNT(Booking_ID))) AS Successful_Ride_Percentage,
    
    -- Financial Metrics
    AVG(Booking_Value) AS Average_Booking_Value,
    SUM(Booking_Value) AS Total_Revenue,
    AVG(Price_Per_KM) AS Avg_Price_Per_Kilometer,

    -- Quality & Efficiency
    AVG(Avg_VTAT) AS Avg_Vehicle_Turnaround_Time,
    AVG(Avg_CTAT) AS Avg_Customer_Turnaround_Time,
    AVG(Efficiency_Ratio) AS Avg_Efficiency_Ratio,
    AVG(Customer_Rating) AS Avg_Customer_Rating,
    (AVG(Customer_Rating) + AVG(Driver_Ratings)) / 2 AS Average_Final_Rating

FROM
    rides;
    
    CREATE VIEW vw_Fact_Rides_Aggregated AS
SELECT
    -- Dimensions (The grouping columns for slicers/axes)
    Ride_Date,
    Day_of_Week,
    Hour_of_Day,
    Month_Name,
    Vehicle_Type,
    Payment_Method,
    Pickup_Zone,
    Drop_Zone,

    -- Measures (The aggregated values)
    COUNT(Booking_ID) AS Total_Rides,
    SUM(Booking_Value) AS Total_Booking_Value,
    AVG(Booking_Value) AS Average_Booking_Value,
    
    AVG(Ride_Distance) AS Average_Ride_Distance,
    SUM(Ride_Distance) AS Total_Distance,

    AVG(Customer_Rating) AS Avg_Customer_Rating,
    AVG(Driver_Ratings) AS Avg_Driver_Rating,
    
    SUM(Cancelled_Rides_By_Customer) AS Total_Customer_Cancellations,
    SUM(Cancelled_Rides_By_Driver) AS Total_Driver_Cancellations,
    SUM(Incomplete_Rides) AS Total_Incomplete_Rides,

    SUM(CASE WHEN Is_Peak_Hour = 1 THEN 1 ELSE 0 END) AS Peak_Hour_Rides,
    AVG(Avg_VTAT) AS Avg_VTAT_Value,
    AVG(Avg_CTAT) AS Avg_CTAT_Value

FROM
    rides
GROUP BY
    Ride_Date, Day_of_Week, Hour_of_Day, Month_Name, Vehicle_Type, Payment_Method, Pickup_Zone, Drop_Zone
ORDER BY
    Ride_Date, Hour_of_Day;