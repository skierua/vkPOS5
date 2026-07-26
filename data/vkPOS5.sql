------------- SQLite3 Dump File -------------

-- ------------------------------------------
-- Dump of "acnt" ver.14.7
-- ------------------------------------------
PRAGMA user_version = 147;

CREATE TABLE "conf" (
    "key" TEXT PRIMARY KEY NOT NULL,
	"val" TEXT
) WITHOUT ROWID;

CREATE TABLE "acnt"(
	"id" Integer PRIMARY KEY,
	"acntno" Text NOT NULL,
	"item" Text,
	"beginamnt" Numeric DEFAULT 0,
	"turndbt" Numeric DEFAULT 0,
	"turncdt" Numeric DEFAULT 0,
	"dbtupd" Text,
	"cdtupd" Text,
	CONSTRAINT "acnt_item_RESTRICT_CASCADE_item_pkey_0" FOREIGN KEY ( "item" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
 );


-- ------------------------------------------
-- Dump of "acntbal"
-- ------------------------------------------

CREATE TABLE "acntbal"(
	"acntno" Text PRIMARY KEY,
	"client" Text,
	"acntnote" Text,
	"mask" Integer DEFAULT (0),
	"trade" Integer DEFAULT (0),
	CONSTRAINT "acntbal_client_RESTRICT_CASCADE_client_pkey_0" FOREIGN KEY ( "client" ) REFERENCES "client"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
 );

CREATE TRIGGER "t_acntbal_au"
	AFTER UPDATE OF "acntno"
	ON "acntbal"
	FOR EACH ROW
begin
  update acnt set acntno =  new.acntno where acntno = old.acntno;
  update strgacnt set acntno =  new.acntno where acntno = old.acntno;
  update docum set acntdbt =  new.acntno where acntdbt = old.acntno;
  update docum set acntcdt =  new.acntno where acntcdt = old.acntno;
  update strgdocum set acntdbt =  new.acntno where acntdbt = old.acntno;
  update strgdocum set acntcdt =  new.acntno where acntcdt = old.acntno;
  end;

-- ------------------------------------------
-- Dump of "acntrade"
-- ------------------------------------------

CREATE TABLE "acntrade"(
	"pkey" Integer PRIMARY KEY,
	"eqid" Integer,
	"rsltid" Integer,
	"bscprice" Numeric NOT NULL DEFAULT 0,
	"lastpricebuy" Numeric,
	"lastpricesell" Numeric,
	"acntno" Text,
	"article" Text,
	CONSTRAINT "acntrade_acnt_CASCADE_CASCADE_pkey_id_0" FOREIGN KEY ( "pkey" ) REFERENCES "acnt"( "id" )
		ON DELETE Cascade
		ON UPDATE Cascade,
	CONSTRAINT "acntrade_acnt_NO ACTION_NO ACTION_eqid_id_0" FOREIGN KEY ( "eqid" ) REFERENCES "acnt"( "id" ),
	CONSTRAINT "acntrade_acnt_NO ACTION_NO ACTION_rsltid_id_0" FOREIGN KEY ( "rsltid" ) REFERENCES "acnt"( "id" ),
	CONSTRAINT "acntrade_acntbal_RESTRICT_CASCADE_acntno_acntno_0" FOREIGN KEY ( "acntno" ) REFERENCES "acntbal"( "acntno" )
		ON DELETE Restrict
		ON UPDATE Cascade,
	CONSTRAINT "acntrade_item_RESTRICT_CASCADE_article_pkey_0" FOREIGN KEY ( "article" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
,
CONSTRAINT "check bscprice >= 0" CHECK (bscprice >= 0),
CONSTRAINT "check not null" CHECK (not null),
CONSTRAINT "check not null2" CHECK (not null) );

CREATE TRIGGER "t_acntrade_ad"
	AFTER DELETE
	ON "acntrade"
	FOR EACH ROW
begin
  delete from acnt where id = coalesce(old.eqid,0);
  delete from acnt where id = coalesce(old.rsltid,0);
 end;

CREATE TRIGGER "t_acntrade_ai"
	AFTER INSERT
	ON "acntrade"
	FOR EACH ROW
begin
  update acntrade set eqid = new.pkey+1, rsltid = new.pkey+2 where pkey = new.pkey;
  insert into acnt (id, acntno, item) values (new.pkey, new.acntno, new.article);
  insert into acnt (id, acntno) values (new.eqid, 'eqvl.'|| new.acntno || '/' || new.article);
  insert into acnt (id, acntno) values (new.rsltid, 'rslt.'|| new.acntno || '/' || new.article);
 end;

-- ------------------------------------------
-- Dump of "articlepriceqty"
-- ------------------------------------------

CREATE TABLE "articlepriceqty"(
	"pkey" Text PRIMARY KEY,
	"qty" Numeric DEFAULT 1,
	CONSTRAINT "articlepriceqty_item_RESTRICT_CASCADE_pkey_pkey_0" FOREIGN KEY ( "pkey" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
,
CONSTRAINT "check qty >0" CHECK (qty >0) );


-- ------------------------------------------
-- Dump of "balname"
-- ------------------------------------------

CREATE TABLE "balname"(
	"bal" Text PRIMARY KEY,
	"balname" Text,
	"articlemask" Integer,
	"trade" Integer );


-- ------------------------------------------
-- Dump of "cashier"
-- ------------------------------------------

CREATE TABLE "cashier"(
	"code" Text,
	"note" Text,
	"psw" Text DEFAULT '',
CONSTRAINT "unique_code" UNIQUE ( code ) );


-- ------------------------------------------
-- Dump of "client"
-- ------------------------------------------

CREATE TABLE "client"(
	"pkey" Text PRIMARY KEY,
	"clchar" Text,
	"phone" Text,
	"clnote" Text,
	"inptime" Text NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%S', 'now')),
CONSTRAINT "unique_clchar" UNIQUE ( clchar ) );


-- ------------------------------------------
-- Dump of "dcmtype"
-- ------------------------------------------

CREATE TABLE "dcmtype"(
	"pkey" Text PRIMARY KEY,
	"dctpchar" Text,
	"dctpname" Text,
	"tranable" Integer DEFAULT 1 );


-- ------------------------------------------
-- Dump of "docum"
-- ------------------------------------------

CREATE TABLE "docum"(
	"id" Integer PRIMARY KEY AUTOINCREMENT,
	"dcmtype" Text,
	"dcmno" Text,
	"item" Text,
	"acntdbt" Text,
	"acntcdt" Text,
	"amount" Numeric,
	"eqamount" Numeric,
	"discount" Numeric,
	"bonus" Numeric,
	"client" Text,
	"parentid" Integer,
	"dcmstate" Integer NOT NULL DEFAULT 0,
	"dcmnote" Text,
	"dcmtime" Text NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%S', 'now')),
	"dcmaker" Text,
	"retfor" Integer,
	CONSTRAINT "docum_dcmtype_RESTRICT_CASCADE_dcmtype_pkey_0" FOREIGN KEY ( "dcmtype" ) REFERENCES "dcmtype"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade,
	CONSTRAINT "docum_item_RESTRICT_CASCADE_item_pkey_0" FOREIGN KEY ( "item" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
 );


-- ------------------------------------------
-- Dump of "documtran"
-- ------------------------------------------

CREATE TABLE "documtran"(
	"dcmid" Integer NOT NULL,
	"amount" Numeric NOT NULL,
	"dbtid" Integer NOT NULL,
	"cdtid" Integer NOT NULL,
	CONSTRAINT "documtran_docum_CASCADE_CASCADE_dcmid_id_0" FOREIGN KEY ( "dcmid" ) REFERENCES "docum"( "id" )
		ON DELETE Cascade
		ON UPDATE Cascade,
	CONSTRAINT "documtran_acnt_RESTRICT_CASCADE_dbtid_id_0" FOREIGN KEY ( "dbtid" ) REFERENCES "acnt"( "id" )
		ON DELETE Restrict
		ON UPDATE Cascade,
	CONSTRAINT "documtran_acnt_RESTRICT_CASCADE_cdtid_id_0" FOREIGN KEY ( "cdtid" ) REFERENCES "acnt"( "id" )
		ON DELETE Restrict
		ON UPDATE Cascade
 );

CREATE TRIGGER "t_documtran_ai1"
	AFTER INSERT
	ON "documtran"
	FOR EACH ROW
	WHEN new.amount>0
begin
  update acnt set turndbt = turndbt + new.amount, dbtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now') where id = new.dbtid;
  update acnt set turncdt = turncdt + new.amount, cdtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now') where id = new.cdtid;
  end;

CREATE TRIGGER "t_documtran_ai2"
	AFTER INSERT
	ON "documtran"
	FOR EACH ROW
	WHEN new.amount<0
begin
  update acnt set turncdt = turncdt - new.amount, cdtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now') where id = new.dbtid;
  update acnt set turndbt = turndbt - new.amount, dbtupd = strftime('%Y-%m-%dT%H:%M:%S', 'now') where id = new.cdtid;
  end;

CREATE TRIGGER "t_documtran_d1"
	BEFORE DELETE
	ON "documtran"
	FOR EACH ROW
	WHEN old.amount>0
begin
  update acnt set turndbt = turndbt - old.amount where id = old.dbtid;
  update acnt set turncdt = turncdt - old.amount where id = old.cdtid;
  end;

CREATE TRIGGER "t_documtran_d2"
	BEFORE DELETE
	ON "documtran"
	FOR EACH ROW
	WHEN old.amount<0
begin
  update acnt set turncdt = turncdt + old.amount where id = old.dbtid;
  update acnt set turndbt = turndbt + old.amount where id = old.cdtid;
  end;

-- ------------------------------------------
-- Dump of "item"
-- ------------------------------------------

CREATE TABLE "item"(
	"pkey" Text PRIMARY KEY,
	"folder" Integer DEFAULT 0,
	"scancode" Text,
	"parentid" Text,
	"itemchar" Text,
	"itemname" Text,
	"itemnote" Text,
	"defunit" Text,
	"itemmask" Integer DEFAULT 0,
	"uktzed" Text DEFAULT '',
	"taxchar" Text DEFAULT '',
	"taxprc" Text DEFAULT '',
	CONSTRAINT "item_itemunit_RESTRICT_CASCADE_defunit_pkey_0" FOREIGN KEY ( "defunit" ) REFERENCES "itemunit"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
,
CONSTRAINT "unique_itemchar" UNIQUE ( itemchar ) );

CREATE TRIGGER "t_item_au"
	AFTER UPDATE OF "pkey"
	ON "item"
	FOR EACH ROW
begin
  update strgacnt set item =  new.pkey where item = old.pkey;
  update strgdocum set item =  new.pkey where item = old.pkey;
  update acntrade set article =  new.pkey where article = old.pkey;
 end;

-- ------------------------------------------
-- Dump of "itemunit"
-- ------------------------------------------

CREATE TABLE "itemunit"(
	"pkey" Text PRIMARY KEY,
	"unitchar" Text,
	"parentid" Text,
	"unitprec" Integer NOT NULL DEFAULT 0,
	"unitname" Text,
	"parentqtty" Numeric,
	"code" Text );


-- ------------------------------------------
-- Dump of "price"
-- ------------------------------------------

CREATE TABLE "price"(
	"id" Integer PRIMARY KEY,
	"item" Text NOT NULL,
	"prbidask" Integer,
	"qtty" Numeric DEFAULT 1,
	"price" Numeric NOT NULL DEFAULT 0,
	"pricetime" Text DEFAULT (strftime('%Y-%m-%dT%H:%M:%S', 'now')),
	"prtype" Text,
	"diff" Numeric DEFAULT 0,
	CONSTRAINT "price_item_RESTRICT_CASCADE_item_pkey_0" FOREIGN KEY ( "item" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
,
CONSTRAINT "check (prbidask = 1) or (prbidask = -1)" CHECK ((prbidask = 1) or (prbidask = -1)),
CONSTRAINT "check qtty >=0" CHECK (qtty >=0),
CONSTRAINT "check price >= 0" CHECK (price >= 0) );


-- ------------------------------------------
-- Dump of "selldsc"
-- ------------------------------------------

CREATE TABLE "selldsc"(
	"article" Text PRIMARY KEY,
	"price" Numeric NOT NULL DEFAULT 0,
	"pricetime" Text DEFAULT (strftime('%Y-%m-%dT%H:%M:%S', 'now')),
	CONSTRAINT "selldsc_item_RESTRICT_CASCADE_article_pkey_0" FOREIGN KEY ( "article" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
 );


-- ------------------------------------------
-- Dump of "selloffer"
-- ------------------------------------------

CREATE TABLE "selloffer"(
	"article" Text PRIMARY KEY,
	"qtty" Numeric DEFAULT 1,
	"price" Numeric NOT NULL DEFAULT 0,
	"pricetime" Text DEFAULT (strftime('%Y-%m-%dT%H:%M:%S', 'now')),
	CONSTRAINT "selloffer_item_RESTRICT_CASCADE_article_pkey_0" FOREIGN KEY ( "article" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
,
CONSTRAINT "check qtty >=0" CHECK (qtty >=0),
CONSTRAINT "check price >=0" CHECK (price >=0) );


-- ------------------------------------------
-- Dump of "shift"
-- ------------------------------------------

CREATE TABLE "shift"(
	"id" Integer PRIMARY KEY,
	"shftdate" Text,
	"shftbegin" Text,
	"shftend" Text,
	"cshr" Text DEFAULT '' );


-- ------------------------------------------
-- Dump of "strgacnt"
-- ------------------------------------------

CREATE TABLE "strgacnt"(
	"shftid" Integer NOT NULL DEFAULT 0,
	"acntid" Integer,
	"acntno" Text NOT NULL,
	"item" Text,
	"beginamnt" Numeric DEFAULT 0,
	"turndbt" Numeric DEFAULT 0,
	"turncdt" Numeric DEFAULT 0,
PRIMARY KEY ( "shftid", "acntid" ) );


-- ------------------------------------------
-- Dump of "strgdocum"
-- ------------------------------------------

CREATE TABLE "strgdocum"(
	"dcmid" Integer PRIMARY KEY,
	"shftid" Integer,
	"dcmtype" Text,
	"dcmno" Text,
	"item" Text,
	"acntdbt" Text,
	"acntcdt" Text,
	"amount" Numeric,
	"eqamount" Numeric,
	"discount" Numeric,
	"bonus" Numeric,
	"client" Text,
	"parentid" Integer,
	"dcmstate" Integer,
	"dcmnote" Text,
	"dcmtime" Text,
	"dcmaker" Text,
	"retfor" Integer );


-- ------------------------------------------
-- Dump of "strgprice"
-- ------------------------------------------

CREATE TABLE "strgprice"(
	"id" Integer PRIMARY KEY,
	"item" Text NOT NULL,
	"prbidask" Integer,
	"qtty" Numeric,
	"price" Numeric,
	"prtype" Text,
	"pricetime" Text DEFAULT (strftime('%Y-%m-%dT%H:%M:%S', 'now')),
	"diff" Numeric DEFAULT 0,
	CONSTRAINT "strgprice_item_RESTRICT_CASCADE_item_pkey_0" FOREIGN KEY ( "item" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
 );


-- ------------------------------------------
-- Dump of "strgtran"
-- ------------------------------------------

CREATE TABLE "strgtran"(
	"dcmid" Integer NOT NULL,
	"amount" Numeric NOT NULL,
	"dbtid" Integer,
	"cdtid" Integer,
	CONSTRAINT "strgtran_strgdocum_CASCADE_CASCADE_dcmid_dcmid_0" FOREIGN KEY ( "dcmid" ) REFERENCES "strgdocum"( "dcmid" )
		ON DELETE Cascade
		ON UPDATE Cascade
 );


-- ------------------------------------------
-- Dump of "taxdcm"
-- ------------------------------------------

CREATE TABLE "taxdcm"(
	"pkey" Integer PRIMARY KEY AUTOINCREMENT,
	"request" Text,
	"response" Text,
	"dcmid" Text DEFAULT '' );


-- ------------------------------------------
-- Dump of "warranty"
-- ------------------------------------------

CREATE TABLE "warranty"(
	"article" Text PRIMARY KEY,
	"term" Integer NOT NULL,
	CONSTRAINT "warranty_item_RESTRICT_CASCADE_article_pkey_0" FOREIGN KEY ( "article" ) REFERENCES "item"( "pkey" )
		ON DELETE Restrict
		ON UPDATE Cascade
,
CONSTRAINT "check term >= 0" CHECK (term >= 0) );


CREATE VIEW acnt_am as select * from acnt where beginamnt!=0 or turndbt !=0 or turncdt !=0;
CREATE VIEW acntradeview as 
select a.acntno, a.item, a.beginamnt+a.turndbt-a.turncdt as total, aeq.beginamnt+aeq.turndbt-aeq.turncdt as totaleq, bscprice, lastpricebuy, lastpricesell, lastpricebuytime, lastpriceselltime 
from acnt as a join acntrade as t on (a.id = t.pkey) join acnt as aeq on (t.eqid = aeq.id);
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
  from strgdocum;
