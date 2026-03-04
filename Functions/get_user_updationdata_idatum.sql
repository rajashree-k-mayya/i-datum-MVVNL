CREATE OR REPLACE FUNCTION public.get_user_updationdata_idatum()
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
BEGIN 


with contactctea as(
select u.userid,u.username,COALESCE(u."FirstName",'')||' '||COALESCE(u."LastName",'') uname,u.mobileno,u.alternative_emailid,cc.firm_name,cc.vendor_code,pu.roleid,cc.contact_rid,
cc.incharge_user_rid,u.date_of_birth from tblusers u 
inner join tblprojectuserallocation pu on pu.userid=u.userid 
inner join se_user_contact_map c on c.user_rid=u.userid 
inner join se_contact cc on cc.contact_rid=c.contact_rid and cc.status=1 
where pu.roleid in (2,26,28,79,80,65) and u.companyid=3  )

,roledata as(
select DISTINCT ON (userid) a.userid,a.roleid,a.contactid
 from tblidatum_usercreation_logs a
inner join contactctea b on b.userid=a.userid
where  (a.inserted = true OR a.updated = true) ORDER BY userid, api_id DESC
)
insert into tblidatum_usercreation_logs(userid,roleid,contactid,request,description,type_id,updated)
select distinct u.userid,u.roleid,u.contact_rid,jsonb_build_object('technician_Id', u.username,'name', uname,'mobile_number', u.mobileno,'email_address',
u.alternative_emailid,'password', '','contractorName', firm_name, 'contractorId', vendor_code,'contractorLoginId', b.username,'subdivision',
jsonb_build_object('location' , '','date' , ''),'dob', u.date_of_birth),'Technician Updated',104,true from contactctea u 
left join tblusers b on u.incharge_user_rid=b.userid 
inner join roledata b1 on b1.userid=u.userid
where (b1.roleid<>u.roleid or b1.contactid<>u.contact_rid) and not exists(select 1 from  tblidatum_usercreation_logs where status_created='0' and userid=u.userid);

 

END; 
$function$
