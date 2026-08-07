____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
1.
select HCP_ID, count(Lab_Result) as Total_Alert from Alerts
group by HCP_ID order by 2 desc limit 10;
____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
2.
with dist as (select distinct(HCP_ID) as HCP_ID from Alerts a)

select distinct HCP_ID, SUM(Prescription_Volume) AS Total_Prescription_vol from Sales s 
join dist d on s.HCP_ID = d.HCP_ID
group by HCP_ID order by 2 desc limit 10;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
3.
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
4.
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
5.
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
6.
WITH top_10 AS (select HCP_ID, count(*) as total_alert from Alerts
group by HCP_ID ORDER BY 2 DESC LIMIT 10)

SELECT s.Drug_Name, s.Drug_ID,  sum( s.Prescription_Volume) as total_vol from Sales s
where s.HCP_ID IN (select HCP_ID from top_10) and s.Drug_ID <> 'DRG001'
group by s.Drug_ID, s.Drug_Name
order by total_vol desc limit 1;

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
7.
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
8.
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
9.
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
10.
with first_pos as (select HCP_ID, min( str_to_date(Alert_Date, '%m/%d/%Y') ) as first_post from Alerts
where Lab_Result = 'Positive'
group by HCP_ID),

pre_prep as (select fs.HCP_ID, coalesce(sum(ps.Prescription_Volume),0) as pre_pre from first_pos fs
join primex.sales ps on ps.HCP_ID = fs.HCP_ID and ps.Drug_ID = 'DRG001'
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

____________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________
