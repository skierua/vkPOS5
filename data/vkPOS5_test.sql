--
-- populate vkPOS5 version 14.7 database
-- 
--
-- PRAGMA foreign_keys = ON;
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;


-- INSERT INTO "settings" ("domcur","domchar","domname","dbversion","branchname","branchname2","branchaddres","acnts") VALUES ( '980', 'UAH', 'українська гривня', '14.7', '', '', '', '{ "cash":"3000", "incas":"3003", "trade":"3500", "bulk":"3501",  "profit":"3607-55" }' );

-- INSERT INTO "shift" ("id","shftdate","shftbegin","shftend","cshr") VALUES ( 1, '2024-12-04', '2024-12-04', '', '' );

-- INSERT INTO "client" ("pkey","clchar","phone","clnote","inptime") VALUES ( '1000', 'Фіз.особа', NULL, NULL, '' );
INSERT INTO "client" ("pkey","clchar","phone","clnote") VALUES ( '1001', 'client Roger', NULL, 'uncle Roger');
INSERT INTO "client" ("pkey","clchar","phone","clnote") VALUES ( '1002', 'Bob Marley', NULL, 'greate signer');
INSERT INTO "client" ("pkey","clchar","phone","clnote") VALUES ( '1003', 'Василь', '1234567890', 'сусід');

-- INSERT INTO "dcmtype" ("pkey","dctpchar","dctpname","tranable") VALUES ( 'check', 'ТОРГ:ЧЕК', NULL, 0 );

-- INSERT INTO "balname" ("bal","balname","articlemask","trade") VALUES ( '30', 'Залишок', 7, 0 );

-- INSERT INTO "acntbal" ("acntno","client","acntnote","mask","trade") VALUES ( '36001000', '1000', NULL, 7, 0 );

-- INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '980', 0, NULL, NULL, 'UAH', 'українська гривня', NULL, NULL, 1, '', '', '' );
-- INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '100001', 1, NULL, NULL, 'ІНОЗ.ВАЛЮТА', 'Іноземна валюти та ін.', NULL, NULL, 2, '', '', '' );
-- INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '100002', 1, NULL, NULL, 'ТОВАР', 'Товари', NULL, NULL, 4, '', '', '' );
-- INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc") VALUES ( '100003', 1, NULL, NULL, 'ПОСЛУГИ', 'Послуги', NULL, NULL, 8, '', '', '' );

INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc")
VALUES ( '200000', 0, '9001531181597 9001531181599', '100002', 'товар тест1 pc', 'товар тест1 повна назва pc', 'повний опис товару pc', 'pc', 4, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc")
VALUES ( '200001', 0, '4820004237860', '100002', 'тестовий товар 2 m', 'товар тест2 кабель повна назва pc', 'якийсь кабель повний опис товару m', 'm', 4, '', '', '' );
INSERT INTO "item" ("pkey","folder","scancode","parentid","itemchar","itemname","itemnote","defunit","itemmask","uktzed","taxchar","taxprc")
VALUES ( '200002', 0, '4820132583648', '100002', 'для тесту 3 кг', 'товар тест3 крупа повна назва кг', 'рандомна крупа повний опис товару кг', 'kg', 4, '', '', '' );

-- INSERT INTO "articlepriceqty" ("pkey","qty") VALUES ( '348', 100 );


COMMIT;
