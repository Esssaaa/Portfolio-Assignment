create database nasdaq;
use nasdaq;
create table cov (
stock1 varchar(10),
stock2 varchar(10),
covariance double
);
create table r (
stock varchar(10),
meanReturn double
);
create table portfolio (
expReturn double,
expRisk double
);