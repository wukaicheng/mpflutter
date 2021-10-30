var dictCSSKeys = ["_","position","top","left","width","height","z-index","border-radius","overflow","background-color","display", "user-select", "-webkit-user-select", "text-align", "-webkit-line-clamp", "opacity", "max-width", "max-height"];
var dictCSSValues = {"_1":"absolute","_2":"unset","_3":"start"};
var style = function(params) {
    var output = "";
    if (!params) return output;
    for (var i = 0; i < dictCSSKeys.length; i++) {
        if (params[i.toString()] !== undefined) {
            if (dictCSSValues[params[i.toString()]]) {
                output += dictCSSKeys[i] + ":" + dictCSSValues[params[i.toString()]] + ';';
            }
            else {
                output += dictCSSKeys[i] + ":" + params[i.toString()] + ';';
            }
        }
        else if (params[dictCSSKeys[i]] !== undefined) {
            output += dictCSSKeys[i] + ":" + params[dictCSSKeys[i]] + ';';
        }
    }
    if (params.other) {
        output += params.other;
    }
    return output;
}
var tag = function(value) {
    if (value) {
        return value;
    }
    else {
        return 'div';
    }
}
export default {
    style: style,
    tag: tag,
};