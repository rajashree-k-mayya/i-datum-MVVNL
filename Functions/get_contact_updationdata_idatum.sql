CREATE OR REPLACE FUNCTION public.get_contact_updationdata_idatum()
 RETURNS void
 LANGUAGE plpgsql
AS $function$ 
BEGIN 

with datactea as(
select a.contact_rid,u.userid,a.vendor_code,u.username,u.mobileno,u.alternative_emailid,r.discription,pu.roleid,u.status,u.date_of_birth,a.incharge_user_rid  from se_contact a
inner join se_user_contact_map m on m.user_rid=a.incharge_user_rid
inner join tblusers u on u.userid=a.incharge_user_rid
inner join tblprojectuserallocation pu on pu.userid=u.userid
inner join tblrole r on r.roleid=pu.roleid
inner join se_contact_category_map cm on cm.contact_rid=a.contact_rid
where u.companyid=3 and pu.projectid=20 and cm.contact_category_index=753
)
,roledata as(
select DISTINCT ON (a.contractorid) a.contractorid,a.roleid,a.inchargeid from tblidatum_contractorcreation_logs a
inner join datactea b on b.contact_rid=a.contractorid
where  (a.inserted = true OR a.updated = true)  ORDER BY a.contractorid, a.api_id DESC
)
insert into tblidatum_contractorcreation_logs (contractorid,roleid,inchargeid,request,description,type_id,updated)
select distinct a.contact_rid,a.roleid,a.incharge_user_rid,jsonb_build_object('uniqueId' ,a.contact_rid,'agencyCode',a.vendor_code ,'userName',a.username,'mobileNo',a.mobileno,'emailAddress',a.alternative_emailid,'role',a.discription,
'isIntellismartAccount', 'false','password', '','dob', a.date_of_birth,'isActive', (case when a.status=1 then 'true' else 'false' end),'Source','Styra'),'Contractor Updated',103,true from datactea a
inner join roledata b on b.contractorid=a.contact_rid
where (b.roleid<>a.roleid or b.inchargeid<>a.incharge_user_rid);



END; 
$function$
