.pragma library

function parse(raw){
    try {
        return JSON.parse(raw);
    } catch (err) {
        return null;
    }
}

const  buildWhereClause = (conditionsArray) => {
    if (!conditionsArray || conditionsArray.length === 0) return "";
    return "WHERE " + conditionsArray.join(" AND ");
}
