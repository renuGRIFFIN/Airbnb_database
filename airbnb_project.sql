-- Create New Database --
CREATE DATABASE IF NOT EXISTS airbnb_db;
---------------------------------------------------------------------------------------------------------------

USE airbnb_db;
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'country' --
CREATE TABLE country (
    country_id VARCHAR(10) PRIMARY KEY,
    country_name VARCHAR(50)
);

-- Insert the values in table --
INSERT INTO country(country_id,country_name)
VALUES ('C1','Netherlands');
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'Room_type' and imported data in table using .csv file --
CREATE TABLE Room_type (
    room_type_id INT(10) PRIMARY KEY,
    room_type_name VARCHAR(100)
);

-- Insert the values in table --
INSERT INTO room_type
VALUES(1,'Private room'),
(2,'Entire home/apt'),
(3,'Hotel room');
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'host' and imported data in table using .csv file --
CREATE TABLE host (
    host_id INT(10) PRIMARY KEY,
    host_name VARCHAR(100)
);
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'review' and imported data in table using .csv file --
CREATE TABLE review (
    review_id VARCHAR(10),
    no_of_reviews INT(10),
    last_review varchar(20),
    reviews_per_month decimal(10,3),
    host_id INT(10),
    PRIMARY KEY (review_id),
    FOREIGN KEY (host_id)
        REFERENCES host (host_id)
        ON DELETE CASCADE
);

-- While importing data, last_review has been taken as string to import it properly
-- So, here we need to convert last_review(string) into last_review(date) format    ---
update review set last_review=str_to_date(replace(last_review,'-','.'),get_format(date,'EUR'));
alter table review modify last_review date;
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'city' --
CREATE TABLE city (
    city_id VARCHAR(10),
    city_name VARCHAR(50),
    country_id VARCHAR(10),
    PRIMARY KEY (city_id),
    FOREIGN KEY (country_id)
        REFERENCES country (country_id)
        ON DELETE CASCADE
);

-- Insert the values in table --
INSERT INTO city(city_id,city_name,country_id)
VALUES('CT1','Amsterdam','C1');
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'neighbourhood' and imported data in table using .csv file --
CREATE TABLE neighbourhood (
    neighbourhood_id VARCHAR(10),
    neighbourhood_name VARCHAR(100),
    city_id VARCHAR(10),
    PRIMARY KEY (neighbourhood_id),
    FOREIGN KEY (city_id)
        REFERENCES city (city_id)
        ON DELETE CASCADE
);
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'location' and imported data in table using .csv file --
CREATE TABLE location (
    lat_long_id VARCHAR(10),
    latitude DECIMAL(10 , 5),
    longitude DECIMAL(10 , 5 ),
    neighbourhood_id VARCHAR(10),
    PRIMARY KEY (lat_long_id),
    FOREIGN KEY (neighbourhood_id)
        REFERENCES neighbourhood (neighbourhood_id)
        ON DELETE CASCADE
);
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'property' and imported data in table using .csv file --
CREATE TABLE property (
    property_id VARCHAR(10),
    property_name VARCHAR(100),
    occupancy INT(10),
    avalibility INT(10),
    price INT(10),
    room_type_id INT(10),
    review_id VARCHAR(10),
    host_id INT(10),
    PRIMARY KEY (property_id),
    FOREIGN KEY (room_type_id)
        REFERENCES room_type (room_type_id)
        ON DELETE CASCADE,
    FOREIGN KEY (review_id)
        REFERENCES review (review_id)
        ON DELETE CASCADE,
    FOREIGN KEY (host_id)
        REFERENCES host (host_id)
        ON DELETE CASCADE
);
---------------------------------------------------------------------------------------------------------------

-- Create new table named 'airbnb' and imported data in table using .csv file --
CREATE TABLE airbnb (
    id INT(10),
    host_id INT(10),
    property_id VARCHAR(10),
    lat_long_id VARCHAR(10),
    PRIMARY KEY (id),
    FOREIGN KEY (host_id)
        REFERENCES host (host_id)
        ON DELETE CASCADE,
    FOREIGN KEY (property_id)
        REFERENCES property (property_id)
        ON DELETE CASCADE,
    FOREIGN KEY (lat_long_id)
        REFERENCES location (lat_long_id)
        ON DELETE CASCADE
);
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

----------------------------------------------- STORED PROCEDURE ------------------------------------------------

-- Cheapest property in given neighbourhood of a particular type of rooms --
delimiter $$
use airbnb_db $$
create procedure p_property_available(in p_neighbourhood_name varchar(100), 
									in p_room_type varchar(100), out p_property_name varchar(100))
begin
select min(p.price),p.property_name into p_property_name
FROM
	room_type r join 
    property p on r.room_type_id=p.room_type_id
        JOIN
    airbnb a ON p.property_id = a.property_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
where n.neighbourhood_name=p_neighbourhood_name and r.room_type_name=p_room_type ;
end$$
delimiter ;

-- calling the procedure --

set @p_property_name = 0;
call airbnb_db.p_property_available('De Baarsjes - Oud-West', 'Private room',@p_property_name);
select @p_property_name;

----------------------------------------------------------------------------------------------------------------

-------------------------------------------------- FUNCTION ----------------------------------------------------

--  Find the no. of available days for a given property_name --

delimiter $$
use airbnb_db $$
create function f_days_available(p_property_name varchar(100)) returns int(10)
deterministic no sql reads sql data
begin
declare v_available_days int;
SELECT 
    avalibility
INTO v_available_days FROM
    property
WHERE
    property_name = p_property_name;
return v_available_days;
end$$
delimiter ;

-- Call the function --
select f_days_available('Urban Oasis~beautiful street in Old South') as days_available;
---------------------------------------------------------------------------------------------------------------

------------------------------------------------------ QUERY---------------------------------------------------

-- 1) No. of properties per neighbourhood???  --
SELECT 
    n.neighbourhood_id, n.neighbourhood_name, COUNT(p.property_id)  no_of_property
FROM
    property p
        JOIN
    airbnb a ON p.property_id = a.property_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_id;
-----------------------------------------------------------------------------------------------------------------

-- 2) Most and least reviewed neighbourhood's property --
(SELECT 
    concat('Most') as reviewed, n.neighbourhood_name, SUM(r.no_of_reviews) no_of_reviews
FROM
    review r
        JOIN
    host h ON r.host_id = h.host_id
        JOIN
    airbnb a ON a.host_id = h.host_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_id
ORDER BY SUM(r.no_of_reviews) DESC
LIMIT 1) UNION (SELECT 
    concat('Least') as reviewed, n.neighbourhood_name, SUM(r.no_of_reviews) no_of_reviews
FROM
    review r
        JOIN
    host h ON r.host_id = h.host_id
        JOIN
    airbnb a ON a.host_id = h.host_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_id
ORDER BY SUM(r.no_of_reviews) ASC
LIMIT 1);
-----------------------------------------------------------------------------------------------------------------

-- 3) Most Popular and least popular neighbourhood for property --
(SELECT 
    concat('Most') as popularity,n.neighbourhood_name,
    AVG(r.no_of_reviews) avg_of_reviews
FROM
    review r
        JOIN
    host h ON r.host_id = h.host_id
        JOIN
    airbnb a ON a.host_id = h.host_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_id 
ORDER BY AVG(r.no_of_reviews) DESC
LIMIT 1) 
UNION
(SELECT 
   concat('Least') as popularity, n.neighbourhood_name,
    AVG(r.no_of_reviews) avg_of_reviews
FROM
    review r
        JOIN
    host h ON r.host_id = h.host_id
        JOIN
    airbnb a ON a.host_id = h.host_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_id
ORDER BY AVG(r.no_of_reviews)
LIMIT 1);

----------------------------------------------------------------------------------------------------------------

-- 4) Most and least available neighbourhood for property --
(SELECT 
     concat('most')  availablity, n.neighbourhood_name, avg(p.avalibility) as availablity_avg
FROM
    property p
        JOIN
    airbnb a ON p.property_id = a.property_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_name
ORDER BY p.avalibility desc
LIMIT 1) UNION (SELECT 
     concat('least')  availablity, n.neighbourhood_name, avg(p.avalibility) as availablity_avg
FROM
    property p
        JOIN
    airbnb a ON p.property_id = a.property_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_name
ORDER BY p.avalibility 
LIMIT 1);

-----------------------------------------------------------------------------------------------------------------

-- 5) Most expensive and cheapest neighbourhood for property --
(SELECT 
     concat('costliest') price  , n.neighbourhood_name, avg(p.price) as avg_price
FROM
    property p
        JOIN
    airbnb a ON p.property_id = a.property_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_name
ORDER BY avg(p.price) desc
LIMIT 1) union (SELECT 
     concat('cheapest') price  , n.neighbourhood_name, avg(p.price) as avg_price
FROM
    property p
        JOIN
    airbnb a ON p.property_id = a.property_id
        JOIN
    location l ON l.lat_long_id = a.lat_long_id
        JOIN
    neighbourhood n ON n.neighbourhood_id = l.neighbourhood_id
GROUP BY n.neighbourhood_name
ORDER BY avg(p.price) 
LIMIT 1);
-----------------------------------------------------------------------------------------------------------------

-- 7) 2021 and 2020 year reviewed properties as per no. of reviews in descending order --
SELECT 
    p.property_name, r.no_of_reviews, r.last_review
FROM
    property p
        JOIN
    review r ON p.review_id = r.review_id
WHERE
    YEAR(r.Last_review) IN ('2021' , '2020')
ORDER BY r.no_of_reviews DESC , r.last_review DESC
; 
-----------------------------------------------------------------------------------------------------------------

-- 8) No. properties available on the basis of room_type --
SELECT 
    COUNT(*)
FROM
    property
GROUP BY Room_type_id;

-----------------------------------------------------------------------------------------------------------------

-- 9) Top 3 host having maximum no. of properties -- 
SELECT 
    h.host_id, COUNT(p.property_id)
FROM
    property p
        JOIN
    host h ON p.host_id = h.host_id
GROUP BY h.host_id
ORDER BY COUNT(p.property_id) DESC
LIMIT 3;
