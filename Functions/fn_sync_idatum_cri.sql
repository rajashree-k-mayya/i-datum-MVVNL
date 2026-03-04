CREATE OR REPLACE FUNCTION public.fn_sync_idatum_cri(doc_number integer, cridate text, remarks text, fromcontractorcode text, materialname text, materialcode text, uom text, stockcondition text, quantity integer, serialno text, type text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
DECLARE 
    stockid int4; matid int4; cnt int4; contrid int4;
BEGIN

if $11='serialized' then

    select stock_rid,mat_rid into stockid, matid
    from se_stock_material_serial_no where serial_no=serialno; 

    if stockid is not null and exists(select 1 from se_stock where stock_rid=stockid and mat_rid=matid and stock_condition_index=800) then


        delete from se_stock_material_serial_no where serial_no=serialno and stock_rid=stockid and mat_rid=matid;

        select count(*) into cnt from se_stock_material_serial_no where stock_rid=stockid;

        update se_stock set qty=cnt::numeric(10,4) where stock_rid=stockid;

    end if;

elsif $11='non-serialized' then

    select mm_rid::int4 into matid from se_material_master where name=materialname and code=materialcode;

    select contact_rid::int4 into contrid from se_contact where vendor_code=fromcontractorcode;

    select stock_rid,mat_rid into stockid, matid from se_stock where mat_rid=matid and holder_rid=contrid and stock_condition_index=800;

    if stockid is not null and exists(select 1 from se_stock where stock_rid=stockid and mat_rid=matid and stock_condition_index=800) then
        
        update se_stock set qty=(qty - quantity)::numeric(10,4)  where stock_rid=stockid;

    end if;

end if;

--table insert-serialised
if ($11 = 'serialized' and not exists(select 1 from tbl_idatum_cridetails a where a.serial_num=$10 and a.doc_num=doc_number)) then

    INSERT INTO public.tbl_idatum_cridetails (doc_num, cridate, remarks, fromcontractorcode, materialname, materialcode, uom, stock_condition, quantity, serial_num, type, wh_activity, createddatetime) 
    VALUES (doc_number, cridate::date, remarks, fromcontractorcode, materialname, materialcode, uom, stockcondition, quantity, serialno,"type", 'CRI', now());
end if;

--table insert-non-serialised
if ($11 = 'non-serialized' and not exists(select 1 from tbl_idatum_cridetails a where a.doc_num = doc_number and a.materialcode = $6 and a.type = $11)) then

    INSERT INTO public.tbl_idatum_cridetails (doc_num, cridate, remarks, fromcontractorcode, materialname, materialcode, uom, stock_condition, quantity, serial_num, type, wh_activity, createddatetime) 
    VALUES (doc_number, cridate::date, remarks, fromcontractorcode, materialname, materialcode, uom, stockcondition, quantity, serialno,"type", 'CRI', now());
end if;
END;
$function$
