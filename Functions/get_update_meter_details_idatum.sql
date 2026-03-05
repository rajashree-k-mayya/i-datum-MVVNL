CREATE OR REPLACE FUNCTION public.get_update_meter_details_idatum(responselogid integer, userid integer, projectid integer, activityid integer)
 RETURNS TABLE(respid integer, url text, json1 json, codepart integer)
 LANGUAGE plpgsql
AS $function$

BEGIN
    if $4 in (72,3,44,46,11,12,10) then
        return query
            with props as(
                select  r.responselogid,(pb.value ->> 'categorypropertyallocationid') as cpa_id,
                case when pb.value ->> 'value' like '{%' then (pb.value ->> 'value')::jsonb
                else jsonb_build_object('value', pb.value ->> 'value')
                end as val
                from tblresponselogs r
                inner join tblusers u on u.userid=r.serveyorid
                cross join lateral jsonb_array_elements(r.response ::jsonb -> 'propertiesBean') pb(value)
                where r.responselogid=$1 and r.projectid=$3 and r.activityid=$4 and r.responsestatusid>=0
            ),
            pivoted  as(
            SELECT
                c.responselogid,

                MAX(val ->> 'meter_Id')
                    FILTER (WHERE cpa_id IN ('57','908','624','1489','1787','1633'))        AS meternum,

                MAX(val ->> 'value')
                    FILTER (WHERE cpa_id IN ('354','530','645','1625','1300','1625','1781','993','984'))       AS oldmeternum,

                MAX(val ->> 'seal_number')
                    FILTER (WHERE cpa_id IN ('68','956','952','2021','1640')) AS bodyseal1,

                MAX(val ->> 'seal_number')
                    FILTER (WHERE cpa_id IN ('359','958','954','2027','1641')) AS bodyseal2,

                MAX(val ->> 'seal_number')
                    FILTER (WHERE cpa_id IN ('70','575','633'))        AS boxseal1,

                MAX(val ->> 'seal_number')
                    FILTER (WHERE cpa_id IN ('71','576','634'))        AS boxseal2,

                MAX(val ->> 'seal_number')
                    FILTER (WHERE cpa_id IN ('67','568','630'))        AS termseal1,

                MAX(val ->> 'seal_number')
                    FILTER (WHERE cpa_id IN ('203','569','631'))       AS termseal2,

                MAX(val ->> 'value')
                    FILTER (WHERE cpa_id IN ('941','797','943'))             AS cablelength,

                MAX(val ->> 'value')
                    FILTER (WHERE cpa_id IN ('674','650'))             AS barcode

            FROM props c
			GROUP BY c.responselogid

            )
			, pivoted_with_sim AS (
			SELECT
			p.*,
			f.sim_no
			FROM pivoted p
			LEFT JOIN tblfactoryfiledetails f
			ON f.serial_number = UPPER(p.meternum)
			),

            cteamain as(
            select distinct r.responselogid,distcode,r.distnid,u.username as meterinstallbyid, concat(u."FirstName",'',u."LastName") meterinstalledby
            , to_timestamp(r.surveydate || ' ' || r.responsetime,'DD/MM/YYYY HH24:MI:SS')::date AS installation_date --to_timestamp(s.surveydate || ' ' || s.surveytime,'DD/MM/YYYY HH24:MI:SS')::date
            ,(case when r.nodetype=1 then 'Consumer' when r.nodetype=7 then 'DT' when r.nodetype=6 then 'Feeder' end) as servicecategory ,(case when r.activityid in (72,44,46) then 'MI' when r.activityid in (3) then 'NSC' when r.activityid in (10,11,12) then 'ONM' end) as servicesubcategory
            ,(case when exists(select 1 from tblresurvey s
            join tblresponselogs old on old.responselogid=s.responseid
            where old.distnid=r.distnid and s.resurvey=1 and old.responselogid = (select max(rr.responselogid) from tblresponselogs rr where rr.distnid=r.distnid and rr.responselogid<r.responselogid)
            )then 'Resurvey' else 'Fresh MI' end) as remarks
            from tblresponselogs r
			--left join tblsurveydetaails s on s.responselogid=r.responselogid
			inner join tblusers u on u.userid=r.serveyorid
            where r.responselogid=$1 and r.projectid=$3 and r.activityid=$4 and r.responsestatusid>=0
            )
            , miinsert_cte as(
            INSERT INTO public.tblidatum_updatemi_logs (distnid,distributionnodecode,request,description,type_id,push_datetime)
            select  distinct m.distnid,distcode,jsonb_build_object('serialNumber',meternum, 'meterStatus','10', 'Stock Status','No', 'meterInstalledById',coalescE(meterinstallbyid,''), 'meterInstalledByName',coalescE(meterinstalledby,''), 'meterInstalledDate',coalescE(installation_date::text,'')
            , 'Id',coalesce(distcode,''), 'oldMeterSerialNumber',coalescE(oldmeternum,barcode,''), 'BodySeal1',coalescE(bodyseal1,''), 'BodySeal2',coalesce(bodyseal2,''), 'BoxSeal1',coalesce(boxseal1,''), 'BoxSeal2',coalesce(boxseal2,''), 'TerminalSeal1',coalesce(termseal1,''), 'TerminalSeal2',coalesce(termseal2,'')
            , 'smcBoxOEMId',(case when mm.mat_subcategory='SMC Box' then mm.smcbox_oemid else 'NA' end), 'smcBoxSAPId',(case when mm.mat_subcategory='SMC Box' then mm.smcbox_sapid else 'NA' end), 'cableLengthConsumed',coalesce(cablelength,''), 'cableSAPId',(case when mm.mat_subcategory='Service Cable' then mm.smcbox_sapid else 'NA' end), 'cableOEMID',(case when mm.mat_subcategory='Service Cable' then mm.smcbox_oemid else 'NA' end), 'newCT','', 'newCTRatio','', 'SIMNo',coalesce(p.sim_no,''), 'serviceCategory',m.servicecategory,'serviceSubCategory',m.servicesubcategory),m.remarks,106,now()
			FROM pivoted_with_sim p
			JOIN cteamain m ON m.responselogid = p.responselogid
          left  join tbl_idatum_crvdetails crv on crv.serialno=p.meternum
            left join se_material_master m1 on m1.name=crv.materialname and m1.code=crv.materialcode
            left join tblidatum_material_master mm on mm.mat_rid=m1.mm_rid
			WHERE NOT EXISTS (SELECT 1 FROM tblidatum_updatemi_logs x WHERE x.distnid = m.distnid and x.status=false) and meternum is not null           
			returning id,request)

            select id,'',request::json,106
            from  miinsert_cte;

    end if;
END;
$function$
