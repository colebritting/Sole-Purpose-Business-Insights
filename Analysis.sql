--Creating my table

CREATE TABLE sole_purpose (
	
	product VARCHAR(50),
	purchase_price DECIMAL(10,2),
	purchase_date DATE,
	site_purcahsed VARCHAR(25),
	sale_price DECIMAL(10,2),
	sale_date DATE,
	sold_through VARCHAR(20),
	profit DECIMAL(10,2)
	
);

--Copying data in

COPY sole_purpose 
FROM 'C:\Users\Owner\Downloads\Job Portfolio\Sneaker Project'
DELIMITER ','
CSV HEADER;

--Making sure everything copied correctly and getting a look at the dataset

SELECT * FROM sole_purpose
LIMIT 5;

--Checking revenue and profits by different selling platform (ACH being direct to consumer)

SELECT sold_through, SUM(sale_price), SUM(profit) FROM sole_purpose
GROUP BY sold_through;

--Noticed there was a mistake in the data, one column had ACh instead of ACH

SELECT * FROM sole_purpose
WHERE sold_through = 'ACh';

--Updating column to correct value

UPDATE sole_purpose
SET sold_through = 'ACH'
WHERE sold_through = 'ACh';

--Double checking to make sure the change was done correctly

SELECT sold_through, SUM(sale_price), SUM(profit) FROM sole_purpose
GROUP BY sold_through;

--Checking % of profit and how many sales with each medium

SELECT sold_through, COUNT(*), (SUM(profit)/SUM(sale_price)) as profit_percent FROM sole_purpose
GROUP BY sold_through;

--Checking all values after April, noticing more formatting issues (somes dates are 2023, instead of 2022)

SELECT * FROM sole_purpose
WHERE sale_date > '2022-05-01'
ORDER BY sale_date DESC;

--Found 8 values formatted wrong

SELECT * FROM sole_purpose
WHERE sale_date > '2023-01-01'
ORDER BY sale_date DESC;

--Update all of the 2023 values to 2022

UPDATE sole_purpose SET sale_date = sale_date + 
MAKE_INTERVAL(YEARS := 2022 - EXTRACT(YEAR FROM sale_date)::INTEGER);
	
--Checking to make sure data has been fixed, it has	
	
SELECT * FROM sole_purpose
WHERE sale_date > '2023-01-01'
ORDER BY sale_date DESC;

--Deleteing all non eBay or ACH values (only 2)

DELETE FROM sole_purpose
WHERE sold_through = 'GOAT' OR sold_through = 'StockX';

--Checking all deals by medium sold after May

SELECT sold_through, COUNT(*) FROM sole_purpose
WHERE sale_date > '2022-05-01'
GROUP BY sold_through;

--Checking the above with a % of total added - After May ACH has around 60% of sales and eBay has around 40%

SELECT sold_through, COUNT(*), count(*) * 100.0 / SUM(count(*)) OVER () AS percentage 
FROM sole_purpose
WHERE sale_date > '2022-05-01'
GROUP BY sold_through;

--Same as before - Here ACH has around 35% while eBay has around 65%

SELECT sold_through, COUNT(*), count(*) * 100.0 / SUM(count(*)) OVER () AS percentage 
FROM sole_purpose
WHERE sale_date < '2022-05-01'
GROUP BY sold_through;

--Creating views for before and after may with our key metrics

CREATE VIEW before_may as
SELECT sold_through, COUNT(*) as before_count, 
(SUM(profit)/SUM(purchase_price))*100 as before_profit_percent, SUM(profit) as before_profit
FROM sole_purpose
WHERE sale_date < '2022-05-01'
GROUP BY sold_through;

CREATE VIEW after_may as
SELECT sold_through, COUNT(*) as after_count, 
(SUM(profit)/SUM(purchase_price))*100 as after_profit_percent, SUM(profit) as after_profit
FROM sole_purpose
WHERE sale_date > '2022-05-01'
GROUP BY sold_through;

--Joining the two views together so we can see the difference easier. Making a view of it

CREATE VIEW profit_count AS
SELECT before_may.sold_through, before_count,
after_count, before_profit_percent, after_profit_percent, 
before_profit, after_profit 
FROM before_may
JOIN after_may 
ON before_may.sold_through = after_may.sold_through

--Looking at the change in % of sales through the two mediums before and after May

SELECT sold_through, (before_count*100/SUM(before_count) OVER ()), 
(after_count*100/SUM(after_count) OVER ()) FROM profit_count;

--Looking at how profit margin changed for each category, and it increased in both (eBay more)
--This tells us that the products we sold were more profitable in our second timeframe.
--We are looking to see if our total profit margin will increase because we are selling more products through one medium.
--This is telling us that we are going to see some increase outside of that, simply because
--the products we sold were more profitable across the board. So we need to calculate for that (next query)

SELECT sold_through,
(after_profit_percent - before_profit_percent) as percent_difference
FROM profit_count;

--We are weighing the above increase in product profitability respective to how much they will increase our total profitability.
--This shows us our total profit margin will increase by about 2.7% (both categories added).
--The rest of our increase will come because we made a conscious effort to sell more DTC (direct to consumer).

SELECT SUM(increase) FROM (SELECT sold_through, 
((after_profit*100/SUM(after_profit) OVER ()) * 
(after_profit_percent - before_profit_percent))/100 as increase
FROM profit_count) as m;

--Finding our total profit margin difference over our two timeframes

SELECT (SELECT (SUM(profit)/SUM(purchase_price))*100 
FROM sole_purpose
WHERE sale_date > '2022-05-01')
-
(SELECT (SUM(profit)/SUM(purchase_price))*100 
FROM sole_purpose
WHERE sale_date < '2022-05-01') 

--Subtracting out the 2.7% increase in product profitability increase

SELECT (SELECT (SUM(profit)/SUM(purchase_price))*100 
FROM sole_purpose
WHERE sale_date > '2022-05-01')
-
(SELECT (SUM(profit)/SUM(purchase_price))*100 
FROM sole_purpose
WHERE sale_date < '2022-05-01')
-
(SELECT SUM(increase) FROM (SELECT sold_through, 
((after_profit*100/SUM(after_profit) OVER ()) * 
(after_profit_percent - before_profit_percent))/100 as increase
FROM profit_count) as m);

--My business change - making an effort to sell more DTC instead of over platforms -
-- led to a 3.26% direct increase in profit margin.


















