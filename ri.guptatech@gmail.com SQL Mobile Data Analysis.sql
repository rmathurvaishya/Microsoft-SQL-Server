
-- Case Study 2 -- Mobile Manufacturer Data Analysis
--Queries::

-- Q1 List all the states in which we have customers who have bought cellphones from 2005 till today.

Select L.State  from FACT_TRANSACTIONS T Join DIM_LOCATION L on T.IDLocation= L.IDLocation join DIM_DATE D on T.Date = D.DATE
  Where D.YEAR > 2005
   group by L.State
     

-- Q2 What state in the US is buying more Samsung cell phones?

Select top 1  L.State  from FACT_TRANSACTIONS T Join DIM_LOCATION L on T.IDLocation= L.IDLocation
        join DIM_MODEL Model on  T.IDModel = Model.IDModel
            join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
               Where L.Country = 'US' and  M.Manufacturer_Name = 'Samsung'
	             group by L.State
	                Order by Count(T.IDCustomer ) Desc  

-- Q3 Show the number of transactions for each model per zip code per state


Select  L.ZipCode , L.State,COUNT(T.IDModel) ' No. of transactions'  from FACT_TRANSACTIONS T Join DIM_LOCATION L on T.IDLocation= L.IDLocation
        join DIM_MODEL Model on  T.IDModel = Model.IDModel
            join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
			 Group by L.ZipCode , L.State
			   Order by COUNT(T.IDModel) Desc

			   Select * from FACT_TRANSACTIONS
 
 -- Q4 Show the cheapest cellphone 

 Select  * from DIM_MODEL
   where Unit_price = (select Min(unit_price) from DIM_MODEL)


-- Q5 Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price. 

 Select  Model.Model_Name,AVG(T.TotalPrice)'Average unit price'  from FACT_TRANSACTIONS T 
         Join  DIM_MODEL Model on  T.IDModel = Model.IDModel
            join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
             where M.Manufacturer_Name = ANY(( select top 5 M.Manufacturer_Name  from FACT_TRANSACTIONS T 
                       Join  DIM_MODEL Model on  T.IDModel = Model.IDModel
                         join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
                                group by M.Manufacturer_Name
                                  Order by  COUNT(T.Quantity) desc))
			   group by Model.Model_Name
			     Order by AVG(T.TotalPrice) desc
 

-- Q6 List the names of the customers and the average amount spent in 2009  where the average is higher than 500 

Select C.Customer_Name , AVG(T.totalPrice)'Average spent' from FACT_TRANSACTIONS T 
         join DIM_CUSTOMER C on T.IDCustomer = C.IDCustomer 
            join DIM_DATE D  on T.Date = D.DATE 
              where D.YEAR = 2009
	            group by C.Customer_Name
	              having AVG(T.totalPrice) > 500
	                order by AVG(T.totalPrice) DESC

-- Q7 List if there is any model that was in the top 5 in terms of quantity simultaneously in 2008, 2009 and 2010 

 
SELECT * FROM (
	SELECT TOP 5   Model_Name, SUM (Quantity) AS QTY
    FROM Fact_Transactions T
    LEFT JOIN DIM_Model M ON T.IDModel = M.IDModel
    WHERE YEAR (T.[Date]) ='2008'
    GROUP BY  Model_Name
    ORDER BY  SUM (Quantity) DESC 
    
INTERSECT

SELECT TOP 5   Model_Name, SUM (Quantity) AS QTY
    FROM Fact_Transactions T
    LEFT JOIN DIM_Model M ON T.IDModel = M.IDModel
    WHERE YEAR (T.[Date]) ='2009'
    GROUP BY  Model_Name
    ORDER BY  SUM (Quantity) DESC 
    
INTERSECT

	SELECT TOP 5   Model_Name, SUM (Quantity) AS QTY
    FROM Fact_Transactions T
    LEFT JOIN DIM_Model M ON T.IDModel = M.IDModel
    WHERE YEAR (T.[Date]) ='2010'
    GROUP BY  Model_Name
    ORDER BY  SUM (Quantity) DESC 
	) X;
			 

-- Q8 Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.

select * from
	(Select  M.Manufacturer_Name, SUM(T.TotalPrice)'Total Sales of 2009'   from FACT_TRANSACTIONS T 
         Join  DIM_MODEL Model on  T.IDModel = Model.IDModel
            Join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
			 where YEAR(t.Date) = '2009'
			  group by M.Manufacturer_Name 
			    order by SUM(T.TotalPrice) Desc 
				  	OFFSET 1 ROWS 
                      FETCH NEXT 1 ROWS ONLY) A,

 (Select  M.Manufacturer_Name, SUM(T.TotalPrice)'Total Sales of 2010'   from FACT_TRANSACTIONS T 
         Join  DIM_MODEL Model on  T.IDModel = Model.IDModel
            Join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
			 where YEAR(t.Date) = '2010'
			  group by M.Manufacturer_Name 
			    order by SUM(T.TotalPrice) Desc 
				OFFSET 1 ROWS 
                  FETCH NEXT 1 ROWS ONLY) B

-- Q9 How the manufacturers that sold cellphone in 2010 but didn't in 2009


Select M.Manufacturer_Name from FACT_TRANSACTIONS T 
           Join  DIM_MODEL Model on  T.IDModel = Model.IDModel
            Join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
			  where  YEAR(T.Date) = 2010
			   group by M.Manufacturer_Name

EXCEPT

Select M.Manufacturer_Name from FACT_TRANSACTIONS T 
           Join  DIM_MODEL Model on  T.IDModel = Model.IDModel
            Join DIM_MANUFACTURER M on Model.IDManufacturer = M.IDManufacturer
			  where  YEAR(T.Date) = 2009 
			   group by M.Manufacturer_Name

-- Q10 Find top 100 customers and their average spend average quantity by each year Also find the percentage of change in their spend.
 

SELECT 
    T1.Customer_Name, T1.Year, T2.YEAR , T1.Avg_Price,T1.Avg_Qty,
    CASE
        WHEN T2.Year IS NOT NULL
        THEN  ((T1.Avg_Price-T2.Avg_Price)/(T2.Avg_Price)) *100 ELSE NULL 
        END AS 'Yearly Percentage change'
    FROM
                               (SELECT C.Customer_Name, YEAR(T.DATE) AS YEAR, AVG(T.TotalPrice) AS Avg_Price, 
								  AVG(T.Quantity) AS Avg_Qty FROM FACT_TRANSACTIONS AS T
                                     left join DIM_CUSTOMER as C ON T.IDCustomer=C.IDCustomer
                                  where T.IDCustomer in (select top 100 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
                                  group by C.Customer_Name, YEAR(T.Date)
                                 )T1
    left join
                           (SELECT C.Customer_Name, YEAR(T.DATE) AS YEAR, AVG(T.TotalPrice) AS Avg_Price,
						    AVG(T.Quantity) AS Avg_Qty FROM FACT_TRANSACTIONS AS T 
                                 left join DIM_CUSTOMER as C ON T.IDCustomer=C.IDCustomer
                           where T.IDCustomer in (select top 100 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
                            group by C.Customer_Name, YEAR(T.Date)
                            )T2

        on T1.Customer_Name=T2.Customer_Name and T2.YEAR = T1.YEAR-1
		order by    T1.Customer_Name


/*NOTE : If we performed Inner Join for all of the questions then the null value will be removed only for those values will be shown 
	 where the customer purchased in 2 years simultaneously.
	 For e.g. Customer name like Angella Cetta purchased in 2003,2004,2007 and 2010 also then only 2004 record will be visible due to
	 percentage change for that particular year.
	 */
    