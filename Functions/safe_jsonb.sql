CREATE OR REPLACE FUNCTION public.safe_jsonb(text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN $1::jsonb;
EXCEPTION WHEN others THEN
    RETURN NULL;
END;
$function$
