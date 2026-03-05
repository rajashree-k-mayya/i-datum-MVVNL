
--To store update meter details API data/ Newly MI done Data

CREATE TABLE tblidatum_updatemi_logs(
    id SERIAL NOT NULL,
    distnid integer,
    distributionnodecode varchar,
    request varchar(500000),
    response varchar(500000),
    description varchar(500),
    status boolean DEFAULT false,
    created_datetime timestamp without time zone DEFAULT now(),
    type_id integer,
    push_datetime timestamp without time zone,
    PRIMARY KEY(id)
);
