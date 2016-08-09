CREATE TABLE history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    job varchar(50) not null,
    status varchar(50),
    iso varchar(255),
    log varchar(255),
    starttime DATETIME,
    duration varchar(50),
    pxe INTEGER
);
