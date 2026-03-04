--To store all Swap/delete MI data logs

CREATE TABLE tblidatum_consumerswap_logs(
    swap_id SERIAL NOT NULL,
    distnid integer,
    distributionnodecode varchar,
    "source" varchar(100),
    request varchar(500000),
    response varchar(500000),
    description varchar(500),
    status boolean DEFAULT false,
    created_datetime timestamp without time zone DEFAULT now(),
    type_id integer,
    push_datetime timestamp without time zone,
    pushlog_id bigint,
    PRIMARY KEY(swap_id)
);
CREATE UNIQUE INDEX uniq_delete_event ON public.tblidatum_consumerswap_logs USING btree (pushlog_id);
