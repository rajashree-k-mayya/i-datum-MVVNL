CREATE OR REPLACE FUNCTION public.get_updatemeter_details_idatum_repush()
 RETURNS TABLE(respid integer, url text, json1 json, codepart integer)
 LANGUAGE plpgsql
AS $function$

BEGIN
	return query
    with missing_dist as (
        select r.responselogid, r.distnid, r.response
        from tblresponselogs r
        where r.projectid = 19 and r.responsestatusid >= 0 and r.activityid not in (-1,81) and r.response is not null
        and r.response <> '' and r.response like '{%'
        and not exists (select 1 from tblidatum_updatemi_logs x where x.distnid = r.distnid and x.status = false and x.type_id = 106)
    )
    , base as (
        select m.distnid,m.responselogid,
        -- safe meter extraction
        case when safe_jsonb(pb.value ->> 'value') is not null then safe_jsonb(pb.value ->> 'value') ->> 'meter_Id'
        else pb.value ->> 'value' end as meter_Id,

        -- safe full value extraction
        coalesce(safe_jsonb(pb.value ->> 'value'),jsonb_build_object('value', pb.value ->> 'value')) as val,

        -- safe cpa
        nullif(pb.value ->> 'categorypropertyallocationid','')::int as cpa_id

        from missing_dist m
        cross join lateral jsonb_array_elements(safe_jsonb(m.response) -> 'propertiesBean') pb(value)
    )
    ,cteamain as(

        select distinct r.responselogid,r.activityid,r.distcode,r.distnid,u.username as meterinstallbyid, concat(u."FirstName",'',u."LastName") meterinstalledby
        , to_timestamp(r.surveydate || ' ' || r.responsetime,'DD/MM/YYYY HH24:MI:SS')::date as installation_date --to_timestamp(s.surveydate || ' ' || s.surveytime,'dd/mm/yyyy hh24:mi:ss')::date
        ,(case when r.nodetype=1 then 'Consumer' when r.nodetype=7 then 'DT' when r.nodetype=6 then 'Feeder' end) as servicecategory ,(case when r.activityid in (72,44,46) then 'MI' when r.activityid in (3) then 'NSC' when r.activityid in (10,11,12) then 'ONM' end) as servicesubcategory
        ,(case when exists(select 1 from tblresurvey s
        join tblresponselogs old on old.responselogid=s.responseid
        where old.distnid=r.distnid and s.resurvey=1 and old.responselogid = (select max(rr.responselogid) from tblresponselogs rr where rr.distnid=r.distnid and rr.responselogid<r.responselogid)
        )then 'Resurvey' else 'Fresh MI' end) as remarks
        from base b
        join tblresponselogs r on r.responselogid=b.responselogid
         join tbl_idatum_crvdetails crv on crv.serialno=b.meter_Id
        left join tblidatum_updatemi_logs um on um.distnid = b.distnid and um.request::jsonb ->> 'serialNumber' = b.meter_Id
        inner join tblusers u on u.userid=r.serveyorid
        where um.request::jsonb ->> 'serialNumber' is null and b.meter_Id <>''
    )--select * from cteamain
    ,
    pivoted  as(
        select c.responselogid,

        max(val ->> 'meter_Id')
            filter (where cpa_id in ('57','908','624','1489','1787','1633'))        as meternum,

        max(val ->> 'value')
            filter (where cpa_id in ('354','530','645','1625','1300','1625','1781','993','984'))       as oldmeternum,

        max(val ->> 'seal_number')
            filter (where cpa_id in ('68','956','952','2021','1640')) as bodyseal1,

        max(val ->> 'seal_number')
            filter (where cpa_id in ('359','958','954','2027','1641')) as bodyseal2,

        max(val ->> 'seal_number')
            filter (where cpa_id in ('70','575','633'))        as boxseal1,

        max(val ->> 'seal_number')
            filter (where cpa_id in ('71','576','634'))        as boxseal2,

        max(val ->> 'seal_number')
            filter (where cpa_id in ('67','568','630'))        as termseal1,

        max(val ->> 'seal_number')
            filter (where cpa_id in ('203','569','631'))       as termseal2,

        max(val ->> 'value')
            filter (where cpa_id in ('941','797','943'))             as cablelength,

        max(val ->> 'value')
            filter (where cpa_id in ('674','650'))             as barcode

        from base c
        group by c.responselogid

    )
    , pivoted_with_sim as (
        select p.*,f.sim_no
        from pivoted p
        left join tblfactoryfiledetails f on f.serial_number = upper(p.meternum)
    ),
     miinsert_cte as(
        insert into public.tblidatum_updatemi_logs (distnid,distributionnodecode,request,description,type_id)
        select m.distnid,distcode,jsonb_build_object('serialNumber',meternum, 'meterStatus','10', 'Stock Status','No', 'meterInstalledById',coalescE(meterinstallbyid,''), 'meterInstalledByName',coalescE(meterinstalledby,''), 'meterInstalledDate',coalescE(installation_date::text,'')
        , 'Id',coalesce(distcode,''), 'oldMeterSerialNumber',coalescE(oldmeternum,barcode,''), 'BodySeal1',coalescE(bodyseal1,''), 'BodySeal2',coalesce(bodyseal2,''), 'BoxSeal1',coalesce(boxseal1,''), 'BoxSeal2',coalesce(boxseal2,''), 'TerminalSeal1',coalesce(termseal1,''), 'TerminalSeal2',coalesce(termseal2,'')
        , 'smcBoxOEMId',(case when mm.mat_subcategory='SMC Box' then mm.smcbox_oemid else 'NA' end), 'smcBoxSAPId',(case when mm.mat_subcategory='SMC Box' then mm.smcbox_sapid else 'NA' end), 'cableLengthConsumed',coalesce(cablelength,''), 'cableSAPId',(case when mm.mat_subcategory='Service Cable' then mm.smcbox_sapid else 'NA' end), 'cableOEMID',(case when mm.mat_subcategory='Service Cable' then mm.smcbox_oemid else 'NA' end), 'newCT','', 'newCTRatio','', 'SIMNo',coalesce(p.sim_no,''), 'serviceCategory',m.servicecategory,'serviceSubCategory',m.servicesubcategory),m.remarks,106
        from pivoted_with_sim p
        join cteamain m on m.responselogid = p.responselogid
        join tbl_idatum_crvdetails crv on crv.serialno=p.meternum
        left join se_material_master m1 on m1.name=crv.materialname and m1.code=crv.materialcode
        left join tblidatum_material_master mm on mm.mat_rid=m1.mm_rid
        where not exists (select 1 from tblidatum_updatemi_logs x where x.distnid = m.distnid and x.status=false)        
        returning id,request
    )--select * from miinsert_cte

	select id,'',request::json,106
	from  miinsert_cte;

END;
$function$
