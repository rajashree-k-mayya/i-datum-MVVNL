CREATE OR REPLACE FUNCTION public.get_newconctractor_idatum(vendor_code character varying, firm_name character varying, search_term character varying, mobileno character varying, address character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 

BEGIN

insert into assignmentpreelogs(fntext,created) select 'get_newconctractor_idatum'|| $1::text||'/'||$2::text||'/'||$3::text||'/'||$4::text||'/'||$5::text,now();

if not exists(select 1 from  se_contact where firm_name=$2) then

    INSERT INTO se_contact (firm_name, contact_person, email, mobile, office_contact, address, image_url, group_rid, status, created_user_rid, created_datetime, vendor_code, alternate_contact, website, type_of_org, incharge_user_rid, data_json) 
    select firm_name,search_term,'',mobileno,'',address,'',3,1,907,now(),vendor_code,'','',0,0,'[]'::jsonb;

end if;



END;
$function$
