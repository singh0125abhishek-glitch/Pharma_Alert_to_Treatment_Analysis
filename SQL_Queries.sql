

select HCP_ID, count(Lab_Result) as Total_Alert from primex.alerts
group by HCP_ID order by 2 desc limit 10
