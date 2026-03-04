CREATE OR REPLACE FUNCTION public.get_newmaterial_idatum(uom character varying, matcat character varying, matsubcat character varying, matname character varying, matcode character varying, mat_description character varying, sap_vendorcode character varying, sap_oemname character varying, deliverynoteunit character varying, unitdesc character varying, serialised character varying, hsncode character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 

DECLARE 
uomu_grid int4;mcrid int4;mscrid int4;serial_flag int4;ug_rid_new int4;uom_rid_new int4;matrid int4;

BEGIN

insert into assignmentpreelogs(fntext,created) select 'get_newmaterial_idatum'|| $1::text||'/'||$2::text||'/'||$3::text||'/'||$4::text||'/'||$5::text||'/'||$6::text||'/'||$7::text||'/'||$8::text||'/'||$9::text||'/'||$10::text||'/'||$11::text||'/'||$12::text,now();

if not exists(select 1 from  se_material_master where name=$4 and code=$5) then

    select ug_rid into uomu_grid from se_uom_group where name=$1;-- uomfruo_rid

    if uomu_grid is null then

        INSERT INTO se_uom_group (name, description, group_rid, status, def_uom_rid) 
        select uom,'',3,1,1
        returning ug_rid into uomu_grid;

        INSERT INTO se_uom (name, ug_rid, status, is_whole_number) 
        select matcat,uomu_grid,1,0
        returning uom_rid into uom_rid_new;
    end if;


    select mc_rid into mcrid from se_mat_category where title=$2;
    select msc_rid into mscrid from se_mat_sub_category where title=$3;

    if mcrid is null then

        INSERT INTO se_mat_category (title, code, status, created_user_rid, created_datetime) 
        select matcat,'',1,907,now()
        returning mc_rid into mcrid;

        INSERT INTO se_mat_sub_category (mc_rid, title, code, status, created_user_rid, created_datetime) 
        select mcrid,matsubcat,'',1,907,now()
        returning msc_rid into mscrid;
    end if;

    select (case when $11='true' then 1 else 0 end) into serial_flag;

    --select (case when exists(select 1 from se_make where mc_rid=mcrid and msc_rid=mscrid) then 1 else 0 end) into hasmake;

    INSERT INTO se_material_master (name, code, description, uom_group_rid, hsn_code, mc_rid, msc_rid, group_rid, is_set, is_global, serial_flag, status,created_user_rid, created_datetime, code_part_type, has_make, short_name, has_labour, is_box_serial, gst_slab, sgst, cgst, igst, default_uom_rid)
    select matname,matcode,mat_description,uomu_grid,coalesce($12,''),mcrid,mscrid,3,0,0,serial_flag,1,907,now(),0,0,'',0,0,null,0,0,0,uomu_grid
    returning mm_rid into matrid;

    INSERT INTO public.tblidatum_material_master (mat_rid,smcbox_oemid,smcbox_sapid)
    select matrid,$7,$8;

end if;

END;
$function$
