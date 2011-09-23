create database deschutes;
use deschutes;

create table documents (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
volpage varchar(100) UNIQUE not null,
recording_date date not null,
doctype varchar(100) not null,
subtype varchar(100) not null,
instrument_id varchar(100)
);

create table mortgage_make_references (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
mortgage_volpage varchar(100) not null,
document_volpage varchar(100) not null,
rank int(15) not null
);

create table mortgage_deeds (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
mortgage_volpage varchar(100) not null,
deed_volpage varchar(100) not null
);

create table default_sales (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
volpage varchar(100) unique not null,
sale_date date
);

create table confidential_documents (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
volpage varchar(100) unique not null,
instrument_id varchar(100)
);

create table dial_records (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
account_number int(11) NOT NULL,
volpage varchar(100) unique NOT NULL,
address varchar(150) NOT NULL
);
