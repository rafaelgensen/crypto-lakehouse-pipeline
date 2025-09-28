create schema if not exists silver;
create schema if not exists gold;

create table if not exists silver.coins (
    id              varchar(100),
    name            varchar(100),
    symbol          varchar(50),
    current_price   decimal(18,4),
    last_updated    timestamp,
    anomesdia       varchar(10)
);

create table if not exists gold.coin_aggregates (
    id              varchar(100),
    name            varchar(100),
    symbol          varchar(50),
    anomesdia       varchar(10),
    avg_price_usd   decimal(18,4),
    min_price_usd   decimal(18,4),
    max_price_usd   decimal(18,4),
    records_count   int,
    last_updated    timestamp
);