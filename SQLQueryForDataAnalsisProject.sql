create database Internet_Usage_In_Egypt

use Internet_Usage_In_Egypt


create table All_Columns(
record_id int,
user_id int,
age tinyint,
gender varchar(40),
region_name varchar (50),
urban_level float,
is_internet_user int,
isp varchar(50),
connection_type varchar(60),
tariff_name varchar(200),
daily_hours float ,
usage_purpose varchar(80),
monthly_cost_egp int,
download_speed_mbps int,
year int,
Reason_Not_Using_Internet varchar(200),
Age_Group varchar(70)
);

bulk insert All_Columns 
from 'C:\Temp\egypt_internet_usage.csv'
with(
firstrow = 2,
fieldterminator = ',',
rowterminator = '0x0a',
TABLOCK,
Format = 'csv'
)


create table Regions(
 Region_id int primary key not null identity(1,1),
 Region_Name varchar(200),
 Urban_Level float
 );

create table isp(
  isp_id int primary key not null identity(1,1),
  isp_Name varchar(80)
 );

create table Tariffs(
 tariff_id int primary key not null identity(1,1),
 Tariff_Name varchar(200),
 Connection_Type varchar(200),
 speed int,
 Monthly_Cost int,
 isp_id int,
 is_internet_user int

 foreign key (isp_id) references isp(isp_id)
 );

create table Reason(
 Reason_id int primary key identity(1,1),
 Purpose_Usage varchar(100)
 );
create table Reason_Not(
 Reason_Not_id int primary key identity(1,1),
 Reason_Not_using_Internet varchar(100)
 );


create table Users(
User_id int primary key not null,
age tinyint,
gender varchar(40),
year int,
Dailyhours float,
Age_Group varchar(70),
Is_Internet_User int,
Region_id int,
isp_id int, 
reason_id int,
reason_not_id int,
tariff_id int,


 foreign key (Region_id) references Regions(Region_id),
 foreign key (isp_id) references ISP (isp_id),
 foreign key (reason_id) references Reason(reason_id),
 foreign key (reason_not_id) references Reason_Not(reason_not_id),
 foreign key (tariff_id) references Tariffs(tariff_id)

 );





 insert into Users(User_id, age, gender, year, Dailyhours, Age_Group, Users. Is_Internet_User ,Region_id, isp_id, reason_id, reason_not_id, tariff_id)
 select distinct user_id, age, gender,year, daily_hours, Age_Group, Is_Internet_User ,r.Region_id, i.isp_id, re.Reason_id, RN.Reason_Not_id,t.tariff_id 
 from All_Columns a 
 join Regions r on a.region_name = r.Region_Name
 join isp i on a.isp  = i.isp_Name
 join Reason re on a.usage_purpose = re.Purpose_Usage
 join Reason_Not RN on a.Reason_Not_Using_Internet = RN.Reason_Not_using_Internet
 join Tariffs t on a.tariff_name = t.Tariff_Name and i.isp_id = t.isp_id
 

 insert into isp(isp_Name)
 select  distinct isp from All_Columns

 insert into Regions(Region_Name, Urban_Level)
 select distinct region_name, urban_level from All_Columns

 insert into Tariffs (Tariff_Name,Connection_Type, speed, Monthly_Cost, isp_id,is_internet_user)
 select distinct tariff_name, connection_type, download_speed_mbps, monthly_cost_egp, i.isp_id ,is_internet_user from All_Columns a join isp i on i.isp_Name = a.isp

 insert into Reason(Purpose_Usage)
 select distinct usage_purpose from All_Columns

 insert into Reason_Not(Reason_Not_using_Internet)
 select distinct Reason_Not_Using_Internet from All_Columns

alter table Regions
add Internet_speed_in_the_Region float

 update Regions set Internet_Speed_in_the_region = 14 where Region_Name = 'Delta'




-- Q1 How has internet penetration changed over the years?
with Users_Table as 
(select year, count(User_id) as 
Internet_Users 
from Users 
where is_internet_User = 1 
group by year)
,
All_Users_Table as 
(select u.year, count(User_id) 
as All_Users from Users u 
group by u.year)
select ut.year , cast(ut.Internet_Users as float) /aut.All_Users as Internet_Penetration
from Users_Table ut 
join All_Users_Table aut
on ut.year = aut.year 
order by ut.year;

--Q2 Which year experienced the highest growth in internet adoption?
select year , count(User_id) 
as users_Of_This_Year, count(User_id)  - lag(count(User_id)) 
over (order by year) 
as Growth   
from Users
group by year, Is_Internet_User
having Is_Internet_User =1
order by year;

Q3--What is the year-over-year growth rate of internet users?
select year , count(User_id) 
as users_Of_This_Year,round(cast( (count(User_id) - lag(count(User_id)) 
over (order by year)) as float) / lag(count(User_id)) 
over (order by year), 2) 
as Growth  
from Users
where Is_Internet_User =1
group by year, Is_Internet_User;


--Q4 Which age groups have the highest internet adoption rates?
with Total_users_Age_Group as (select Age_Group, count(User_id) as Total from Users group by Age_Group )
select u.Age_Group, cast (count(Is_Internet_User) as float) / t.Total as Internet_Adoption_Rate from Users u join Total_users_Age_Group t on u.Age_Group = t.Age_Group
where Is_Internet_User = 1
group by u.Age_Group, t.Total
order by t.Total DESC

--Q5 Which age groups spend the most time online on average?
select Age_Group, AVG(Dailyhours) as Average_Usage from Users
group by Age_Group 
order by Average_Usage DESC

--Q6 Which regions have the highest and lowest internet penetration? 
with Total_users_Regions as (select Region_Name, count(User_id) as Total from Regions join Users on Users.Region_id = Regions.Region_id group by Region_Name )
select r.Region_Name, cast(count(u.User_id)as float) / Total as Users_Penetration from Regions r join Users u on r.Region_id = u.Region_id join Total_users_Regions t on t.Region_Name = r.Region_Name
where u.Is_Internet_User = 1
group by r.Region_Name, Total

--Q7 How does urbanization level affect internet usage and speed? 
select r.Urban_Level, AVG(u.Dailyhours) as Average_Hours, AVG(r.Internet_Speed_in_the_region) as Average_Speed from Regions r join Users u on r.Region_id = u.Region_id
group by r.Urban_Level;

--Q8 What is the market share of each ISP? 
with total_user as (select count(User_id) as Total_Users from Users)
select i.isp_Name , cast(count(u.User_id) as float)/ Total_Users as Market_Share from isp i join users u on i.isp_id = u.isp_id cross join total_user
where i.isp_Name != 'No is Sim Owner'
group by i.isp_Name, Total_Users
order by Market_Share


--Q9 Which ISP has the highest average revenue per user (ARPU)? 
select i.isp_Name, AVG(t.Monthly_Cost) as Revenue from isp i join Tariffs t on i.isp_id = t.isp_id join Users u on u.isp_id = i.isp_id
where i.isp_Name != 'No is Sim Owner'
group by i.isp_Name
order by Revenue DESC

--Q10 Does higher internet cost correspond to higher speed? 

select Tariff_Name, avg(speed) as Average_Speed , Monthly_Cost, isp_Name from Tariffs  t join isp i on t.isp_id = i.isp_id  
where Tariff_Name != 'None'
group by isp_Name, Tariff_Name, Monthly_Cost
order by Monthly_Cost DESC

--Q11 What are the main reasons for not using the internet, and which groups are most affected?
select r.Reason_Not_using_Internet, u.Age_Group, count(u.User_id) as Affected_Persons from Reason_Not r join Users u on r.Reason_Not_id = u.reason_not_id
where r.Reason_Not_using_Internet != 'is_Internet_User'
group by r.Reason_Not_using_Internet, u.Age_Group
order by Affected_Persons;

--Q12 Which regions or age groups represent the highest potential for future internet growth? 

with Total_Non_users as ( select count(user_id) as Non_Users from users where Is_Internet_User = 0)
select r.Region_Name, u.Age_Group , round(cast(count(u.User_id) as float) / t.Non_Users, 2) as Future_Growth from users u join Regions r on u.Region_id = r.Region_id cross join Total_Non_users t
where u.Is_Internet_User = 0
group by r.Region_Name, u.Age_Group, t.Non_Users
order by Future_Growth DESC;

--Q13 What is the 3-year moving average of internet adoption per region? 
WITH Yearly_Adoption AS (
    SELECT
        r.Region_Name,
        u.year,
        COUNT(u.User_id) AS Internet_Users
    FROM Users u
    JOIN Regions r ON u.Region_id = r.Region_id
    WHERE u.Is_Internet_User = 1
    GROUP BY r.Region_Name, u.year
)
SELECT
    Region_Name,
    year,
    AVG(Internet_Users) OVER (
        PARTITION BY Region_Name
        ORDER BY year
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Three_Year_Moving_Avg
FROM Yearly_Adoption
ORDER BY Region_Name, year;


--Q14 Which regions show consistent growth over time?

SELECT 
r.Region_Name,
u.YEAR ,
COUNT(u.User_id)  
AS total_users_of_internet,
ROUND(CAST((COUNT(u.User_id) 
- 
LAG(COUNT(u.User_id)) 
over 
(PARTITION By r.region_name ORDER BY u.year))AS Float) 
/ 
LAG(COUNT(u.User_id)) OVER
(PARTITION BY r.region_name ORDER BY u.year),2) AS Growth_Rate
FROM users u join Regions r 
ON u.Region_id = r.Region_id 
WHERE Is_Internet_User = 1 
GROUP BY r.Region_Name, u.year;


--Q15 Which ISP shows declining growth despite high market share?
with All_users as (select count(User_id) 
as All_users_Market 
from users 
where Is_Internet_User =1)
,
Market_Share as (select isp_Name, 
round(cast(count(user_id)as float) 
/ All_users_Market,2) 
as Market_Share  
from isp  join users 
on isp.isp_id = users.isp_id 
cross join All_users 
where isp_Name != 'is No Sim Owner' 
and Is_Internet_User = 1 
group by isp_Name, All_users_Market)
,
growth_ISP as (select year , isp_Name, count(User_id) 
as Users_per_ISP from isp i 
join users u on i.isp_id = u.isp_id where isp_Name != 'is No Sim Owner' 
and Is_Internet_User = 1 group by year, isp_Name )
,
GrowthRate as (select ms.isp_Name 
,ms.Market_Share, 
gi.year,
(cast(gi.Users_per_ISP - lag(gi.Users_per_ISP) over(partition by ms.isp_Name order by gi.year)as float))
/ lag(gi.Users_per_ISP) over(partition by ms.isp_Name order by gi.year) as Grwoth_Rate
from All_users au
cross join Market_Share ms
join growth_ISP gi on ms.isp_Name = gi.isp_Name)

select m.isp_Name , 
m.Market_Share, 
g.year, 
g.Grwoth_Rate 
from GrowthRate g 
join Market_Share m 
on g.isp_Name = m.isp_Name  
where m.Market_Share > 0.25 and Grwoth_Rate < 0;

--Q16 Which region is expected to have the highest internet adoption next year?
with users_per_Region as 
(select r.Region_Name, u.year , count(u.User_id) 
as Total_Of_Users from Regions r join Users u 
on r.Region_id = u.Region_id where u.Is_Internet_User = 1 
group by r.Region_Name , u.year)
, 
Growth_Rate as (select Region_Name, year ,
cast(Total_Of_Users - lag(Total_Of_Users) over(partition by region_name order by year)as float) / 
lag(Total_Of_Users) over(partition by region_name order by year) as Growth_User_Rate 
from  users_per_Region
) 
select Region_Name ,avg(Growth_User_Rate)as avg_growth_last_years  from Growth_Rate where year >= 2022
group by Region_Name;


--Q17 Which age group and region combination has the lowest internet adoption rate?

with total as (select u.Age_Group , r.Region_Name , count(u.User_id)
as Total_users 
from Regions r join users u on r.Region_id = u.Region_id 
group by u.Age_Group, r.Region_Name)
,
total_per_GroupRegion as (select u.Age_Group , r.Region_Name , count(u.User_id)
as users_per_Group_Region 
from Regions r join users u on r.Region_id = u.Region_id 
where Is_Internet_User = 1
group by u.Age_Group, r.Region_Name)

select t.Age_Group , t.Region_Name , cast(users_per_Group_Region as float) 
/ Total_users   as Adpation_Rate  from total_per_GroupRegion  tgr join total t on tgr.Age_Group = t.Age_Group 
and tgr.Region_Name = t.Region_Name
order by Adpation_Rate ASC;


--Q18 Which age group shows the biggest gap between internet access and actual usage time?

with Total as (select Age_Group ,count(user_id) as total_users from users group by Age_Group)
select u.Age_Group , round(cast( count (User_id)as float) / total_users , 2) as Penetration_Rate , 
AVG(Dailyhours) as Average_Hours, round(cast( count (User_id)as float) / total_users , 2) - 
AVG(Dailyhours) as Gap  from users u join Total t  on u.Age_Group = t.Age_Group 
where Is_Internet_User = 1
group by u.Age_Group, t.total_users;

--Q19 Which ISP offers the best value (highest speed per pound?
select isp_Name, AVG(cast(Tariffs.speed as float) / Tariffs.Monthly_Cost) 
as Cost_efficiency from isp join tariffs on isp.isp_id = tariffs.isp_id
where Tariff_Name != 'None' and isp_Name != 'No is Sim Owner'
group by isp_Name;

--Q20 Which ISP has the most stable user base over time?
with Total as 
(select isp_name , year ,count(user_id) as total_users from users u join isp i on u.isp_id = i.isp_id 
where Is_Internet_User = 1 group by year, isp_name)
select i.isp_Name , (max(total_users) - min(total_users)) as Variation from isp i join Total t on i.isp_Name = t.isp_Name 
group by i.isp_Name