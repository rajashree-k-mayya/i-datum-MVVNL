CREATE OR REPLACE FUNCTION public.fn_sync_idatum_crv(doc_number integer, bu_rid integer, crvdate text, remarks text, warehousecode text, contractorcode text, divisioncode text, materialname text, materialcode text, uom text, stockcondition text, quantity integer, serialno text, factoryfile text, type text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 

DECLARE
    matrid int4; contrid int4; stockid int4; matid int4; new_stockid int4; new_matid int4; cnt int4;
    f_file jsonb;


BEGIN

insert into assignmentpreelogs(fntext,created) select 'fn_sync_idatum_crv'||$1::text||'/'||$2::text||'/'||$3::text||'/'||$4::text||'/'||
$5::text||'/'||$6::text||'/'||$7::text||'/'||$8::text||'/'||$9::text||'/'||$10::text||'/'||$11::text||'/'||$12::text||'/'||$13::text||'/'||$14::text||'/'||$15::text,now();

if $15 = 'serialized' AND factoryfile IS NOT NULL AND factoryfile <> '' then
    f_file := factoryfile::jsonb;
else
    f_file := '{}'::jsonb;
end if;


select mm_rid::int4 into matrid from se_material_master where name=materialname and code=materialcode;

select contact_rid::int4 into contrid from se_contact where vendor_code=contractorcode;

select stock_rid,mat_rid into stockid, matid from se_stock where mat_rid=matrid and holder_rid=contrid and stock_condition_index=800;


if $15='serialized' then 
    if stockid is not null then 

        if not exists(select 1 from se_stock_material_serial_no where stock_rid=stockid and serial_no=$13) then 
            INSERT INTO se_stock_material_serial_no (stock_rid, mat_rid, serial_no, make_rid) VALUES (stockid,matid,upper(serialno),0);
        end if;

        select count(*) into cnt from se_stock_material_serial_no where stock_rid=stockid;

        update se_stock set qty=coalesce(qty,0) + cnt::numeric(10,4) where stock_rid=stockid;


    else 
        if contrid is not null then

            INSERT INTO se_stock (mat_rid, price, stock_condition_index, uom_rid, qty, holder_rid, holder_type, bu_rid, group_rid, created_datetime) 
            VALUES (matrid, 0.0, 800, 1, 0.0,contrid, 2, 20, 3, now())
            RETURNING stock_rid, mat_rid into new_stockid, new_matid;

            INSERT INTO se_stock_material_serial_no (stock_rid, mat_rid, serial_no, make_rid) VALUES (new_stockid,new_matid,upper(serialno),0);
        end if; 

        select count(*) into cnt from se_stock_material_serial_no where stock_rid=new_stockid;

        update se_stock set qty=coalesce(qty,0) + cnt::numeric(10,4) where stock_rid=new_stockid;

    end if;

elsif $15='non-serialized' then
    if stockid is not null then
    
        update se_stock set qty=coalesce(qty,0) + quantity::numeric(10,4) where stock_rid=stockid;

    else 
         
        INSERT INTO se_stock (mat_rid, price, stock_condition_index, uom_rid, qty, holder_rid, holder_type, bu_rid, group_rid, created_datetime) 
        VALUES (matrid, 0.0, 800, 1, quantity::numeric,contrid, 2, 20, 3, now())
        RETURNING stock_rid, mat_rid into new_stockid, new_matid;

        update se_stock set qty=quantity where stock_rid=new_stockid;

    end if;

end if;

--table insert-serialised
if ($15 = 'serialized' and not exists(select 1 from tbl_idatum_crvdetails a where a.serialno=$13 and a.documentnumber=doc_number )) then
    --($15 != 'serialized' and not exists(select 1 from tbl_idatum_crvdetails a where a.doc_num = doc_number and a.materialcode = $9 and a.type = $15 ) and not exists(select 1 from tbl_idatum_crvdetails where doc_num=doc_number ))  

INSERT INTO public.tbl_idatum_crvdetails (documentnumber, crvdate, remarks, warehousecode, contractorcode, divisioncode, materialname, materialcode, uom, stockcondition, quantity, serialno, type, wh_activity)
select doc_number, crvdate::date, remarks, warehousecode, contractorcode::int, divisioncode, materialname, materialcode, uom, stockcondition, quantity, upper(serialno) ,type,'CRV';

--values(doc_number, crvdate::date, remarks, warehousecode::int, contractorcode::int, divisioncode, materialname, materialcode, uom, stockcondition, quantity, upper(serialno), 
--        f_file->>'Manufacturing Month Year', f_file->>'Display Digits Length', f_file->>'Meter Body Seal 1', f_file->>'Meter Body Seal 2', f_file->>'Communication medium',
--        f_file->>'ModuleMake-Model', f_file->>'Module FW ver', f_file->>'IMEI Number(Cellular)RF', f_file->>'IMSI Number(SIM)', f_file->>'SIM No',
--        f_file->>'SIM IP address', f_file->>'HES Service', f_file->>'HES Server IP', (f_file->>'TCP Port')::int, f_file->>'APN', f_file->>'EK', f_file->>'AK', f_file->>'HLS (US)', f_file->>'HLS (FW)', f_file->>'LLS',type,'CRV',now(),f_file->>'Device ID',f_file->>'Utility Name',f_file->>'Phase'
--);
INSERT INTO public.tblfactoryfiles_history (serial_number, device_id, meter_make, meter_type, phase, current_rating, utility_name, meter_fw_version, manufacturing_month_year, display_digits_length, meter_body_seal_1, meter_body_seal_2, communication_medium, modulemake_model, module_fw_ver, imei_number_cellular_rf, imsi_number_sim
, sim_no, sim_ip_address, hes_service, hes_server_ip, tcp_port, apn, ek, hls_us, hls_fw, lls, ak, meter_nic_seal_1, meter_nic_seal_2, loose_seal_1, loose_seal_2, loose_seal_3, loose_seal_4, loose_seal_5, loose_seal_6,type_source)
select  serial_number, device_id, meter_make, meter_type, phase, current_rating, utility_name, meter_fw_version, manufacturing_month_year, display_digits_length, meter_body_seal_1, meter_body_seal_2, communication_medium, modulemake_model, module_fw_ver, imei_number_cellular_rf, imsi_number_sim
, sim_no, sim_ip_address, hes_service, hes_server_ip, tcp_port, apn, ek, hls_us, hls_fw, lls, ak, meter_nic_seal_1, meter_nic_seal_2, loose_seal_1, loose_seal_2, loose_seal_3, loose_seal_4, loose_seal_5, loose_seal_6,type_source
from tblfactoryfiledetails where serial_number=upper(serialno);

delete from tblfactoryfiledetails where serial_number=upper(serialno);


INSERT INTO tblfactoryfiledetails ( serial_number, device_id, meter_make, meter_type, phase, current_rating, utility_name, meter_fw_version, manufacturing_month_year, display_digits_length, meter_body_seal_1, meter_body_seal_2, communication_medium, modulemake_model, module_fw_ver, imei_number_cellular_rf, imsi_number_sim
, sim_no, sim_ip_address, hes_service, hes_server_ip, tcp_port, apn, ek, hls_us, hls_fw, lls, ak, meter_nic_seal_1, meter_nic_seal_2, loose_seal_1, loose_seal_2, loose_seal_3, loose_seal_4, loose_seal_5, loose_seal_6,type_source)

select upper(serialno), f_file->>'Device ID',f_file->>'Meter Make',f_file->>'Meter Type',f_file->>'Phase',f_file->>'Current Rating',f_file->>'Utility Name',f_file->>'Meter FW Version',f_file->>'Manufacturing Month Year',f_file->>'Display Digits Length',f_file->>'Meter Body Seal 1', f_file->>'Meter Body Seal 2',f_file->>'Communication medium',f_file->>'ModuleMake-Model',f_file->>'Module FW ver',f_file->>'IMEI Number(Cellular)RF', f_file->>'IMSI Number(SIM)',
f_file->>'SIM No',f_file->>'SIM IP address',f_file->>'HES Service', f_file->>'HES Server IP',f_file->>'TCP Port', f_file->>'APN', f_file->>'EK', f_file->>'HLS (US)',f_file->>'HLS (FW)',f_file->>'LLS', f_file->>'AK', f_file->>'Meter Nic Seal 1', f_file->>'Meter Nic Seal 2', f_file->>'Loose Seal 1',f_file->>'Loose Seal 2',f_file->>'Loose Seal 3',f_file->>'Loose Seal 4',f_file->>'Loose Seal 5',f_file->>'Loose Seal 6','idatum';

end if;

--table insert-non serialised
if ($15 = 'non-serialized' and not exists(select 1 from tbl_idatum_crvdetails a where a.documentnumber = doc_number and a.materialcode = $9 and a.type = $15)) then

INSERT INTO public.tbl_idatum_crvdetails (documentnumber, crvdate, remarks, warehousecode, contractorcode, divisioncode, materialname, materialcode, uom, stockcondition, quantity, serialno, type, wh_activity)
values(doc_number, crvdate::date, remarks, warehousecode, contractorcode::int, divisioncode, materialname, materialcode, uom, stockcondition, quantity, upper(serialno),type,'CRV'
);
end if;


END;
$function$
