CREATE TABLE tblidatum_usercreation_logs(
    api_id SERIAL NOT NULL,
    userid integer,
    roleid integer,
    contactid integer,
    "source" text,
    request_url text,
    request varchar(500000),
    response varchar(500000),
    description varchar(500),
    status_created boolean DEFAULT false,
    status_updated boolean DEFAULT false,
    created_datetime timestamp without time zone DEFAULT now(),
    inserted boolean DEFAULT false,
    updated boolean DEFAULT false,
    type_id integer,
    push_datetime timestamp without time zone,
    PRIMARY KEY(api_id)
);
CREATE INDEX idx_userlog_inserted_userid ON public.tblidatum_usercreation_logs USING btree (userid) WHERE (inserted = true);
CREATE INDEX idx_userlog_userid_apiid_desc ON public.tblidatum_usercreation_logs USING btree (userid, api_id DESC);
CREATE INDEX idx_userlog_active_latest ON public.tblidatum_usercreation_logs USING btree (userid, roleid, contactid, api_id DESC) WHERE ((inserted = true) OR (updated = true));