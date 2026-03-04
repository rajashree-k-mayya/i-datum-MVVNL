CREATE OR REPLACE FUNCTION public.get_usercreationdata_idatum()
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
BEGIN 

with contactctea as(
select u.userid,u.username,COALESCE(u."FirstName",'')||' '||COALESCE(u."LastName",'') uname,u.mobileno,u.alternative_emailid,cc.firm_name,cc.vendor_code,cc.contact_rid,pu.roleid,
cc.incharge_user_rid,u.date_of_birth from tblusers u 
inner join tblprojectuserallocation pu on pu.userid=u.userid 
inner join se_user_contact_map c on c.user_rid=u.userid 
inner join se_contact cc on cc.contact_rid=c.contact_rid 
where pu.roleid in (2,26,28,79,80,65) and u.companyid=3 and cc.status=1
and NOT EXISTS ( SELECT 1 FROM tblidatum_usercreation_logs WHERE status_created='1'  and userid = u.userid ) )

insert into tblidatum_usercreation_logs(userid,contactid,roleid,request,description,type_id,inserted)
select distinct u.userid,u.contact_rid,u.roleid,jsonb_build_object('technician_Id', u.username,'name', uname,'mobile_number', u.mobileno,'email_address',
u.alternative_emailid,'password', '','contractorName', firm_name, 'contractorId', vendor_code,'contractorLoginId', b.username,'subdivision',
jsonb_build_object('location' , '','date' , ''),'dob', u.date_of_birth),'Create Technician',100,true from contactctea u 
left join tblusers b on u.incharge_user_rid=b.userid
where not exists(select 1 from  tblidatum_usercreation_logs where status_created='0' and userid=u.userid);
--RETURNING userid, request::jsonb ;

--INSERT INTO tblidatum_userid_pushlog (userid, status_inserted,description,type_id) 
--SELECT userid, 'true','Create Technician',100 FROM inserted ;

-- SELECT userid, request::jsonb 
-- FROM inserted; 

END; 
$function$
