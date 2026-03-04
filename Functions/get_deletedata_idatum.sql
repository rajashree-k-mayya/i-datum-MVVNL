CREATE OR REPLACE FUNCTION public.get_deletedata_idatum()
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
BEGIN
with swapcte as(
select id.swapid as pushlog_id,id.distnid,id.meternum,id.remarks from tblidatum_consumerswap_pushlog id where id.status=false and id.remarks='delete'
)
, micte as(

select s.pushlog_id,r.distnid,r.distcode,(case when value like '{%' then value::jsonb->>'meter_Id' else value end) as meternum,s.remarks
from tblresponselogs r
join swapcte s on s.distnid=r.distnid
cross join lateral jsonb_to_recordset(response::jsonb -> 'propertiesBean') as items( value text,categorypropertyallocationid int)
where  r.projectid=999 and r.responsestatusid>=0 and items.categorypropertyallocationid in (57,908,624,1489,1633,1787)

)--select * from micte

INSERT INTO public.tblidatum_consumerswap_logs (distnid,distributionnodecode,request,description,type_id,pushlog_id)

select m.distnid,m.distcode,jsonb_build_object('serialNumber',m.meternum,'miDeleteFlag',true)
,m.remarks,108,m.pushlog_id

from micte m 
where not exists(select 1 from tblidatum_consumerswap_logs where request::jsonb->>'serialNumber'=m.meternum and distnid=m.distnid and description='delete' and status='false')
ON CONFLICT (pushlog_id) DO NOTHING;

END;
$function$
