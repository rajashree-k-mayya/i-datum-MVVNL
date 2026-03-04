--To store idatum contractor creation/updation logs

CREATE TABLE tblidatum_contractorcreation_logs(
    api_id SERIAL NOT NULL,
    contractorid integer,
    roleid integer,
    inchargeid integer,
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
