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

create table address (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
deed_id varchar(100) not null,
address varchar(100) not null
);

create table pdfs (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
volpage varchar(100) unique not null,
content text not null
);

create table confidential_documents (
id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
volpage varchar(100) unique not null,
instrument_id varchar(100)
)
