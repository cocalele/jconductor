
PRAGMA foreign_keys = ON;

drop view if exists v_id;
drop view  if exists v_store_use;

drop view  if exists v_store_alloc_size;
drop view  if exists v_store_total_size;
drop view  if exists v_store_free_size;
drop view  if exists v_tray_alloc_size;
drop view  if exists v_tray_total_size;
drop view  if exists v_tray_free_size;
drop view  if exists v_primary_count;
drop view  if exists v_primary_s5store_id;
drop table  if exists t_volume;
drop table  if exists t_replica;
drop table  if exists t_quotaset;
drop table  if exists t_tenant;
drop table  if exists t_daemon;
drop table  if exists t_nic;
drop table  if exists t_tray;
drop table  if exists t_set;
drop table  if exists t_rge;
drop table  if exists t_fan;
drop table  if exists t_bcc;
drop table  if exists t_task_journal;
drop table  if exists t_power;
drop table  if exists t_seq_gen;
drop table  if exists t_s5store;
--'auth' column of 'tenant' describes access permission level of current tenant, 0 indicates normal user, 1 indicates administrator, -1 invalid tenant
-- car id from 0 ~ 63 is reserved for special usage, and will not be set to rge.
-- 
create table t_tenant(
	idx integer primary key not null, 
	car_id integer not null, 
	name varchar(96) unique not null, 
	pass_wd varchar(256) not null, 
	auth int not null, 
	size int not null, 
	iops int not null, 
	cbs int not null, 
	bw int not null);


insert into t_tenant(idx, car_id, name, pass_wd, auth, size, iops, cbs, bw) values(0, 0, 'tenant_default', '123456', -1, 0, 0, 0, 0);
insert into t_tenant(idx, car_id, name, pass_wd, auth, size, iops, cbs, bw) values(1, 0, 'system_sp_tenant', '123456', -1, 0, 0, 0, 0);

--init administrator (id for administrator starts from 32 to 63)
insert into t_tenant(idx, car_id, name, pass_wd, auth, size, iops, cbs, bw) values(32, -1, 'admin', '123456', 1, 0, 0, 0, 0);

create table t_quotaset(
	idx integer primary key not null, 
	car_id integer not null, 
	name varchar(96) not null, 
	iops int not null, 
	cbs int not null, 
	bw int not null, 
	tenant_idx integer not null, 
	foreign key (tenant_idx) references t_tenant(idx));

insert into t_quotaset(idx, car_id, name, iops, cbs, bw, tenant_idx) values(65, 1, 'quotaset_default', 0, 0, 0, 0);

create table t_s5store(
	idx integer primary key autoincrement , 
	name varchar(96) unique not null, 
	sn varchar(128) unique not null, 
	model varchar(128) not null, 
	mngt_ip varchar(32) unique not null,
	status integer not null);


--'access' describes access permission property of volume, 1 ---'00 01' owner read-only, 3 --- '00 11' owner read-write, 5 --- '01 01' all read, 7 --- '01 11' all-read owner-write,
--15 --- '11 11' all read-write
create table t_volume(
	idx integer primary key not null, 
	car_id integer not null, 
	name varchar(96) not null, 
	access int not null, 
	size int not null, 
	iops int not null , 
	cbs int not null, 
	bw int not null, 
	tenant_idx integer not null, 
	quotaset_idx integer not null, 
	flag int not null, 
	status integer not null, 
	exposed boolean default(0),
	primary_rep_idx integer,
	foreign key (tenant_idx) references t_tenant(idx), 
	foreign key (quotaset_idx) references t_quotaset(idx));


create view v_id as select idx from t_tenant union all select idx from t_volume union all select idx from t_quotaset;

--all status field in t_daemon,t_nic, t_rge, t_tray, t_set, t_fan, 1 ---- NA, 2 ---- ERROR, 3 ---- WARNING, 4 ---- OK
-- role  1 ---- master, 0 ---- slave
create table t_daemon(
	idx integer primary key autoincrement , 
	name varchar(96) unique not null, 
	role integer not null, 
	ip_addr varchar(16) unique not null, 
	store_idx integer not null, 
	status integer not null, 
	foreign key (store_idx) references t_s5store(idx));



create table t_bcc(
	idx integer primary key autoincrement , 
	name varchar(96) not null, 
	status integer not null, 
	model varchar(128) not null,
	daemon_idx integer not null, 
	foreign key (daemon_idx) references t_daemon(idx));


create table t_rge(
	idx integer primary key autoincrement , 
	name varchar(96) not null, 
	status integer not null, 
	model varchar(128) not null, 
	bit integer not null,
	daemon_idx integer not null, 
	foreign key (daemon_idx) references t_daemon(idx));


create table t_nic(
	idx integer primary key autoincrement , 
	name varchar(96) not null, 
	ip_addr varchar(16) unique not null,
	mask varchar(16) not null, 
	mac varchar(18) unique not null, 
	daemon_idx integer not null, 
	seq_in_daemon integer not null, 
	status integer not null, 
	foreign key (daemon_idx) references t_daemon(idx));

create table t_tray(
	idx integer primary key autoincrement ,  -- idx generated by DB, as key
	name varchar(96) not null, 
	status integer not null, 
	model varchar(128) not null, 
	bit integer not null, 
	firmware integer not null, 
	raw_capacity long not null, 
	set0_name varchar(96) not null, 
	set0_status integer not null, 
	set0_model varchar(128) not null, 
	set0_bit integer not null, 
	set1_name varchar(96) not null, 
	set1_status integer not null, 
	set1_model varchar(128) not null, 
	set1_bit integer not null, 
	store_idx integer not null, 
	--tray_id integer not null, -- tray ID, in its S5 store, always start from 0
	foreign key (store_idx) references t_s5store(idx));


create table t_power(
	idx integer primary key autoincrement , 
	name varchar(96) not null, 
	status integer not null, 
	store_idx integer not null, 
	foreign key (store_idx) references t_s5store(idx));


create table t_fan(
	idx integer primary key autoincrement , 
	name varchar(96) not null, 
	store_idx integer not null, 
	status integer not null, 
	foreign key (store_idx) references t_s5store(idx));


create table t_task_journal(
	idx integer primary key autoincrement , 
	type integer not null, 
	task blob, 
	time varchar(20) not null default (datetime('now', 'localtime')));

create table t_replica(
	idx integer primary key autoincrement , 
	volume_idx integer,
	store_idx integer,
	tray_id	integer,
	status integer default 0);

create view v_store_alloc_size as  select store_idx, sum(size) as alloc_size from t_volume, t_replica where t_volume.idx=t_replica.volume_idx group by t_replica.store_idx;
create view v_store_total_size as  select store_idx, sum(t.raw_capacity) as total_size from t_tray as t where t.status=0 group by t.store_idx;
create view v_store_free_size as select t.store_idx, t.total_size, COALESCE(a.alloc_size,0) as alloc_size , t.total_size-COALESCE(a.alloc_size,0) as free_size 
 from v_store_total_size as t left join v_store_alloc_size as a on t.store_idx=a.store_idx order by free_size desc;
create view v_tray_alloc_size as select  t_replica.store_idx as store_idx, tray_id, sum(size) as alloc_size from t_volume, t_replica where t_volume.idx = t_replica.volume_idx group by t_replica.tray_id , t_replica.store_idx;	
create view v_tray_total_size as select store_idx, cast(substr(name,6) as int) as tray_id, raw_capacity as total_size, status from t_tray;
create view v_tray_free_size as select t.store_idx as store_idx, t.tray_id as tray_id, t.total_size as total_size,
 COALESCE(a.alloc_size,0) as alloc_size , t.total_size-COALESCE(a.alloc_size,0) as free_size, t.status as status from v_tray_total_size as t left join v_tray_alloc_size as a on t.store_idx=a.store_idx and t.tray_id=a.tray_id order by free_size desc;
-- select store_idx, tray_id, max(free_size) from v_tray_free_size group by store_idx;

--table used to generate sequence, val keep the latest available value
create table t_seq_gen(
	name varchar(32) primary key,
	val	integer not null);
insert into t_seq_gen values("vol_id", 66);
