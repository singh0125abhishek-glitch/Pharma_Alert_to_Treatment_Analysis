____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
1.-- Ques1. a) Top 10 by Alert Volume: Which 10 doctors have the highest total number of alerts generated?
select HCP_ID, count(Lab_Result) as Total_Alert from Alerts
group by HCP_ID order by 2 desc limit 10;
____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
2.-- Ques2. b) Top 10 by Prescription Volume: Which 10 doctors from the alerts universe have written the highest prescription volume in the Sales data?
 
with dist as (select distinct(HCP_ID) as HCP_ID from Alerts a)

select distinct s.HCP_ID, SUM(Prescription_Volume) AS Total_Prescription_vol from Sales s 
join dist d on s.HCP_ID = d.HCP_ID
group by HCP_ID order by 2 desc limit 10;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
3.-- Ques2. a) Identify all doctors from the alerts universe who received positive lab test alerts, indicating that the patient likely
  -- required treatment. Evaluate whether these doctors showed any prescription activity for any drug within 30 days 
 -- following their first positive alert. Among doctors with no prescribing activity during this post-alert window, 
 -- rank the Top 10 HCPs by total positive alert volume.

with first_pos as (select HCP_ID, min(str_to_date(Alert_Date, '%m/%d/%Y')) as first_post from Alerts
where Lab_Result = 'Positive'
group by HCP_ID),

pos_count as (select HCP_ID, COUNT(*) AS pos_alert from Alerts
where Lab_Result = 'Positive'
group by HCP_ID),

rx_window as (select distinct  f.HCP_ID from first_pos f
join Sales s on s.HCP_ID = f.HCP_ID 
where datediff(str_to_date(s.Prescription_Date, '%m/%d/%Y'), f.first_post) >=0
and datediff(str_to_date(s.Prescription_Date, '%m/%d/%Y'), f.first_post) < 30)

select p.HCP_ID, p.pos_alert from pos_count p
where p.HCP_ID not in ( select HCP_ID from rx_window)
order by 2 desc limit 10;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
4. -- Ques2. b) Create a funnel showing HCPs with at least one positive alert, multiple positive alerts, 
 -- and multiple positive alerts but zero prescribing activity within 30 days
 
with first_pos as (select HCP_ID, min(str_to_date(Alert_Date, '%m/%d/%Y')) as first_post from Alerts
where Lab_Result = 'Positive'
group by HCP_ID),

pos_count as (select HCP_ID, COUNT(*) AS pos_alert from Alerts
where Lab_Result = 'Positive'
group by HCP_ID),

rx_window as (select distinct  f.HCP_ID from first_pos f
join Sales s on s.HCP_ID = f.HCP_ID 
where datediff(str_to_date(s.Prescription_Date, '%m/%d/%Y'), f.first_post) >=0
and datediff(str_to_date(s.Prescription_Date, '%m/%d/%Y'), f.first_post) < 30)

select  
(select count(*) from pos_count) as 1st_stage,
(select count(*) from pos_count where pos_alert > 1) as 2nd_stage,
(select count(*) from pos_count p 
where p.pos_alert > 1
and p.HCP_ID not in (select HCP_ID from rx_window)) as 3rd_stage;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
5. -- Ques3. a) Use the Top 10 doctors by total alert volume from Question 1.
--- For these 10 doctors, calculate the share of total prescription volume contributed by:
--  1) Our Drug (DRG001)
--  2) Competitor Drugs (all other drugs)
 
with top_10 as (select HCP_ID, count(*) as total_alert from Alerts
group by HCP_ID order by 2 desc limit 10),

rx_window as (select s.HCP_ID, 
SUM( s.Prescription_Volume) as total_vol,
sum(case when s.Drug_ID = 'DRG001' then s.Prescription_Volume else 0 end) as our_drug,
sum(case when s.Drug_ID <> 'DRG001' then s.Prescription_Volume else 0 end) as cop_drug
from Sales s
where s.HCP_ID in (select HCP_ID from top_10) group by s.HCP_ID)

select t.HCP_ID, coalesce(w.total_vol,0),
round(100.0* coalesce(w.our_drug, 0) / nullif(w.total_vol, 0) , 2) as our_drug_pct,
round(100.0* coalesce(w.cop_drug, 0) / nullif(w.total_vol, 0) , 2) as cop_drug_pct
from top_10 t
left join rx_window w on w.HCP_ID = t.HCP_ID 
ORDER BY t.total_alert desc;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
6. -- Ques3. b)Identify which competitor drug accounts for the highest prescription volume and is capturing 
 --   the largest share among your highest-alerting doctors.
 
WITH top_10 AS (select HCP_ID, count(*) as total_alert from Alerts
group by HCP_ID ORDER BY 2 DESC LIMIT 10)

SELECT s.Drug_Name, s.Drug_ID,  sum( s.Prescription_Volume) as total_vol from Sales s
where s.HCP_ID IN (select HCP_ID from top_10) and s.Drug_ID <> 'DRG001'
group by s.Drug_ID, s.Drug_Name
order by total_vol desc limit 1;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
7. -- Ques4. Using the Affiliation dataset, identify the Top 10 accounts with the highest alert volume based on 
 -- activity generated by their affiliated doctors.
--  For these Top 10 accounts, calculate:
--  1) Total Alert Count
--  2) Our Drug Prescription Count (DRG001)
--  3) Conversion Ratio - defined as the proportion of prescription count relative to alert count
-- Rank the accounts by lowest conversion ratio to identify high-alert accounts with weak prescription conversion.

with total_alert as (select af.Account_id, count(al.Alert_ID) as alert_count from Affliation af
join Alerts al on af.HCP_ID = al.HCP_ID
group by af.Account_id),

total_pre as (select af.Account_ID, count(s.Prescription_ID) as final_pre from Affliation af
join primex.sales s on s.HCP_ID = af.HCP_ID and s.Drug_ID = 'DRG001'
group by af.Account_id),

top_10 as (select Account_ID, alert_count from total_alert
order by 2 desc limit 10)

select t.Account_ID, t.alert_count, coalesce(tp.final_pre,0) as total_our_drug_pre,
round( coalesce ( tp.final_pre,0)*1.0/t.alert_count, 4) as conversion_rate from top_10 t 
left join total_pre tp on tp.Account_ID = t.Account_ID 
order by 4 asc;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
8.-- Ques5. Using the Affiliation dataset, determine the total number of doctors associated with each account. 
 -- Using prescription activity for Our Drug, calculate:
--  1) The number of active prescribers within each account
--  2) Total prescription volume at the account level
-- Finally, rank accounts by the lowest prescriptions-per-active-doctor ratio and identify the Top 10 accounts.
 
with affliated as (select Account_id, count(distinct HCP_ID) as aff_doc from Affliation
group by Account_id),

act as (select af.Account_id, count(distinct s.HCP_ID) as act_doc,
sum(s.Prescription_Volume) as our_drug_vol from Affliation af
join primex.sales s on af.HCP_ID = s.HCP_ID AND s.Drug_ID = 'DRG001'
group by af.Account_id)

select af.Account_ID, af.aff_doc, 
coalesce(a.act_doc,0) as activ, coalesce(a.our_drug_vol,0) as our_drug_pre,
round(coalesce(a.our_drug_vol,0)*1.0/ nullif(a.act_doc,0),2) as pre_pr_act_doc from affliated af 
left join act a on a.Account_ID = af.Account_ID
order by 5 asc  limit 10;


____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
9. -- Ques6. Part A) Basic lift: Define a 90-day before and 90-day after window around each doctor's first positive alert. 
 -- Calculate prescription volume for our drug in each window. Rank Top 10 HCPs by lift % with highest lift being Rank 1?
 
with first_pos as (select HCP_ID, min( str_to_date(Alert_Date, '%m/%d/%Y') ) as first_post from Alerts
where Lab_Result = 'Positive'
group by HCP_ID),

pre_prep as (select fs.HCP_ID, coalesce(sum(ps.Prescription_Volume),0) as pre_pre from first_pos fs
join Sales ps on ps.HCP_ID = fs.HCP_ID and ps.Drug_ID = 'DRG001'
where str_to_date(ps.Prescription_Date,  '%m/%d/%Y') < fs.first_post  and
datediff( fs.first_post, str_to_date(ps.Prescription_Date,  '%m/%d/%Y')) <= 90
group by fs.HCP_ID),
 
post_prep as (select fs.HCP_ID, coalesce(sum(ps.Prescription_Volume),0) as post_pre from first_pos fs
join Sales ps on ps.HCP_ID = fs.HCP_ID and ps.Drug_ID = 'DRG001'
where str_to_date(ps.Prescription_Date,  '%m/%d/%Y') >= fs.first_post and
datediff( str_to_date(ps.Prescription_Date,  '%m/%d/%Y'),fs.first_post) < 90
group by fs.HCP_ID)
 
select pp.HCP_ID, pp.pre_pre, pop.post_pre,
round(100.0*( pop.post_pre-pp.pre_pre)/pp.pre_pre,1) as lift_pct from pre_prep pp
join post_prep pop on pop.HCP_ID = pp.HCP_ID
where pp.pre_pre > 0 order by 4 desc limit 10;

_____________________________________________________________________________________________________________________________________________
_____________________________________________________________________________________________________________________________________________
10. --  Ques6. Part B) Segment the lift: Split all doctors into 3 behavioral bucket as mentioned in the formula table. 
 -- Does the lift look different across the three groups? Which group shows strongest commercial impact?
 
with first_pos as (select HCP_ID, min( str_to_date(Alert_Date, '%m/%d/%Y') ) as first_post from Alerts
where Lab_Result = 'Positive'
group by HCP_ID),

pre_prep as (select fs.HCP_ID, coalesce(sum(ps.Prescription_Volume),0) as pre_pre from first_pos fs
left join Sales ps on ps.HCP_ID = fs.HCP_ID and ps.Drug_ID = 'DRG001'
and str_to_date(ps.Prescription_Date,  '%m/%d/%Y') < fs.first_post  and
datediff( fs.first_post, str_to_date(ps.Prescription_Date,  '%m/%d/%Y')) <= 90
group by fs.HCP_ID),
 
post_prep as (select fs.HCP_ID, coalesce(sum(ps.Prescription_Volume),0) as post_pre from first_pos fs
left join Sales ps on ps.HCP_ID = fs.HCP_ID and ps.Drug_ID = 'DRG001'
and str_to_date(ps.Prescription_Date,  '%m/%d/%Y') >= fs.first_post and
datediff( str_to_date(ps.Prescription_Date,  '%m/%d/%Y'),fs.first_post) < 90
group by fs.HCP_ID),
 
lift as (select pp.HCP_ID, pp.pre_pre, pop.post_pre, 
CASE WHEN pp.pre_pre = 0 THEN NULL ELSE
round(100.0*( pop.post_pre-pp.pre_pre)/pp.pre_pre,1) end as lift_pct from pre_prep pp
join post_prep pop on pop.HCP_ID = pp.HCP_ID),

Segments as (select *, 
 case when pre_pre = 0 and post_pre > 0 then 'New Starter'
      when pre_pre > 0 and lift_pct >= 20 then 'Grower'
      else 'Non-Responders' end as segment from lift)

select segment, count(*) as HCPs, round(avg(lift_pct),1) as avg_lift from Segments
group by segment;


____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________

--  FPRMULA:
-- Lift% : (Post Prescription Volume – Pre Prescription Volume) / (Pre Prescription Volume) * 100
-- New starters: pre=0, post>0
-- Growers: pre>0 and lift% ≥ +20%
-- Non-responders: Everything else
