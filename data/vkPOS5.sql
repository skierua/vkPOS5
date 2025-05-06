CREATE TABLE balname
(
  bal text primary key,
  balname text,
  articlemask integer,
  trade integer);
CREATE TABLE shift
(
	id integer primary key,
	shftdate text,
	shftbegin text,
	shftend text 		-- default ( strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') )
, cshr text default '');
CREATE TABLE client
(
--   id integer primary key,	-- код
  pkey text primary key, 	-- цифровий код
  clchar text unique, 		-- коротка назва код
  phone text,
  clnote text,			-- примітки про клієнта
  inptime text not null default ( strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') )
  );
CREATE TABLE itemunit
(
--   id integer primary key,
  pkey text primary key,
  unitchar text,
  parentid text,		-- базова одиниця виміру (unitid)
  unitprec integer not null default 0,		-- кількість знаків після коми (точність)
  unitname text,
  parentqtty numeric		-- кількість у базових одиницях виміру (unitid)
, code text);
CREATE TABLE item
(
--   id integer primary key,
  pkey text primary key,				-- цифровий код
  folder integer default 0,		-- 0 - item, 1 - folder
  scancode text ,				-- скан код
  parentid text,
  itemchar text unique,				-- скорочена назва
  itemname text ,				-- повна назва
  itemnote text ,				-- примітка
  defunit text references itemunit (pkey) on update cascade on delete restrict,
  itemmask integer default 0
, uktzed text default '', taxchar text default '', taxprc text default '');
CREATE TABLE dcmtype
(
--   id integer primary key,
  pkey text primary key,
  dctpchar text,
  dctpname text,
  tranable integer default 1		-- 0 not tran, 1 amnt tran, 2 eq tran(+dsc), 4 bonus tran
);
CREATE TABLE docum
(
  id integer primary key autoincrement,
  dcmtype text references dcmtype (pkey) on update cascade on delete restrict,		-- тип документу
  dcmno text,
  item text references item (pkey) on update cascade on delete restrict,
  acntdbt text,			-- дебіт рахунок
  acntcdt text,			-- кредіт рахунок
  amount numeric ,	-- сума
  eqamount numeric,					-- сума еквіваленту в гривнях
  discount numeric,					-- сума знижки
  bonus numeric,						-- сума премії
  client text,			-- 
  parentid integer ,			-- id пачки документів
  dcmstate integer not null default 0, -- DCMNEW
  dcmnote text,										-- примітка
  dcmtime text not null default ( strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') ),
  dcmaker text 		-- користувач, що ввів документ
, retfor integer);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE strgdocum
(
  dcmid integer primary key,
  shftid integer,
  dcmtype text,		-- тип документу
  dcmno text,
  item text,		-- валюта документу
  acntdbt text,			-- дебіт рахунок
  acntcdt text,			-- кредіт рахунок
  amount numeric ,		-- сума
  eqamount numeric,	-- сума еквіваленту в гривнях
  discount numeric,		-- сума знижки
  bonus numeric,	-- сума премії
  client text,			--
  parentid integer ,			-- id пачки документів
  dcmstate integer,
  dcmnote text,		-- примітка
  dcmtime text,			-- час документу (та дата)
  dcmaker text 		-- користувач, що ввів документ
, retfor integer);
CREATE TABLE articlepriceqty
(
  pkey text primary key references item (pkey) on update cascade on delete restrict,	-- цифровий код
  qty numeric default 1 check (qty >0)
);
CREATE VIEW acnt_am as select * from acnt where beginamnt!=0 or turndbt !=0 or turncdt !=0
/* acnt_am(id,acntno,item,beginamnt,turndbt,turncdt,dbtupd,cdtupd) */;
CREATE VIEW acntradeview as 
select a.acntno, a.item, a.beginamnt+a.turndbt-a.turncdt as total, aeq.beginamnt+aeq.turndbt-aeq.turncdt as totaleq, bscprice, lastpricebuy, lastpricesell, lastpricebuytime, lastpriceselltime 
from acnt as a join acntrade as t on (a.id = t.pkey) join acnt as aeq on (t.eqid = aeq.id);
CREATE TABLE strgacnt
(
  shftid integer default 0 not null,
  acntid integer,
  acntno text not null,
  item text,
  beginamnt numeric default 0,		-- залишок на рахунку на початок зміни
  turndbt numeric default 0,
  turncdt numeric default 0,
  constraint strgacnt_pk primary key (shftid, acntid)
);
CREATE TABLE acnt
(
  id integer primary key,
  acntno text not null,
  item text references item (pkey) on update cascade on delete restrict,
  beginamnt numeric default 0,		-- залишок на рахунку на початок зміни
  turndbt numeric default 0,
  turncdt numeric default 0,
  dbtupd text,						-- час останньої зміни debit
  cdtupd text						-- час останньої зміни credit
--   ,constraint acnt_unique unique (acntno,itemid)	-- різні приходи
);
CREATE TABLE acntbal (
  acntno text primary key,
  client TEXT references client (pkey) on update cascade on delete restrict,
  acntnote TEXT,
  mask INTEGER DEFAULT (0),
  trade INTEGER DEFAULT (0)
);
CREATE TABLE strgprice
(
    id integer primary key,
    item text not null references item (pkey) on update cascade on delete restrict,
    prbidask integer, -- 1 bid, -1 ask
    qtty numeric,
    price numeric,		-- курс купівлі
    prtype text,
    pricetime text default ( strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') ),
    diff numeric default 0	-- різниця зміни курсу
);
CREATE TABLE price (
    id integer primary key,
    item text not null references item (pkey) on update cascade on delete restrict,
    prbidask integer check ((prbidask = 1) or (prbidask = -1)), -- [+]1 bid, -1 ask
    qtty numeric default 1 check (qtty >=0),
    price numeric not null default 0 check (price >= 0),			-- курс купівлі
    pricetime text default ( strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') ),
    prtype text  -- price type
, diff numeric default 0);
CREATE TABLE selldsc
(
    article text primary key references item (pkey) on update cascade on delete restrict,
    price numeric not null default 0,  -- discount
    pricetime text default ( strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') )
);
CREATE TABLE selloffer
(
    article text primary key references item (pkey) on update cascade on delete restrict,
    qtty numeric default 1 check (qtty >=0),
    price numeric not null default 0 check (price >=0),
    pricetime text default ( strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') )
);
CREATE TRIGGER t_selloffer_ai
  after insert on selloffer for each row 
  begin
   insert into strgprice ( item, prbidask, qtty, price, prtype)
    values ( new.article, -1, new.qtty, new.price, 'offer');
  end;
CREATE TRIGGER t_selldsc_ai
  after insert on selldsc for each row 
  begin
   insert into strgprice ( item, prbidask, qtty, price, prtype)
    values ( new.article, -1, 0, new.price, 'discount');
  end;
CREATE TABLE documtran
(
  dcmid integer not null references docum (id) on update cascade on delete cascade,
  amount numeric not null,
  dbtid integer not null references acnt (id) on update cascade on delete restrict,
  cdtid integer not null references acnt (id) on update cascade on delete restrict
);
CREATE TRIGGER t_documtran_d1 delete on documtran for each row when old.amount>0
  begin
  update acnt set turndbt = turndbt - old.amount where id = old.dbtid;
  update acnt set turncdt = turncdt - old.amount where id = old.cdtid;
  end;
CREATE TRIGGER t_documtran_d2 delete on documtran for each row when old.amount<0
  begin
  update acnt set turncdt = turncdt + old.amount where id = old.dbtid;
  update acnt set turndbt = turndbt + old.amount where id = old.cdtid;
  end;
CREATE TRIGGER t_documtran_ai1 after insert on documtran when new.amount>0
  begin
  update acnt set turndbt = turndbt + new.amount, dbtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') where id = new.dbtid;
  update acnt set turncdt = turncdt + new.amount, cdtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') where id = new.cdtid;
  end;
CREATE TRIGGER t_documtran_ai2 after insert on documtran when new.amount<0
  begin
  update acnt set turncdt = turncdt - new.amount, cdtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') where id = new.dbtid;
  update acnt set turndbt = turndbt - new.amount, dbtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') where id = new.cdtid;
  end;
CREATE TABLE strgtran
(
  dcmid integer not null references strgdocum (dcmid) on update cascade on delete cascade,
  amount numeric not null,
  dbtid integer,
  cdtid integer
);
CREATE TABLE acntrade
(
  pkey integer primary key references acnt (id) on update cascade on delete cascade,
  eqid integer references acnt (id), -- on update cascade on delete restrict
  rsltid integer references acnt (id), -- on update cascade on delete restrict
  bscprice numeric not null default 0 check (bscprice >= 0),			-- курс обліку (basic)
  lastpricebuy numeric,			-- курс останньої купівлі
  lastpricesell numeric,			-- курс останнього продажу
  acntno text check(not null)  references acntbal (acntno) on update cascade on delete restrict, 
  article text check(not null)  references item (pkey) on update cascade on delete restrict
);
CREATE TRIGGER t_acntbal_au after update of acntno on acntbal
  begin
  update acnt set acntno =  new.acntno where acntno = old.acntno;
  update strgacnt set acntno =  new.acntno where acntno = old.acntno;
  update docum set acntdbt =  new.acntno where acntdbt = old.acntno;
  update docum set acntcdt =  new.acntno where acntcdt = old.acntno;
  update strgdocum set acntdbt =  new.acntno where acntdbt = old.acntno;
  update strgdocum set acntcdt =  new.acntno where acntcdt = old.acntno;
  end;
CREATE TRIGGER t_item_au after update of pkey on item
  begin
  update strgacnt set item =  new.pkey where item = old.pkey;
  update strgdocum set item =  new.pkey where item = old.pkey;
  update acntrade set article =  new.pkey where article = old.pkey;
 end;
CREATE TABLE settings
(
	domcur	text,		-- цифровий код нац.валюти
	domchar	text,		-- літеррний код нац.валюти
	domname	text,		-- назва нац.валюти
	dbversion text,			-- версія бази даних
	branchname text,
	branchname2 text,
	branchaddres text
	, acnts text default '');
CREATE VIEW documall as
  select 0 shftid,
    id,
    dcmtype,
    dcmno,
    item,
    acntdbt,
    acntcdt,
    amount,
    eqamount,
    discount,
    bonus,
    client,
    parentid,
    dcmstate,
    dcmnote,
    dcmtime,
    dcmaker,
   retfor 
  from docum
  union
  select shftid,
    dcmid id,
    dcmtype,
    dcmno,
    item,
    acntdbt,
    acntcdt,
    amount,
    eqamount,
    discount,
    bonus,
    client,
    parentid,
     dcmstate,
     dcmnote,
    dcmtime,
    dcmaker,
    retfor
  from strgdocum
/* documall(shftid,id,dcmtype,dcmno,item,acntdbt,acntcdt,amount,eqamount,discount,bonus,client,parentid,dcmstate,dcmnote,dcmtime,dcmaker,retfor) */;
CREATE TABLE warranty
(
    article text primary key references item (pkey) on update cascade on delete restrict,
    term integer not null  check (term >= 0) -- warranty term in days
);
CREATE TRIGGER t_price_au
  after update on price for each row when (((new.price!=old.price) or (new.qtty!=old.qtty)) and (old.price!=0))
  begin
  update price set diff =  new.price-old.price, pricetime = strftime('%Y-%m-%dT%H:%M:%S', 'now','localtime') where id = new.id;
  insert into strgprice (item, prbidask, qtty, price, prtype, diff)
    values ( new.item, new.prbidask, new.qtty, new.price, new.prtype,new.price-old.price);
  end;
CREATE TABLE taxdcm
(
  pkey  integer primary key autoincrement, 	-- номер документу
  request text, 		-- JSON дані запиту
  response text 		-- JSON дані відповіді
  , dcmid text default '');
CREATE TABLE cashier(
	"code" text,
	"note" text,
	"psw" text default '',
CONSTRAINT "unique_code" UNIQUE ( code ) );
CREATE TRIGGER t_acntrade_ad after delete on acntrade
  begin
  delete from acnt where id = coalesce(old.eqid,0);
  delete from acnt where id = coalesce(old.rsltid,0);
 end;
CREATE TRIGGER t_acntrade_ai after insert on acntrade
  begin
  update acntrade set eqid = new.pkey+1, rsltid = new.pkey+2 where pkey = new.pkey;
  insert into acnt (id, acntno, item) values (new.pkey, new.acntno, new.article);
  insert into acnt (id, acntno) values (new.eqid, 'eqvl.'|| new.acntno || '/' || new.article);
  insert into acnt (id, acntno) values (new.rsltid, 'rslt.'|| new.acntno || '/' || new.article);
 end;
