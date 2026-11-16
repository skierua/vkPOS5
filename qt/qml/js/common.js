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

// QML object stringify
function safeStringify(obj) {
    const seen = new WeakSet();
    return JSON.stringify(obj, (key, value) => {
        // Skip common QML cyclic references if present
        if (key === 'parent' || key === 'children' || key === 'window') {
            return undefined;
        }
        if (typeof value === "object" && value !== null) {
            if (seen.has(value)) {
                return "[Circular]"; // Replace circular reference with a string tag
            }
            seen.add(value);
        }
        return value;
    }, 2);
}