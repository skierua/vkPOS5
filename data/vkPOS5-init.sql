--
-- populate vkPOS5 version 14.7 database
-- 
--
-- PRAGMA foreign_keys = ON;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;


INSERT INTO "settings" ("domcur","domchar","domname","dbversion","branchname","branchname2","branchaddres","acnts") VALUES 
( '980', 'UAH', 'українська гривня', '14.7', '', '', '', '{ "cash":"3000", "incas":"3003", "trade":"3500", "bulk":"3501",  "profit":"3607-55" }' );

INSERT INTO "shift" ("id","shftdate","shftbegin","shftend","cshr") VALUES ( 1, '2024-12-04', '2024-12-04', '', '' );

INSERT INTO "client" ("pkey","clchar","phone","clnote","inptime") VALUES ( '1000', 'Фіз.особа', NULL, NULL, '' );

INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'folder', 'ПАПКА', NULL, 0 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'memo', 'MEMO', NULL, 1 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'invoice', 'ТОРГ:Рахунок', NULL, 1 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'facture', 'ТОРГ:Накладна', NULL, 0 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'check', 'ТОРГ:ЧЕК', NULL, 0 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'trade:buy', 'ТОРГ:КУП', NULL, 7 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'trade:sell', 'ТОРГ:ПРОД', NULL, 7 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'pay:in', 'ПЛАТІЖ:ПРИХ', NULL, 1 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'pay:out', 'ПЛАТІЖ:РОЗХ', NULL, 1 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'service', 'ПОСЛУГИ', NULL, 6 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'trade:inner', 'ТОРГ:ВНУТР', NULL, 7 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'trade:buy:inner', 'ТОРГ:КУП:ВНУТР', NULL, 7 );
INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'trade:sell:inner', 'ТОРГ:ПРОД:ВНУТР', NULL, 7 );

INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '30', 'Залишок', 7, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '31', 'Коррахунок', 7, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '35', 'Торгівля', 6, 1 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( 'eq', 'Торг.Еквівалент', 6, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '36', 'Розрахунки', 7, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '38', 'Бонуси', 1, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '42', 'Капітал', 1, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '44', 'Дохід', 1, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( 'rs', 'Торг.Дохід', 1, 0 );
INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '80', 'Витрати', 1, 0 );

INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( '36001000', '1000', NULL, 7, 0 );
INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( '3607-55', NULL, 'ДохідВитрати', 7, 0 );
INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( '4200', NULL, 'Капітал', 0, 0 );
INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( '3000', NULL, NULL, 7, 0 );
INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( '3500', NULL, NULL, 14, 1 );
INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( 'rslt', NULL, 'ЕКВІВАЛЕНТ доходу', 1, 0 );
INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( '3501', NULL, 'ТОРГ-ГУРТ(HURT)', 0, 1 );

INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '980', 0, NULL, NULL, 'UAH', 'українська гривня', NULL, NULL, 1, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '100001', 1, NULL, NULL, 'ІНОЗ.ВАЛЮТА', 'Іноземна валюти та ін.', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '100002', 1, NULL, NULL, 'ТОВАР', 'Товари', NULL, NULL, 4, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '100003', 1, NULL, NULL, 'ПОСЛУГИ', 'Послуги', NULL, NULL, 8, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '100004', 1, NULL, '100001', 'ТелКартки', 'Телефонні картки', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '840', 0, NULL, '100001', 'USD', 'долар США', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '978', 0, NULL, '100001', 'EUR', 'ЄВРО', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '643', 0, NULL, '100001', 'RUB', 'російський рубль', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '203', 0, NULL, '100001', 'CZK', 'чеська крона', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '985', 0, NULL, '100001', 'PLN', 'польський злотий', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '826', 0, NULL, '100001', 'GBP', 'англійський фунт стрл.', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '124', 0, NULL, '100001', 'CAD', 'канадський долар', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '756', 0, NULL, '100001', 'CHF', 'швейцарський франк', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '036', 0, NULL, '100001', 'AUD', 'австралійський долар', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '752', 0, NULL, '100001', 'SEK', 'шведська крона', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '348', 0, NULL, '100001', 'HUF', 'угорський форинт', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '32', 0, NULL, '100001', 'EURmet', 'ЄВРО метал', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '33', 0, NULL, '100001', 'PLNmet', 'пол.злотий метал', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '31', 0, NULL, '100001', 'USD$1', 'долар США $1', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '578', 0, NULL, '100001', 'NOK', 'норвезька крона', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '208', 0, NULL, '100001', 'DKK', 'датська крона', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '946', 0, NULL, '100001', 'RON', 'румунський лей', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '498', 0, NULL, '100001', 'MDL', 'молдовський лей', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '975', 0, NULL, '100001', 'BGN', 'болгарський лев', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '156', 0, NULL, '100001', 'CNY', 'китайський юань', NULL, NULL, 2, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '949', 0, NULL, '100001', 'TRY', 'турецька ліра', NULL, NULL, 2, '', '', '' );
update item set itemnote='' ;
update item set itemnote='0' where pkey='980';
update item set itemnote='10' where pkey='840';
update item set itemnote='15' where pkey='978';
update item set itemnote='20' where pkey='985';
update item set itemnote='23' where pkey='203';
update item set itemnote='26' where pkey='826';
update item set itemnote='52' where pkey='124';
update item set itemnote='54' where pkey='756';
update item set itemnote='56' where pkey='036';
update item set itemnote='58' where pkey='752';
update item set itemnote='60' where pkey='578';
update item set itemnote='62' where pkey='208';
update item set itemnote='72' where pkey='348';
update item set itemnote='74' where pkey='975';
update item set itemnote='75' where pkey='946';
update item set itemnote='76' where pkey='949';
update item set itemnote='78' where pkey='156';
update item set itemnote='80' where pkey='392';

INSERT INTO "itemunit" ("pkey","unitchar","parentid","unitprec","unitname","parentqtty","code") VALUES ( 'pc', 'шт', NULL, 0, 'штук', NULL, '2009' );
INSERT INTO "itemunit" ("pkey","unitchar","parentid","unitprec","unitname","parentqtty","code") VALUES ( 'm', 'м', NULL, 2, 'метр', NULL, '0101' );
INSERT INTO "itemunit" ("pkey","unitchar","parentid","unitprec","unitname","parentqtty","code") VALUES ( 'kg', 'кг', NULL, 3, 'кілограм', NULL, '0301' );

INSERT INTO "articlepriceqty" ("pkey","qty") VALUES ( '643', 10 );
INSERT INTO "articlepriceqty" ("pkey","qty") VALUES ( '348', 100 );


COMMIT;
