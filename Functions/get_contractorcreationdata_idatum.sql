CREATE OR REPLACE FUNCTION public.get_contractorcreationdata_idatum()
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
BEGIN 

insert into tblidatum_contractorcreation_logs (contractorid,roleid,inchargeid,request,description,type_id,inserted)
select distinct contact_rid,roleid,incharge_user_rid,jsonb_build_object('uniqueId' ,contact_rid,'agencyCode',vendor_code ,'userName',username,'mobileNo',mobileno,'emailAddress',alternative_emailid,'role', discription,
'isIntellismartAccount', 'false','password', '','dob', date_of_birth,'isActive', (case when status=1 then 'true' else 'false' end),'Source','Styra','division',''),'Contractor Created',102,true from (
select a.contact_rid,a.vendor_code,a.firm_name,u.username,u.mobileno,u.alternative_emailid,r.discription,u.date_of_birth,u.status,pu.roleid,a.incharge_user_rid from se_contact a
inner join se_user_contact_map m on m.user_rid=a.incharge_user_rid
inner join tblusers u on u.userid=a.incharge_user_rid
inner join tblprojectuserallocation pu on pu.userid=u.userid
inner join tblrole r on r.roleid=pu.roleid
inner join se_contact_category_map cm on cm.contact_rid=a.contact_rid
where u.companyid=3 and pu.projectid=20 and cm.contact_category_index=753
 and NOT EXISTS ( SELECT 1 FROM tblidatum_contractorcreation_logs WHERE inserted='1' and contractorid = a.contact_rid )
) as d;



END; 
$function$
