CREATE OR REPLACE FUNCTION public.get_meterswapdata_idatum()
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
BEGIN

--meter change
--meter swap
with swapcte as(
select id.distnid,id.meternum,id.remarks from tblidatum_consumerswap_pushlog id where id.status=false and id.remarks='consumer swap'
)

, micte as(
select m.distributionnodecode,m.distributionnodeid,_19 as consumer_name,_354 as oldmeternum,s.meternum,s.remarks from etl_midata m 
join swapcte s on s.distnid=m.distributionnodeid
union all
select n.distributionnodecode,n.distributionnodeid,n.distributionnodename,'',s.meternum,s.remarks from etl_nscdata n 
join swapcte s on s.distnid=n.distributionnodeid
union all
select m.distributionnodecode,m.distnid,'','',s.meternum,s.remarks from etl_dtmi m
join swapcte s on s.distnid=m.distnid
)
INSERT INTO public.tblidatum_consumerswap_logs (distnid,distributionnodecode,request,description,type_id)

select m.distributionnodeid,m.distributionnodecode,jsonb_build_object('serialNumber',m.meternum,'consumerId',m.distributionnodecode,'consumername',m.consumer_name,'oldMeterSerialNumber',m.oldmeternum)
,m.remarks,105

from micte m
where not exists(select 1 from tblidatum_consumerswap_logs cp where cp.distnid=m.distributionnodeid and cp.description = m.remarks and cp.status=false)
--join tblidatum_consumerswap_pushlog p on p.distnid=m.distributionnodeid and p.remarks='consumer swap'
--where  not exists (select 1 from tblidatum_consumerswap_logs where distnid=m.distributionnodeid and description='consumer swap')
;


END;
$function$
