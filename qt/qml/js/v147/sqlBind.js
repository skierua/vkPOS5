.pragma library

function parse(raw){
    try {
        return JSON.parse(raw);
    } catch (err) {
        return null;
    }
}

// used for printing
function dbBind(db, bindid) {
    let tbl = "docum";
    const stmt = `
    SELECT
        id,
        dcmtype,
        amount,
        coalesce(eqamount,0) eq,
        coalesce(discount,0) dsc,
        coalesce(dcmnote,itemchar,'') note,
        dcmtime,
        coalesce(itemchar,'ГРН') ichar,
        coalesce(itemname,'') iname,
        coalesce(itemmask,1) mask,
        coalesce(unitprec,2) prec,
        coalesce(itemunit.code,'') ucode,
        coalesce(unitchar,'') uchar,
        coalesce(qty,1) qty,
        coalesce(term,0) term,
        coalesce(item.pkey,'') iid,
        coalesce(dcmno,'') dcmno
    `;

    const vsql = String("select id, dcmtype, amount,coalesce(eqamount,0) eq,coalesce(discount,0) dsc, coalesce(dcmnote,itemchar,'') note, dcmtime, coalesce(itemchar,'ГРН') ichar, coalesce(' ('||itemname||')','') iname, " + "coalesce(itemmask,1) mask, coalesce(unitprec,2) prec, coalesce(itemunit.code,'') ucode, coalesce(unitchar,'') uchar, coalesce(qty,1) qty, coalesce(term,0) term, coalesce(item.pkey,'') iid, coalesce(dcmno,'') dcmno " + "from %1 left join item on (item=item.pkey) left join itemunit on (defunit=itemunit.pkey) left join articlepriceqty on (item=articlepriceqty.pkey) " + "left join warranty on (item=warranty.article) ");
    const fltBind = String(" where %1.id = %2;");
    let jbind = db.dbSelectRow(vsql.arg(tbl) + fltBind.arg(tbl).arg(bindid));
    // log("#2w44 printCheck " + JSON.stringify(jbind))
    if (jbind.errid === 1) {
        tbl = "documall";
        jbind = db.dbSelectRow(vsql.arg(tbl) + fltBind.arg(tbl).arg(bindid));
        if (jbind.errid === 1) {
            // error
            log(jbind.errname, "lib.printCheck", "EE");
            // cb(jbind.errname)
            return false;
        }
    }
    const fltDcm = String(" where %1.parentid = %2;");
    const jdcm = parse(db.dbSelectRows(vsql.arg(tbl) + fltDcm.arg(tbl).arg(bindid)));
    // log("#2w44 printCheck " + (vsql.arg(tbl) + fltDcm.arg(tbl).arg(id)))
    // log("#898 printCheck " + JSON.stringify(jdcm))
    if (!jdcm) {
        jbind.errid = 1;
        jbind.errname = "Bind documents not found";
        // log("Bind documents not found","lib.printCheck", "EE")
        // cb(jbind.errname);
        return false;
    }
    jbind.dcms = jdcm.rows;

    // log("#898 printCheck " + JSON.stringify(jbind))
    // cb(null, jbind)
    return jbind;
}

function selStmt(archive) {
    const isArchive = !!archive;
    const tbl = isArchive ? "strgdocum" : "docum";
    const fldShift = isArchive ? "shftid" : "0 AS shftid";
    const fldDcmid = isArchive ? "dcmid" : "id AS dcmid";

    // ✅ ВИПРАВЛЕНО: Додано префікси ${tbl}. до всіх рідних полів документів,
    // щоб уникнути помилки "ambiguous column name", якщо такі ж поля є в таблиці item
    return `
    SELECT
        ${fldShift},
        ${fldDcmid},
        ${tbl}.parentid AS pid,
        ${tbl}.dcmno,
        ${tbl}.dcmtype,
        ${tbl}.item AS itemid,
        ${tbl}.acntdbt,
        ${tbl}.acntcdt,
        ${tbl}.amount,
        ${tbl}.eqamount,
        ${tbl}.discount,
        ${tbl}.bonus,
        ${tbl}.client AS clid,
        ${tbl}.dcmnote,
        ${tbl}.dcmtime,
        ${tbl}.dcmaker,
        ${tbl}.retfor
    FROM ${tbl}
    `;
    // ,unitprec,
    // itemunit.code AS unitcode,
    // unitchar,
    // coalesce(itemmask, 1) AS mask,
    // itemchar
    // LEFT JOIN item ON (${tbl}.item = item.pkey)
    // LEFT JOIN itemunit ON (defunit = itemunit.pkey)
}

// Безпечний пошук одного документа
function selDcmById(db, dcmid, archive) {
    if (!db) return null;
    const isArchive = !!archive;

    const cleanId = parseInt(dcmid, 10) || 0;
    const fldName = isArchive ? "dcmid" : "id";

    const vsql = `${selStmt(isArchive)} WHERE ${fldName} = ${cleanId}`;
    return db.dbSelectRow(vsql);
}

// Безпечний вибір масиву рядків за Parent ID
function selDcmsByPid(db, pid, archive) {
    if (!db) return null;
    const isArchive = !!archive;

    const cleanPid = parseInt(pid, 10) || 0;
    const tbl = isArchive ? "strgdocum" : "docum";

    const vsql = `${selStmt(isArchive)} WHERE ${tbl}.parentid = ${cleanPid}`;
    return db.dbSelectRowsJSON(vsql);
}

// Пошук за кастомною SQL-умовою
function dbDocum(db, condition, archive) {
    if (!db) return null;
    const isArchive = !!archive;

    const whereCondition = condition ? `WHERE ${condition}` : "";
    const vsql = `${selStmt(isArchive)} ${whereCondition}`;
    // console.info(`II:sqlBind.js/dbDocum ${vsql}` );
    return db.dbSelectRowsJSON(vsql);
}

// client, acntno, article
// tmFrom
// dcmview.js
function selList(db, bindOnly,  param){
    // console.info(`II:#7yy sqlBind.js/selBindList param=${JSON.stringify(param)}`);
    const crntVal = !bindOnly ? "parentid" : "id";
    const strgVal = !bindOnly ? "parentid" : "dcmid";
    let dataFilter = "";
    let timeFilter = "";
    let archive = true;
    let crntTblFilter = "";
    let strgTblFilter = "";
    let whereCondition = "";
    // if (String(param?.shft || )

    if (param.tmFrom !== undefined && param.tmFrom !== null){
        if (param.tmFrom === "last2Week") timeFilter = "date(dcmtime) >= date('now', '-14 day')";
        else if (param.tmFrom === "last1Month") timeFilter = "date(dcmtime) >= date('now', '-1 month')";
        else if (param.tmFrom === "last3Month") timeFilter = "date(dcmtime) >= date('now', '-3 month')";
        else if (param.tmFrom === "last1Year") timeFilter = "date(dcmtime) >= date('now', '-1 year')";
        else if (param.tmFrom === "startOfMonth") timeFilter = "date(dcmtime) >= date('now', 'start of month')";
        else if (param.tmFrom === "startOfYear") timeFilter = "date(dcmtime) >= date('now', 'start of year')";
        else if (param.tmFrom === "all") timeFilter = "";
        else archive = false;
    } else archive = false;

    if (param.acntno) {
        whereCondition = `WHERE (acntcdt = '${param.acntno}') ${!!timeFilter ? 'AND' : ''} ${timeFilter}`;
        crntTblFilter = `
            ${crntVal} IN (
            SELECT DISTINCT parentid
            FROM docum
            ${whereCondition}
            )`;
        strgTblFilter = `
            ${strgVal} IN (
            SELECT DISTINCT parentid
            FROM strgdocum
            ${whereCondition}
            )`;
    } else if (param.article !== undefined){
        // console.info(`II: sqlBind.js/selBindList ATCL is defined`);
        dataFilter = !String(param?.article ?? "") ? "(item IS NULL OR item = '')"
                              : `(item = '${String(param.article)}')`;
        whereCondition = `WHERE ${dataFilter} ${!!timeFilter ? 'AND' : ''} ${timeFilter}`;
        crntTblFilter = `
            ${crntVal} IN (
            SELECT DISTINCT parentid
            FROM docum
            ${whereCondition}
            )`;
        strgTblFilter = `
            ${strgVal} IN (
            SELECT DISTINCT parentid
            FROM strgdocum
            ${whereCondition}
            )`;
    } else if (param.client !== undefined){
        const clid = param.client ?? "";
        crntTblFilter = `
            ${crntVal} IN (
        SELECT DISTINCT parentid FROM docum WHERE acntcdt IN (SELECT acntno FROM acntbal WHERE client = '${clid}')
         ${!!timeFilter ? 'AND' : ''} ${timeFilter}
        UNION
        SELECT dcmid FROM docum WHERE (parentid IS NULL OR parentid = '') AND client = '${clid}' ${!!timeFilter ? 'AND' : ''} ${timeFilter}
            )`;

        strgTblFilter = `
            ${strgVal} IN (
        SELECT DISTINCT parentid FROM strgdocum WHERE acntcdt IN (SELECT acntno FROM acntbal WHERE client = '${clid}')
         ${!!timeFilter ? 'AND' : ''} ${timeFilter}
        UNION
        SELECT dcmid FROM strgdocum WHERE (parentid IS NULL OR parentid = '') AND client = '${clid}' ${!!timeFilter ? 'AND' : ''} ${timeFilter}
            )`;

    } else {
        if (!bindOnly){
            crntTblFilter = `(parentid IS NOT NULL AND parentid != '') ${!!timeFilter ? 'AND' : ''} ${timeFilter}`;
            strgTblFilter = crntTblFilter;
        } else {
            crntTblFilter = `(parentid IS NULL OR parentid = '') ${!!timeFilter ? 'AND' : ''} ${timeFilter}`;
            strgTblFilter = crntTblFilter;
        }
    }

    // console.info(`II: sqlBind.js/selBindList dataFilter=${crntTblFilter}`);
    const source1 = dbDocum(db, crntTblFilter, false);
    if (archive){
        // console.info(`II: sqlBind.js/selBindList dataFilter=${strgTblFilter}`);
        const source2 = dbDocum(db, strgTblFilter, true);
        if (source2.length > 65000) {
            const res = source1.concat(source2);
            return res ?? [];
        }
        source1.push(...source2);
    }
    return source1 ?? [];
}


function updDocum(db, dcmid, updateFields, archive) {
    if (!db || !dcmid || !updateFields) return false;

    const isArchive = !!archive; // примусове приведення до boolean
    const tbl = isArchive ? "strgdocum" : "docum";
    const fldName = (isArchive ? "dcmid" : "id");

    let setParts = [];
    let params = { ":condition_id": dcmid };

    // Пробігаємося по полях, які треба оновити
    Object.keys(updateFields).forEach(key => {
        if (updateFields.hasOwnProperty(key)) {
            setParts.push(`${key} = :${key}`);
            params[`:${key}`] = updateFields[key];
        }
    });

    const usql = `UPDATE ${tbl} SET ${setParts.join(", ")} WHERE ${fldName} = :condition_id`;
    // console.log(`dh6g#sqlBind ${usql} \nparam=${JSON.stringify(params)}`); return;
    return db.dbUpdate(usql, params);
}


