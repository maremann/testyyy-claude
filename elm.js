(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}

console.warn('Compiled in DEV mode. Follow the advice at https://elm-lang.org/0.19.1/optimize for better performance and smaller assets.');


// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**_UNUSED/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**_UNUSED/
	if (typeof x.$ === 'undefined')
	//*/
	/**/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0_UNUSED = 0;
var _Utils_Tuple0 = { $: '#0' };

function _Utils_Tuple2_UNUSED(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3_UNUSED(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr_UNUSED(c) { return c; }
function _Utils_chr(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil_UNUSED = { $: 0 };
var _List_Nil = { $: '[]' };

function _List_Cons_UNUSED(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log_UNUSED = F2(function(tag, value)
{
	return value;
});

var _Debug_log = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString_UNUSED(value)
{
	return '<internals>';
}

function _Debug_toString(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash_UNUSED(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.start.line === region.end.line)
	{
		return 'on line ' + region.start.line;
	}
	return 'on lines ' + region.start.line + ' through ' + region.end.line;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (Object.prototype.hasOwnProperty.call(value, key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap(value) { return { $: 0, a: value }; }
function _Json_unwrap(value) { return value.a; }

function _Json_wrap_UNUSED(value) { return value; }
function _Json_unwrap_UNUSED(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	var unwrapped = _Json_unwrap(value);
	if (!(key === 'toJSON' && typeof unwrapped === 'function'))
	{
		object[key] = unwrapped;
	}
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**_UNUSED/
	var node = args['node'];
	//*/
	/**/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'outerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof _Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(_Json_unwrap(value)))
		? _Json_wrap(
			/**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		message: func(record.message),
		stopPropagation: record.stopPropagation,
		preventDefault: record.preventDefault
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.message;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.stopPropagation;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.preventDefault) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var view = impl.view;
			/**_UNUSED/
			var domNode = args['node'];
			//*/
			/**/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.setup && impl.setup(sendToApp)
			var view = impl.view;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.body);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.title) && (_VirtualDom_doc.title = title = doc.title);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.onUrlChange;
	var onUrlRequest = impl.onUrlRequest;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		setup: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.protocol === next.protocol
							&& curr.host === next.host
							&& curr.port_.a === next.port_.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		init: function(flags)
		{
			return A3(impl.init, flags, _Browser_getUrl(), key);
		},
		view: impl.view,
		update: impl.update,
		subscriptions: impl.subscriptions
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { hidden: 'hidden', change: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { hidden: 'mozHidden', change: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { hidden: 'msHidden', change: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { hidden: 'webkitHidden', change: 'webkitvisibilitychange' }
		: { hidden: 'hidden', change: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		scene: _Browser_getScene(),
		viewport: {
			x: _Browser_window.pageXOffset,
			y: _Browser_window.pageYOffset,
			width: _Browser_doc.documentElement.clientWidth,
			height: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		width: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		height: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			scene: {
				width: node.scrollWidth,
				height: node.scrollHeight
			},
			viewport: {
				x: node.scrollLeft,
				y: node.scrollTop,
				width: node.clientWidth,
				height: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			scene: _Browser_getScene(),
			viewport: {
				x: x,
				y: y,
				width: _Browser_doc.documentElement.clientWidth,
				height: _Browser_doc.documentElement.clientHeight
			},
			element: {
				x: x + rect.left,
				y: y + rect.top,
				width: rect.width,
				height: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}



var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});



function _Time_now(millisToPosix)
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(millisToPosix(Date.now())));
	});
}

var _Time_setInterval = F2(function(interval, task)
{
	return _Scheduler_binding(function(callback)
	{
		var id = setInterval(function() { _Scheduler_rawSpawn(task); }, interval);
		return function() { clearInterval(id); };
	});
});

function _Time_here()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(
			A2($elm$time$Time$customZone, -(new Date().getTimezoneOffset()), _List_Nil)
		));
	});
}


function _Time_getZoneName()
{
	return _Scheduler_binding(function(callback)
	{
		try
		{
			var name = $elm$time$Time$Name(Intl.DateTimeFormat().resolvedOptions().timeZone);
		}
		catch (e)
		{
			var name = $elm$time$Time$Offset(new Date().getTimezoneOffset());
		}
		callback(_Scheduler_succeed(name));
	});
}
var $elm$core$Basics$EQ = {$: 'EQ'};
var $elm$core$Basics$GT = {$: 'GT'};
var $elm$core$Basics$LT = {$: 'LT'};
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0.a;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (node.$ === 'SubTree') {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 'Err', a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 'Failure', a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 'Field', a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 'Index', a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 'Ok', a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 'OneOf', a: a};
};
var $elm$core$Basics$False = {$: 'False'};
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 'Just', a: a};
};
var $elm$core$Maybe$Nothing = {$: 'Nothing'};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 'Field':
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 'Nothing') {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'Index':
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'OneOf':
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 'Array_elm_builtin', a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 'Leaf', a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 'SubTree', a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.nodeListSize) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.tail);
		} else {
			var treeLen = builder.nodeListSize * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.nodeList) : builder.nodeList;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.nodeListSize);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.tail);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{nodeList: nodeList, nodeListSize: (len / $elm$core$Array$branchFactor) | 0, tail: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = {$: 'True'};
var $elm$core$Result$isOk = function (result) {
	if (result.$ === 'Ok') {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 'Normal':
			return 0;
		case 'MayStopPropagation':
			return 1;
		case 'MayPreventDefault':
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 'External', a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 'Internal', a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = function (a) {
	return {$: 'NotFound', a: a};
};
var $elm$url$Url$Http = {$: 'Http'};
var $elm$url$Url$Https = {$: 'Https'};
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {fragment: fragment, host: host, path: path, port_: port_, protocol: protocol, query: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 'Nothing') {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Http,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Https,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0.a;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = function (a) {
	return {$: 'Perform', a: a};
};
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(_Utils_Tuple0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0.a;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return _Utils_Tuple0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(_Utils_Tuple0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0.a;
		return $elm$core$Task$Perform(
			A2($elm$core$Task$map, tagger, task));
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2($elm$core$Task$map, toMessage, task)));
	});
var $elm$browser$Browser$element = _Browser_element;
var $author$project$Message$GotViewport = function (a) {
	return {$: 'GotViewport', a: a};
};
var $author$project$Types$MainTab = {$: 'MainTab'};
var $author$project$Types$NotDragging = {$: 'NotDragging'};
var $author$project$Types$PreGame = {$: 'PreGame'};
var $author$project$Message$ShapesGenerated = function (a) {
	return {$: 'ShapesGenerated', a: a};
};
var $author$project$Types$Speed1x = {$: 'Speed1x'};
var $author$project$Types$StatsTab = {$: 'StatsTab'};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Dict$RBEmpty_elm_builtin = {$: 'RBEmpty_elm_builtin'};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$random$Random$Generate = function (a) {
	return {$: 'Generate', a: a};
};
var $elm$random$Random$Seed = F2(
	function (a, b) {
		return {$: 'Seed', a: a, b: b};
	});
var $elm$core$Bitwise$shiftRightZfBy = _Bitwise_shiftRightZfBy;
var $elm$random$Random$next = function (_v0) {
	var state0 = _v0.a;
	var incr = _v0.b;
	return A2($elm$random$Random$Seed, ((state0 * 1664525) + incr) >>> 0, incr);
};
var $elm$random$Random$initialSeed = function (x) {
	var _v0 = $elm$random$Random$next(
		A2($elm$random$Random$Seed, 0, 1013904223));
	var state1 = _v0.a;
	var incr = _v0.b;
	var state2 = (state1 + x) >>> 0;
	return $elm$random$Random$next(
		A2($elm$random$Random$Seed, state2, incr));
};
var $elm$time$Time$Name = function (a) {
	return {$: 'Name', a: a};
};
var $elm$time$Time$Offset = function (a) {
	return {$: 'Offset', a: a};
};
var $elm$time$Time$Zone = F2(
	function (a, b) {
		return {$: 'Zone', a: a, b: b};
	});
var $elm$time$Time$customZone = $elm$time$Time$Zone;
var $elm$time$Time$Posix = function (a) {
	return {$: 'Posix', a: a};
};
var $elm$time$Time$millisToPosix = $elm$time$Time$Posix;
var $elm$time$Time$now = _Time_now($elm$time$Time$millisToPosix);
var $elm$time$Time$posixToMillis = function (_v0) {
	var millis = _v0.a;
	return millis;
};
var $elm$random$Random$init = A2(
	$elm$core$Task$andThen,
	function (time) {
		return $elm$core$Task$succeed(
			$elm$random$Random$initialSeed(
				$elm$time$Time$posixToMillis(time)));
	},
	$elm$time$Time$now);
var $elm$random$Random$step = F2(
	function (_v0, seed) {
		var generator = _v0.a;
		return generator(seed);
	});
var $elm$random$Random$onEffects = F3(
	function (router, commands, seed) {
		if (!commands.b) {
			return $elm$core$Task$succeed(seed);
		} else {
			var generator = commands.a.a;
			var rest = commands.b;
			var _v1 = A2($elm$random$Random$step, generator, seed);
			var value = _v1.a;
			var newSeed = _v1.b;
			return A2(
				$elm$core$Task$andThen,
				function (_v2) {
					return A3($elm$random$Random$onEffects, router, rest, newSeed);
				},
				A2($elm$core$Platform$sendToApp, router, value));
		}
	});
var $elm$random$Random$onSelfMsg = F3(
	function (_v0, _v1, seed) {
		return $elm$core$Task$succeed(seed);
	});
var $elm$random$Random$Generator = function (a) {
	return {$: 'Generator', a: a};
};
var $elm$random$Random$map = F2(
	function (func, _v0) {
		var genA = _v0.a;
		return $elm$random$Random$Generator(
			function (seed0) {
				var _v1 = genA(seed0);
				var a = _v1.a;
				var seed1 = _v1.b;
				return _Utils_Tuple2(
					func(a),
					seed1);
			});
	});
var $elm$random$Random$cmdMap = F2(
	function (func, _v0) {
		var generator = _v0.a;
		return $elm$random$Random$Generate(
			A2($elm$random$Random$map, func, generator));
	});
_Platform_effectManagers['Random'] = _Platform_createManager($elm$random$Random$init, $elm$random$Random$onEffects, $elm$random$Random$onSelfMsg, $elm$random$Random$cmdMap);
var $elm$random$Random$command = _Platform_leaf('Random');
var $elm$random$Random$generate = F2(
	function (tagger, generator) {
		return $elm$random$Random$command(
			$elm$random$Random$Generate(
				A2($elm$random$Random$map, tagger, generator)));
	});
var $author$project$Types$DecorativeShape = F5(
	function (x, y, size, shapeType, color) {
		return {color: color, shapeType: shapeType, size: size, x: x, y: y};
	});
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $elm$core$Bitwise$and = _Bitwise_and;
var $elm$core$Bitwise$xor = _Bitwise_xor;
var $elm$random$Random$peel = function (_v0) {
	var state = _v0.a;
	var word = (state ^ (state >>> ((state >>> 28) + 4))) * 277803737;
	return ((word >>> 22) ^ word) >>> 0;
};
var $elm$random$Random$float = F2(
	function (a, b) {
		return $elm$random$Random$Generator(
			function (seed0) {
				var seed1 = $elm$random$Random$next(seed0);
				var range = $elm$core$Basics$abs(b - a);
				var n1 = $elm$random$Random$peel(seed1);
				var n0 = $elm$random$Random$peel(seed0);
				var lo = (134217727 & n1) * 1.0;
				var hi = (67108863 & n0) * 1.0;
				var val = ((hi * 134217728.0) + lo) / 9007199254740992.0;
				var scaled = (val * range) + a;
				return _Utils_Tuple2(
					scaled,
					$elm$random$Random$next(seed1));
			});
	});
var $elm$random$Random$addOne = function (value) {
	return _Utils_Tuple2(1, value);
};
var $elm$random$Random$getByWeight = F3(
	function (_v0, others, countdown) {
		getByWeight:
		while (true) {
			var weight = _v0.a;
			var value = _v0.b;
			if (!others.b) {
				return value;
			} else {
				var second = others.a;
				var otherOthers = others.b;
				if (_Utils_cmp(
					countdown,
					$elm$core$Basics$abs(weight)) < 1) {
					return value;
				} else {
					var $temp$_v0 = second,
						$temp$others = otherOthers,
						$temp$countdown = countdown - $elm$core$Basics$abs(weight);
					_v0 = $temp$_v0;
					others = $temp$others;
					countdown = $temp$countdown;
					continue getByWeight;
				}
			}
		}
	});
var $elm$core$List$sum = function (numbers) {
	return A3($elm$core$List$foldl, $elm$core$Basics$add, 0, numbers);
};
var $elm$random$Random$weighted = F2(
	function (first, others) {
		var normalize = function (_v0) {
			var weight = _v0.a;
			return $elm$core$Basics$abs(weight);
		};
		var total = normalize(first) + $elm$core$List$sum(
			A2($elm$core$List$map, normalize, others));
		return A2(
			$elm$random$Random$map,
			A2($elm$random$Random$getByWeight, first, others),
			A2($elm$random$Random$float, 0, total));
	});
var $elm$random$Random$uniform = F2(
	function (value, valueList) {
		return A2(
			$elm$random$Random$weighted,
			$elm$random$Random$addOne(value),
			A2($elm$core$List$map, $elm$random$Random$addOne, valueList));
	});
var $author$project$Update$generateColor = A2(
	$elm$random$Random$uniform,
	'#8B4513',
	_List_fromArray(
		['#A0522D', '#D2691E', '#CD853F', '#DEB887', '#228B22', '#006400']));
var $author$project$Types$Circle = {$: 'Circle'};
var $author$project$Types$Rectangle = {$: 'Rectangle'};
var $author$project$Update$generateShapeType = A2(
	$elm$random$Random$uniform,
	$author$project$Types$Circle,
	_List_fromArray(
		[$author$project$Types$Rectangle]));
var $elm$random$Random$map5 = F6(
	function (func, _v0, _v1, _v2, _v3, _v4) {
		var genA = _v0.a;
		var genB = _v1.a;
		var genC = _v2.a;
		var genD = _v3.a;
		var genE = _v4.a;
		return $elm$random$Random$Generator(
			function (seed0) {
				var _v5 = genA(seed0);
				var a = _v5.a;
				var seed1 = _v5.b;
				var _v6 = genB(seed1);
				var b = _v6.a;
				var seed2 = _v6.b;
				var _v7 = genC(seed2);
				var c = _v7.a;
				var seed3 = _v7.b;
				var _v8 = genD(seed3);
				var d = _v8.a;
				var seed4 = _v8.b;
				var _v9 = genE(seed4);
				var e = _v9.a;
				var seed5 = _v9.b;
				return _Utils_Tuple2(
					A5(func, a, b, c, d, e),
					seed5);
			});
	});
var $author$project$Update$generateShape = function (config) {
	return A6(
		$elm$random$Random$map5,
		$author$project$Types$DecorativeShape,
		A2($elm$random$Random$float, 0, config.width),
		A2($elm$random$Random$float, 0, config.height),
		A2($elm$random$Random$float, 20, 80),
		$author$project$Update$generateShapeType,
		$author$project$Update$generateColor);
};
var $elm$random$Random$listHelp = F4(
	function (revList, n, gen, seed) {
		listHelp:
		while (true) {
			if (n < 1) {
				return _Utils_Tuple2(revList, seed);
			} else {
				var _v0 = gen(seed);
				var value = _v0.a;
				var newSeed = _v0.b;
				var $temp$revList = A2($elm$core$List$cons, value, revList),
					$temp$n = n - 1,
					$temp$gen = gen,
					$temp$seed = newSeed;
				revList = $temp$revList;
				n = $temp$n;
				gen = $temp$gen;
				seed = $temp$seed;
				continue listHelp;
			}
		}
	});
var $elm$random$Random$list = F2(
	function (n, _v0) {
		var gen = _v0.a;
		return $elm$random$Random$Generator(
			function (seed) {
				return A4($elm$random$Random$listHelp, _List_Nil, n, gen, seed);
			});
	});
var $author$project$Update$generateShapes = F2(
	function (count, config) {
		return A2(
			$elm$random$Random$list,
			count,
			$author$project$Update$generateShape(config));
	});
var $elm$browser$Browser$Dom$getViewport = _Browser_withWindow(_Browser_getViewport);
var $author$project$Update$init = function (_v0) {
	var mapConfig = {boundary: 500, height: 4992, width: 4992};
	var gridConfig = {buildGridSize: 64, pathfindingGridSize: 32};
	var initialModel = {
		accumulatedTime: 0,
		buildMode: $elm$core$Maybe$Nothing,
		buildingOccupancy: $elm$core$Dict$empty,
		buildingTab: $author$project$Types$MainTab,
		buildings: _List_Nil,
		camera: {x: 2496, y: 2496},
		debugTab: $author$project$Types$StatsTab,
		decorativeShapes: _List_Nil,
		dragState: $author$project$Types$NotDragging,
		gameState: $author$project$Types$PreGame,
		gold: 50000,
		goldInputValue: '',
		gridConfig: gridConfig,
		lastSimulationDeltas: _List_Nil,
		mapConfig: mapConfig,
		mouseWorldPos: $elm$core$Maybe$Nothing,
		nextBuildingId: 1,
		nextUnitId: 1,
		pathfindingOccupancy: $elm$core$Dict$empty,
		selected: $elm$core$Maybe$Nothing,
		showBuildGrid: false,
		showBuildingOccupancy: false,
		showCityActiveArea: false,
		showCitySearchArea: false,
		showPathfindingGrid: false,
		showPathfindingOccupancy: false,
		simulationFrameCount: 0,
		simulationSpeed: $author$project$Types$Speed1x,
		tooltipHover: $elm$core$Maybe$Nothing,
		units: _List_Nil,
		windowSize: _Utils_Tuple2(800, 600)
	};
	return _Utils_Tuple2(
		initialModel,
		$elm$core$Platform$Cmd$batch(
			_List_fromArray(
				[
					A2(
					$elm$random$Random$generate,
					$author$project$Message$ShapesGenerated,
					A2($author$project$Update$generateShapes, 150, mapConfig)),
					A2($elm$core$Task$perform, $author$project$Message$GotViewport, $elm$browser$Browser$Dom$getViewport)
				])));
};
var $author$project$Message$Frame = function (a) {
	return {$: 'Frame', a: a};
};
var $author$project$Message$MinimapMouseMove = F2(
	function (a, b) {
		return {$: 'MinimapMouseMove', a: a, b: b};
	});
var $author$project$Message$MouseMove = F2(
	function (a, b) {
		return {$: 'MouseMove', a: a, b: b};
	});
var $author$project$Message$MouseUp = {$: 'MouseUp'};
var $author$project$Message$WindowResize = F2(
	function (a, b) {
		return {$: 'WindowResize', a: a, b: b};
	});
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $elm$browser$Browser$AnimationManager$Delta = function (a) {
	return {$: 'Delta', a: a};
};
var $elm$browser$Browser$AnimationManager$State = F3(
	function (subs, request, oldTime) {
		return {oldTime: oldTime, request: request, subs: subs};
	});
var $elm$browser$Browser$AnimationManager$init = $elm$core$Task$succeed(
	A3($elm$browser$Browser$AnimationManager$State, _List_Nil, $elm$core$Maybe$Nothing, 0));
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$browser$Browser$AnimationManager$now = _Browser_now(_Utils_Tuple0);
var $elm$browser$Browser$AnimationManager$rAF = _Browser_rAF(_Utils_Tuple0);
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$core$Process$spawn = _Scheduler_spawn;
var $elm$browser$Browser$AnimationManager$onEffects = F3(
	function (router, subs, _v0) {
		var request = _v0.request;
		var oldTime = _v0.oldTime;
		var _v1 = _Utils_Tuple2(request, subs);
		if (_v1.a.$ === 'Nothing') {
			if (!_v1.b.b) {
				var _v2 = _v1.a;
				return $elm$browser$Browser$AnimationManager$init;
			} else {
				var _v4 = _v1.a;
				return A2(
					$elm$core$Task$andThen,
					function (pid) {
						return A2(
							$elm$core$Task$andThen,
							function (time) {
								return $elm$core$Task$succeed(
									A3(
										$elm$browser$Browser$AnimationManager$State,
										subs,
										$elm$core$Maybe$Just(pid),
										time));
							},
							$elm$browser$Browser$AnimationManager$now);
					},
					$elm$core$Process$spawn(
						A2(
							$elm$core$Task$andThen,
							$elm$core$Platform$sendToSelf(router),
							$elm$browser$Browser$AnimationManager$rAF)));
			}
		} else {
			if (!_v1.b.b) {
				var pid = _v1.a.a;
				return A2(
					$elm$core$Task$andThen,
					function (_v3) {
						return $elm$browser$Browser$AnimationManager$init;
					},
					$elm$core$Process$kill(pid));
			} else {
				return $elm$core$Task$succeed(
					A3($elm$browser$Browser$AnimationManager$State, subs, request, oldTime));
			}
		}
	});
var $elm$browser$Browser$AnimationManager$onSelfMsg = F3(
	function (router, newTime, _v0) {
		var subs = _v0.subs;
		var oldTime = _v0.oldTime;
		var send = function (sub) {
			if (sub.$ === 'Time') {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(
						$elm$time$Time$millisToPosix(newTime)));
			} else {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(newTime - oldTime));
			}
		};
		return A2(
			$elm$core$Task$andThen,
			function (pid) {
				return A2(
					$elm$core$Task$andThen,
					function (_v1) {
						return $elm$core$Task$succeed(
							A3(
								$elm$browser$Browser$AnimationManager$State,
								subs,
								$elm$core$Maybe$Just(pid),
								newTime));
					},
					$elm$core$Task$sequence(
						A2($elm$core$List$map, send, subs)));
			},
			$elm$core$Process$spawn(
				A2(
					$elm$core$Task$andThen,
					$elm$core$Platform$sendToSelf(router),
					$elm$browser$Browser$AnimationManager$rAF)));
	});
var $elm$browser$Browser$AnimationManager$Time = function (a) {
	return {$: 'Time', a: a};
};
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $elm$browser$Browser$AnimationManager$subMap = F2(
	function (func, sub) {
		if (sub.$ === 'Time') {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Time(
				A2($elm$core$Basics$composeL, func, tagger));
		} else {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Delta(
				A2($elm$core$Basics$composeL, func, tagger));
		}
	});
_Platform_effectManagers['Browser.AnimationManager'] = _Platform_createManager($elm$browser$Browser$AnimationManager$init, $elm$browser$Browser$AnimationManager$onEffects, $elm$browser$Browser$AnimationManager$onSelfMsg, 0, $elm$browser$Browser$AnimationManager$subMap);
var $elm$browser$Browser$AnimationManager$subscription = _Platform_leaf('Browser.AnimationManager');
var $elm$browser$Browser$AnimationManager$onAnimationFrameDelta = function (tagger) {
	return $elm$browser$Browser$AnimationManager$subscription(
		$elm$browser$Browser$AnimationManager$Delta(tagger));
};
var $elm$browser$Browser$Events$onAnimationFrameDelta = $elm$browser$Browser$AnimationManager$onAnimationFrameDelta;
var $elm$browser$Browser$Events$Document = {$: 'Document'};
var $elm$browser$Browser$Events$MySub = F3(
	function (a, b, c) {
		return {$: 'MySub', a: a, b: b, c: c};
	});
var $elm$browser$Browser$Events$State = F2(
	function (subs, pids) {
		return {pids: pids, subs: subs};
	});
var $elm$browser$Browser$Events$init = $elm$core$Task$succeed(
	A2($elm$browser$Browser$Events$State, _List_Nil, $elm$core$Dict$empty));
var $elm$browser$Browser$Events$nodeToKey = function (node) {
	if (node.$ === 'Document') {
		return 'd_';
	} else {
		return 'w_';
	}
};
var $elm$browser$Browser$Events$addKey = function (sub) {
	var node = sub.a;
	var name = sub.b;
	return _Utils_Tuple2(
		_Utils_ap(
			$elm$browser$Browser$Events$nodeToKey(node),
			name),
		sub);
};
var $elm$core$Dict$Black = {$: 'Black'};
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: 'RBNode_elm_builtin', a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = {$: 'Red'};
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Red')) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) && (left.d.$ === 'RBNode_elm_builtin')) && (left.d.a.$ === 'Red')) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1.$) {
				case 'LT':
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 'EQ':
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $elm$browser$Browser$Events$Event = F2(
	function (key, event) {
		return {event: event, key: key};
	});
var $elm$browser$Browser$Events$spawn = F3(
	function (router, key, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var actualNode = function () {
			if (node.$ === 'Document') {
				return _Browser_doc;
			} else {
				return _Browser_window;
			}
		}();
		return A2(
			$elm$core$Task$map,
			function (value) {
				return _Utils_Tuple2(key, value);
			},
			A3(
				_Browser_on,
				actualNode,
				name,
				function (event) {
					return A2(
						$elm$core$Platform$sendToSelf,
						router,
						A2($elm$browser$Browser$Events$Event, key, event));
				}));
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $elm$browser$Browser$Events$onEffects = F3(
	function (router, subs, state) {
		var stepRight = F3(
			function (key, sub, _v6) {
				var deads = _v6.a;
				var lives = _v6.b;
				var news = _v6.c;
				return _Utils_Tuple3(
					deads,
					lives,
					A2(
						$elm$core$List$cons,
						A3($elm$browser$Browser$Events$spawn, router, key, sub),
						news));
			});
		var stepLeft = F3(
			function (_v4, pid, _v5) {
				var deads = _v5.a;
				var lives = _v5.b;
				var news = _v5.c;
				return _Utils_Tuple3(
					A2($elm$core$List$cons, pid, deads),
					lives,
					news);
			});
		var stepBoth = F4(
			function (key, pid, _v2, _v3) {
				var deads = _v3.a;
				var lives = _v3.b;
				var news = _v3.c;
				return _Utils_Tuple3(
					deads,
					A3($elm$core$Dict$insert, key, pid, lives),
					news);
			});
		var newSubs = A2($elm$core$List$map, $elm$browser$Browser$Events$addKey, subs);
		var _v0 = A6(
			$elm$core$Dict$merge,
			stepLeft,
			stepBoth,
			stepRight,
			state.pids,
			$elm$core$Dict$fromList(newSubs),
			_Utils_Tuple3(_List_Nil, $elm$core$Dict$empty, _List_Nil));
		var deadPids = _v0.a;
		var livePids = _v0.b;
		var makeNewPids = _v0.c;
		return A2(
			$elm$core$Task$andThen,
			function (pids) {
				return $elm$core$Task$succeed(
					A2(
						$elm$browser$Browser$Events$State,
						newSubs,
						A2(
							$elm$core$Dict$union,
							livePids,
							$elm$core$Dict$fromList(pids))));
			},
			A2(
				$elm$core$Task$andThen,
				function (_v1) {
					return $elm$core$Task$sequence(makeNewPids);
				},
				$elm$core$Task$sequence(
					A2($elm$core$List$map, $elm$core$Process$kill, deadPids))));
	});
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (_v0.$ === 'Just') {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$browser$Browser$Events$onSelfMsg = F3(
	function (router, _v0, state) {
		var key = _v0.key;
		var event = _v0.event;
		var toMessage = function (_v2) {
			var subKey = _v2.a;
			var _v3 = _v2.b;
			var node = _v3.a;
			var name = _v3.b;
			var decoder = _v3.c;
			return _Utils_eq(subKey, key) ? A2(_Browser_decodeEvent, decoder, event) : $elm$core$Maybe$Nothing;
		};
		var messages = A2($elm$core$List$filterMap, toMessage, state.subs);
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Platform$sendToApp(router),
					messages)));
	});
var $elm$browser$Browser$Events$subMap = F2(
	function (func, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var decoder = _v0.c;
		return A3(
			$elm$browser$Browser$Events$MySub,
			node,
			name,
			A2($elm$json$Json$Decode$map, func, decoder));
	});
_Platform_effectManagers['Browser.Events'] = _Platform_createManager($elm$browser$Browser$Events$init, $elm$browser$Browser$Events$onEffects, $elm$browser$Browser$Events$onSelfMsg, 0, $elm$browser$Browser$Events$subMap);
var $elm$browser$Browser$Events$subscription = _Platform_leaf('Browser.Events');
var $elm$browser$Browser$Events$on = F3(
	function (node, name, decoder) {
		return $elm$browser$Browser$Events$subscription(
			A3($elm$browser$Browser$Events$MySub, node, name, decoder));
	});
var $elm$browser$Browser$Events$onMouseMove = A2($elm$browser$Browser$Events$on, $elm$browser$Browser$Events$Document, 'mousemove');
var $elm$browser$Browser$Events$onMouseUp = A2($elm$browser$Browser$Events$on, $elm$browser$Browser$Events$Document, 'mouseup');
var $elm$browser$Browser$Events$Window = {$: 'Window'};
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $elm$browser$Browser$Events$onResize = function (func) {
	return A3(
		$elm$browser$Browser$Events$on,
		$elm$browser$Browser$Events$Window,
		'resize',
		A2(
			$elm$json$Json$Decode$field,
			'target',
			A3(
				$elm$json$Json$Decode$map2,
				func,
				A2($elm$json$Json$Decode$field, 'innerWidth', $elm$json$Json$Decode$int),
				A2($elm$json$Json$Decode$field, 'innerHeight', $elm$json$Json$Decode$int))));
};
var $author$project$Update$subscriptions = function (model) {
	var _v0 = model.dragState;
	switch (_v0.$) {
		case 'NotDragging':
			return $elm$core$Platform$Sub$batch(
				_List_fromArray(
					[
						$elm$browser$Browser$Events$onResize($author$project$Message$WindowResize),
						$elm$browser$Browser$Events$onAnimationFrameDelta($author$project$Message$Frame)
					]));
		case 'DraggingViewport':
			return $elm$core$Platform$Sub$batch(
				_List_fromArray(
					[
						$elm$browser$Browser$Events$onResize($author$project$Message$WindowResize),
						$elm$browser$Browser$Events$onMouseMove(
						A3(
							$elm$json$Json$Decode$map2,
							$author$project$Message$MouseMove,
							A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
							A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
						$elm$browser$Browser$Events$onMouseUp(
						$elm$json$Json$Decode$succeed($author$project$Message$MouseUp)),
						$elm$browser$Browser$Events$onAnimationFrameDelta($author$project$Message$Frame)
					]));
		default:
			return $elm$core$Platform$Sub$batch(
				_List_fromArray(
					[
						$elm$browser$Browser$Events$onResize($author$project$Message$WindowResize),
						$elm$browser$Browser$Events$onMouseMove(
						A3(
							$elm$json$Json$Decode$map2,
							$author$project$Message$MinimapMouseMove,
							A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
							A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
						$elm$browser$Browser$Events$onMouseUp(
						$elm$json$Json$Decode$succeed($author$project$Message$MouseUp)),
						$elm$browser$Browser$Events$onAnimationFrameDelta($author$project$Message$Frame)
					]));
	}
};
var $author$project$Types$BuildingTag = {$: 'BuildingTag'};
var $author$project$Types$CofferTag = {$: 'CofferTag'};
var $author$project$Types$DraggingMinimap = function (a) {
	return {$: 'DraggingMinimap', a: a};
};
var $author$project$Types$DraggingViewport = function (a) {
	return {$: 'DraggingViewport', a: a};
};
var $author$project$Types$GameOver = {$: 'GameOver'};
var $author$project$Types$GenerateGold = {$: 'GenerateGold'};
var $author$project$Types$GuildTag = {$: 'GuildTag'};
var $author$project$Types$Medium = {$: 'Medium'};
var $author$project$Types$ObjectiveTag = {$: 'ObjectiveTag'};
var $author$project$Types$Pause = {$: 'Pause'};
var $author$project$Types$Player = {$: 'Player'};
var $author$project$Types$Playing = {$: 'Playing'};
var $author$project$Types$SpawnHouse = {$: 'SpawnHouse'};
var $author$project$Types$UnderConstruction = {$: 'UnderConstruction'};
var $author$project$Types$buildingSizeToGridCells = function (size) {
	switch (size.$) {
		case 'Small':
			return 1;
		case 'Medium':
			return 2;
		case 'Large':
			return 3;
		default:
			return 4;
	}
};
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $author$project$Grid$getBuildingGridCells = function (building) {
	var sizeCells = $author$project$Types$buildingSizeToGridCells(building.size);
	var xs = A2($elm$core$List$range, building.gridX, (building.gridX + sizeCells) - 1);
	var ys = A2($elm$core$List$range, building.gridY, (building.gridY + sizeCells) - 1);
	return A2(
		$elm$core$List$concatMap,
		function (x) {
			return A2(
				$elm$core$List$map,
				function (y) {
					return _Utils_Tuple2(x, y);
				},
				ys);
		},
		xs);
};
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1.$) {
					case 'LT':
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 'EQ':
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.e.d.$ === 'RBNode_elm_builtin') && (dict.e.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.d.d.$ === 'RBNode_elm_builtin') && (dict.d.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Black')) {
					if (right.d.$ === 'RBNode_elm_builtin') {
						if (right.d.a.$ === 'Black') {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor.$ === 'Black') {
			if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === 'RBNode_elm_builtin') {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Black')) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === 'RBNode_elm_builtin') {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBNode_elm_builtin') {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === 'RBNode_elm_builtin') {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (_v0.$ === 'Just') {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $author$project$Grid$addBuildingGridOccupancy = F2(
	function (building, occupancy) {
		var incrementCell = F2(
			function (cell, dict) {
				return A3(
					$elm$core$Dict$update,
					cell,
					function (maybeCount) {
						if (maybeCount.$ === 'Just') {
							var count = maybeCount.a;
							return $elm$core$Maybe$Just(count + 1);
						} else {
							return $elm$core$Maybe$Just(1);
						}
					},
					dict);
			});
		var cells = $author$project$Grid$getBuildingGridCells(building);
		return A3($elm$core$List$foldl, incrementCell, occupancy, cells);
	});
var $author$project$Grid$getBuildingPathfindingCells = F2(
	function (gridConfig, building) {
		var buildingWorldY = building.gridY * gridConfig.buildGridSize;
		var startPfY = $elm$core$Basics$floor(buildingWorldY / gridConfig.pathfindingGridSize);
		var buildingWorldX = building.gridX * gridConfig.buildGridSize;
		var startPfX = $elm$core$Basics$floor(buildingWorldX / gridConfig.pathfindingGridSize);
		var buildingSizeCells = $author$project$Types$buildingSizeToGridCells(building.size);
		var buildingWorldHeight = buildingSizeCells * gridConfig.buildGridSize;
		var endPfY = $elm$core$Basics$floor(((buildingWorldY + buildingWorldHeight) - 1) / gridConfig.pathfindingGridSize);
		var ys = A2($elm$core$List$range, startPfY, endPfY);
		var buildingWorldWidth = buildingSizeCells * gridConfig.buildGridSize;
		var endPfX = $elm$core$Basics$floor(((buildingWorldX + buildingWorldWidth) - 1) / gridConfig.pathfindingGridSize);
		var xs = A2($elm$core$List$range, startPfX, endPfX);
		return A2(
			$elm$core$List$concatMap,
			function (x) {
				return A2(
					$elm$core$List$map,
					function (y) {
						return _Utils_Tuple2(x, y);
					},
					ys);
			},
			xs);
	});
var $author$project$Grid$addBuildingOccupancy = F3(
	function (gridConfig, building, occupancy) {
		var incrementCell = F2(
			function (cell, dict) {
				return A3(
					$elm$core$Dict$update,
					cell,
					function (maybeCount) {
						if (maybeCount.$ === 'Just') {
							var count = maybeCount.a;
							return $elm$core$Maybe$Just(count + 1);
						} else {
							return $elm$core$Maybe$Just(1);
						}
					},
					dict);
			});
		var cells = A2($author$project$Grid$getBuildingPathfindingCells, gridConfig, building);
		return A3($elm$core$List$foldl, incrementCell, occupancy, cells);
	});
var $author$project$Grid$getUnitPathfindingCells = F3(
	function (gridConfig, worldX, worldY) {
		var unitRadius = gridConfig.pathfindingGridSize / 4;
		var minY = worldY - unitRadius;
		var startPfY = $elm$core$Basics$floor(minY / gridConfig.pathfindingGridSize);
		var minX = worldX - unitRadius;
		var startPfX = $elm$core$Basics$floor(minX / gridConfig.pathfindingGridSize);
		var maxY = worldY + unitRadius;
		var maxX = worldX + unitRadius;
		var endPfY = $elm$core$Basics$floor(maxY / gridConfig.pathfindingGridSize);
		var ys = A2($elm$core$List$range, startPfY, endPfY);
		var endPfX = $elm$core$Basics$floor(maxX / gridConfig.pathfindingGridSize);
		var xs = A2($elm$core$List$range, startPfX, endPfX);
		return A2(
			$elm$core$List$concatMap,
			function (x) {
				return A2(
					$elm$core$List$map,
					function (y) {
						return _Utils_Tuple2(x, y);
					},
					ys);
			},
			xs);
	});
var $author$project$Grid$addUnitOccupancy = F4(
	function (gridConfig, worldX, worldY, occupancy) {
		var incrementCell = F2(
			function (cell, dict) {
				return A3(
					$elm$core$Dict$update,
					cell,
					function (maybeCount) {
						if (maybeCount.$ === 'Just') {
							var count = maybeCount.a;
							return $elm$core$Maybe$Just(count + 1);
						} else {
							return $elm$core$Maybe$Just(1);
						}
					},
					dict);
			});
		var cells = A3($author$project$Grid$getUnitPathfindingCells, gridConfig, worldX, worldY);
		return A3($elm$core$List$foldl, incrementCell, occupancy, cells);
	});
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Pathfinding$findNode = F2(
	function (pos, nodes) {
		return $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (n) {
					return _Utils_eq(n.position, pos);
				},
				nodes));
	});
var $elm$core$Basics$ge = _Utils_ge;
var $elm$core$List$sortBy = _List_sortBy;
var $author$project$Pathfinding$getLowestFCostNode = function (nodes) {
	if (!nodes.b) {
		return $elm$core$Maybe$Nothing;
	} else {
		return $elm$core$List$head(
			A2(
				$elm$core$List$sortBy,
				function (n) {
					return n.gCost + n.hCost;
				},
				nodes));
	}
};
var $author$project$Pathfinding$getNeighbors = function (_v0) {
	var x = _v0.a;
	var y = _v0.b;
	return _List_fromArray(
		[
			_Utils_Tuple2(
			_Utils_Tuple2(x + 1, y),
			1.0),
			_Utils_Tuple2(
			_Utils_Tuple2(x - 1, y),
			1.0),
			_Utils_Tuple2(
			_Utils_Tuple2(x, y + 1),
			1.0),
			_Utils_Tuple2(
			_Utils_Tuple2(x, y - 1),
			1.0),
			_Utils_Tuple2(
			_Utils_Tuple2(x + 1, y + 1),
			1.414),
			_Utils_Tuple2(
			_Utils_Tuple2(x + 1, y - 1),
			1.414),
			_Utils_Tuple2(
			_Utils_Tuple2(x - 1, y + 1),
			1.414),
			_Utils_Tuple2(
			_Utils_Tuple2(x - 1, y - 1),
			1.414)
		]);
};
var $author$project$Grid$isPathfindingCellOccupied = F2(
	function (cell, occupancy) {
		var _v0 = A2($elm$core$Dict$get, cell, occupancy);
		if (_v0.$ === 'Just') {
			var count = _v0.a;
			return count > 0;
		} else {
			return false;
		}
	});
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $elm$core$Basics$not = _Basics_not;
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $author$project$Pathfinding$octileDistance = F2(
	function (_v0, _v1) {
		var x1 = _v0.a;
		var y1 = _v0.b;
		var x2 = _v1.a;
		var y2 = _v1.b;
		var dy = $elm$core$Basics$abs(y1 - y2);
		var dx = $elm$core$Basics$abs(x1 - x2);
		var maxDist = A2($elm$core$Basics$max, dx, dy);
		var minDist = A2($elm$core$Basics$min, dx, dy);
		return (minDist * 1.414) + (maxDist - minDist);
	});
var $author$project$Pathfinding$reconstructPath = F2(
	function (endPos, parentMap) {
		var buildPath = F2(
			function (current, acc) {
				buildPath:
				while (true) {
					var _v0 = A2($elm$core$Dict$get, current, parentMap);
					if (_v0.$ === 'Just') {
						var parent = _v0.a;
						var $temp$current = parent,
							$temp$acc = A2($elm$core$List$cons, current, acc);
						current = $temp$current;
						acc = $temp$acc;
						continue buildPath;
					} else {
						return A2($elm$core$List$cons, current, acc);
					}
				}
			});
		return A2(buildPath, endPos, _List_Nil);
	});
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$Pathfinding$removeNode = F2(
	function (pos, nodes) {
		return A2(
			$elm$core$List$filter,
			function (n) {
				return !_Utils_eq(n.position, pos);
			},
			nodes);
	});
var $elm$core$List$tail = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(xs);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Pathfinding$findPath = F5(
	function (gridConfig, mapConfig, occupancy, start, goal) {
		var startNode = {
			gCost: 0,
			hCost: A2($author$project$Pathfinding$octileDistance, start, goal),
			parent: $elm$core$Maybe$Nothing,
			position: start
		};
		var isWalkable = function (_v7) {
			var x = _v7.a;
			var y = _v7.b;
			var worldY = y * gridConfig.pathfindingGridSize;
			var worldX = x * gridConfig.pathfindingGridSize;
			var inBounds = (worldX >= 0) && ((_Utils_cmp(worldX, mapConfig.width) < 0) && ((worldY >= 0) && (_Utils_cmp(worldY, mapConfig.height) < 0)));
			return inBounds && (!A2(
				$author$project$Grid$isPathfindingCellOccupied,
				_Utils_Tuple2(x, y),
				occupancy));
		};
		var astar = F3(
			function (openSet, closedSet, parentMap) {
				astar:
				while (true) {
					var _v0 = $author$project$Pathfinding$getLowestFCostNode(openSet);
					if (_v0.$ === 'Nothing') {
						return _List_Nil;
					} else {
						var currentNode = _v0.a;
						if (_Utils_eq(currentNode.position, goal)) {
							return A2(
								$elm$core$Maybe$withDefault,
								_List_Nil,
								$elm$core$List$tail(
									A2($author$project$Pathfinding$reconstructPath, goal, parentMap)));
						} else {
							var newOpenSet = A2($author$project$Pathfinding$removeNode, currentNode.position, openSet);
							var newClosedSet = A2($elm$core$List$cons, currentNode.position, closedSet);
							var neighbors = A2(
								$elm$core$List$filter,
								function (_v6) {
									var pos = _v6.a;
									return !A2($elm$core$List$member, pos, newClosedSet);
								},
								A2(
									$elm$core$List$filter,
									function (_v5) {
										var pos = _v5.a;
										return isWalkable(pos);
									},
									$author$project$Pathfinding$getNeighbors(currentNode.position)));
							var _v1 = A3(
								$elm$core$List$foldl,
								F2(
									function (_v2, _v3) {
										var neighborPos = _v2.a;
										var moveCost = _v2.b;
										var accOpenSet = _v3.a;
										var accParentMap = _v3.b;
										var tentativeGCost = currentNode.gCost + moveCost;
										var existingNode = A2($author$project$Pathfinding$findNode, neighborPos, accOpenSet);
										if (existingNode.$ === 'Just') {
											var existing = existingNode.a;
											if (_Utils_cmp(tentativeGCost, existing.gCost) < 0) {
												var updatedNode = {
													gCost: tentativeGCost,
													hCost: A2($author$project$Pathfinding$octileDistance, neighborPos, goal),
													parent: $elm$core$Maybe$Just(currentNode.position),
													position: neighborPos
												};
												var newOpenSet_ = A2(
													$elm$core$List$cons,
													updatedNode,
													A2($author$project$Pathfinding$removeNode, neighborPos, accOpenSet));
												return _Utils_Tuple2(
													newOpenSet_,
													A3($elm$core$Dict$insert, neighborPos, currentNode.position, accParentMap));
											} else {
												return _Utils_Tuple2(accOpenSet, accParentMap);
											}
										} else {
											var newNode = {
												gCost: tentativeGCost,
												hCost: A2($author$project$Pathfinding$octileDistance, neighborPos, goal),
												parent: $elm$core$Maybe$Just(currentNode.position),
												position: neighborPos
											};
											return _Utils_Tuple2(
												A2($elm$core$List$cons, newNode, accOpenSet),
												A3($elm$core$Dict$insert, neighborPos, currentNode.position, accParentMap));
										}
									}),
								_Utils_Tuple2(newOpenSet, parentMap),
								neighbors);
							var updatedOpenSet = _v1.a;
							var updatedParentMap = _v1.b;
							var $temp$openSet = updatedOpenSet,
								$temp$closedSet = newClosedSet,
								$temp$parentMap = updatedParentMap;
							openSet = $temp$openSet;
							closedSet = $temp$closedSet;
							parentMap = $temp$parentMap;
							continue astar;
						}
					}
				}
			});
		return _Utils_eq(start, goal) ? _List_Nil : ((!isWalkable(goal)) ? _List_Nil : A3(
			astar,
			_List_fromArray(
				[startNode]),
			_List_Nil,
			$elm$core$Dict$empty));
	});
var $author$project$Pathfinding$calculateUnitPath = F6(
	function (gridConfig, mapConfig, occupancy, unitX, unitY, targetCell) {
		var currentCell = _Utils_Tuple2(
			$elm$core$Basics$floor(unitX / gridConfig.pathfindingGridSize),
			$elm$core$Basics$floor(unitY / gridConfig.pathfindingGridSize));
		var path = A5($author$project$Pathfinding$findPath, gridConfig, mapConfig, occupancy, currentCell, targetCell);
		return path;
	});
var $elm$core$Basics$clamp = F3(
	function (low, high, number) {
		return (_Utils_cmp(number, low) < 0) ? low : ((_Utils_cmp(number, high) > 0) ? high : number);
	});
var $author$project$Update$getMinimapScale = F2(
	function (minimapConfig, mapConfig) {
		return A2($elm$core$Basics$min, (minimapConfig.width - (minimapConfig.padding * 2)) / mapConfig.width, (minimapConfig.height - (minimapConfig.padding * 2)) / mapConfig.height);
	});
var $author$project$Update$centerCameraOnMinimapClick = F4(
	function (model, minimapConfig, clickX, clickY) {
		var scale = A2($author$project$Update$getMinimapScale, minimapConfig, model.mapConfig);
		var terrainHeight = model.mapConfig.height * scale;
		var terrainWidth = model.mapConfig.width * scale;
		var clampedY = A3($elm$core$Basics$clamp, minimapConfig.padding, minimapConfig.padding + terrainHeight, clickY);
		var clampedX = A3($elm$core$Basics$clamp, minimapConfig.padding, minimapConfig.padding + terrainWidth, clickX);
		var _v0 = model.windowSize;
		var winWidth = _v0.a;
		var winHeight = _v0.b;
		var worldY = ((clampedY - minimapConfig.padding) / scale) - (winHeight / 2);
		var worldX = ((clampedX - minimapConfig.padding) / scale) - (winWidth / 2);
		return {x: worldX, y: worldY};
	});
var $author$project$Update$constrainCamera = F3(
	function (config, _v0, camera) {
		var winWidth = _v0.a;
		var winHeight = _v0.b;
		var viewWidth = winWidth;
		var viewHeight = winHeight;
		var minY = 0 - config.boundary;
		var minX = 0 - config.boundary;
		var maxY = (config.height + config.boundary) - viewHeight;
		var maxX = (config.width + config.boundary) - viewWidth;
		return {
			x: A3($elm$core$Basics$clamp, minX, maxX, camera.x),
			y: A3($elm$core$Basics$clamp, minY, maxY, camera.y)
		};
	});
var $author$project$Types$Garrisoned = function (a) {
	return {$: 'Garrisoned', a: a};
};
var $author$project$Types$Henchman = {$: 'Henchman'};
var $author$project$Types$HenchmanTag = {$: 'HenchmanTag'};
var $author$project$Types$Sleeping = {$: 'Sleeping'};
var $author$project$GameHelpers$createHenchman = F4(
	function (unitType, unitId, buildingId, homeBuilding) {
		var _v0 = function () {
			switch (unitType) {
				case 'Peasant':
					return _Utils_Tuple3(
						50,
						2.0,
						_List_fromArray(
							[$author$project$Types$HenchmanTag]));
				case 'Tax Collector':
					return _Utils_Tuple3(
						50,
						1.5,
						_List_fromArray(
							[$author$project$Types$HenchmanTag]));
				case 'Castle Guard':
					return _Utils_Tuple3(
						100,
						2.0,
						_List_fromArray(
							[$author$project$Types$HenchmanTag]));
				default:
					return _Utils_Tuple3(
						50,
						2.0,
						_List_fromArray(
							[$author$project$Types$HenchmanTag]));
			}
		}();
		var hp = _v0.a;
		var speed = _v0.b;
		var tags = _v0.c;
		return {
			activeRadius: 192,
			behavior: $author$project$Types$Sleeping,
			behaviorDuration: 0,
			behaviorTimer: 0,
			carriedGold: 0,
			color: '#888',
			homeBuilding: $elm$core$Maybe$Just(buildingId),
			hp: hp,
			id: unitId,
			location: $author$project$Types$Garrisoned(buildingId),
			maxHp: hp,
			movementSpeed: speed,
			owner: $author$project$Types$Player,
			path: _List_Nil,
			searchRadius: 384,
			tags: tags,
			targetDestination: $elm$core$Maybe$Nothing,
			thinkingDuration: 0,
			thinkingTimer: 0,
			unitKind: $author$project$Types$Henchman,
			unitType: unitType
		};
	});
var $author$project$Grid$getBuildingAreaCells = F2(
	function (building, radiusInCells) {
		var sizeCells = $author$project$Types$buildingSizeToGridCells(building.size);
		var centerY = building.gridY + ((sizeCells / 2) | 0);
		var maxY = centerY + radiusInCells;
		var minY = centerY - radiusInCells;
		var centerX = building.gridX + ((sizeCells / 2) | 0);
		var maxX = centerX + radiusInCells;
		var minX = centerX - radiusInCells;
		var allCells = A2(
			$elm$core$List$concatMap,
			function (x) {
				return A2(
					$elm$core$List$map,
					function (y) {
						return _Utils_Tuple2(x, y);
					},
					A2($elm$core$List$range, minY, maxY));
			},
			A2($elm$core$List$range, minX, maxX));
		return allCells;
	});
var $author$project$Types$Idle = {$: 'Idle'};
var $elm$core$Dict$member = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$get, key, dict);
		if (_v0.$ === 'Just') {
			return true;
		} else {
			return false;
		}
	});
var $author$project$Grid$areBuildGridCellsOccupied = F2(
	function (cells, occupancy) {
		return A2(
			$elm$core$List$any,
			function (cell) {
				return A2($elm$core$Dict$member, cell, occupancy);
			},
			cells);
	});
var $author$project$Grid$getBuildingGridCellsWithSpacing = function (building) {
	var startY = building.gridY - 1;
	var startX = building.gridX - 1;
	var sizeCells = $author$project$Types$buildingSizeToGridCells(building.size);
	var endY = building.gridY + sizeCells;
	var ys = A2($elm$core$List$range, startY, endY);
	var endX = building.gridX + sizeCells;
	var xs = A2($elm$core$List$range, startX, endX);
	return A2(
		$elm$core$List$concatMap,
		function (x) {
			return A2(
				$elm$core$List$map,
				function (y) {
					return _Utils_Tuple2(x, y);
				},
				ys);
		},
		xs);
};
var $author$project$Grid$getCitySearchArea = function (buildings) {
	return $elm$core$Dict$keys(
		A3(
			$elm$core$List$foldl,
			F2(
				function (cell, acc) {
					return A3($elm$core$Dict$insert, cell, _Utils_Tuple0, acc);
				}),
			$elm$core$Dict$empty,
			A2(
				$elm$core$List$concatMap,
				function (b) {
					return A2($author$project$Grid$getBuildingAreaCells, b, 6);
				},
				A2(
					$elm$core$List$filter,
					function (b) {
						return _Utils_eq(b.owner, $author$project$Types$Player);
					},
					buildings))));
};
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Grid$isValidBuildingPlacement = F7(
	function (gridX, gridY, size, mapConfig, gridConfig, buildingOccupancy, buildings) {
		var tempBuilding = {
			activeRadius: 192,
			behavior: $author$project$Types$Idle,
			behaviorDuration: 0,
			behaviorTimer: 0,
			buildingType: '',
			coffer: 0,
			garrisonConfig: _List_Nil,
			garrisonOccupied: 0,
			garrisonSlots: 0,
			gridX: gridX,
			gridY: gridY,
			hp: 0,
			id: 0,
			maxHp: 0,
			owner: $author$project$Types$Player,
			searchRadius: 384,
			size: size,
			tags: _List_fromArray(
				[$author$project$Types$BuildingTag])
		};
		var sizeCells = $author$project$Types$buildingSizeToGridCells(size);
		var maxGridY = $elm$core$Basics$floor(mapConfig.height / gridConfig.buildGridSize);
		var maxGridX = $elm$core$Basics$floor(mapConfig.width / gridConfig.buildGridSize);
		var inBounds = (gridX >= 0) && ((gridY >= 0) && ((_Utils_cmp(gridX + sizeCells, maxGridX) < 1) && (_Utils_cmp(gridY + sizeCells, maxGridY) < 1)));
		var citySearchArea = $author$project$Grid$getCitySearchArea(buildings);
		var searchAreaSet = A3(
			$elm$core$List$foldl,
			F2(
				function (cell, acc) {
					return A3($elm$core$Dict$insert, cell, _Utils_Tuple0, acc);
				}),
			$elm$core$Dict$empty,
			citySearchArea);
		var cellsWithSpacing = $author$project$Grid$getBuildingGridCellsWithSpacing(tempBuilding);
		var notOccupied = !A2($author$project$Grid$areBuildGridCellsOccupied, cellsWithSpacing, buildingOccupancy);
		var buildingCells = $author$project$Grid$getBuildingGridCells(tempBuilding);
		var tilesInSearchArea = $elm$core$List$length(
			A2(
				$elm$core$List$filter,
				function (cell) {
					return A2($elm$core$Dict$member, cell, searchAreaSet);
				},
				buildingCells));
		var totalTiles = $elm$core$List$length(buildingCells);
		var atLeastHalfInSearchArea = $elm$core$List$isEmpty(buildings) ? true : (_Utils_cmp(tilesInSearchArea, totalTiles / 2) > -1);
		return inBounds && (notOccupied && atLeastHalfInSearchArea);
	});
var $elm$core$List$takeReverse = F3(
	function (n, list, kept) {
		takeReverse:
		while (true) {
			if (n <= 0) {
				return kept;
			} else {
				if (!list.b) {
					return kept;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs,
						$temp$kept = A2($elm$core$List$cons, x, kept);
					n = $temp$n;
					list = $temp$list;
					kept = $temp$kept;
					continue takeReverse;
				}
			}
		}
	});
var $elm$core$List$takeTailRec = F2(
	function (n, list) {
		return $elm$core$List$reverse(
			A3($elm$core$List$takeReverse, n, list, _List_Nil));
	});
var $elm$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (n <= 0) {
			return _List_Nil;
		} else {
			var _v0 = _Utils_Tuple2(n, list);
			_v0$1:
			while (true) {
				_v0$5:
				while (true) {
					if (!_v0.b.b) {
						return list;
					} else {
						if (_v0.b.b.b) {
							switch (_v0.a) {
								case 1:
									break _v0$1;
								case 2:
									var _v2 = _v0.b;
									var x = _v2.a;
									var _v3 = _v2.b;
									var y = _v3.a;
									return _List_fromArray(
										[x, y]);
								case 3:
									if (_v0.b.b.b.b) {
										var _v4 = _v0.b;
										var x = _v4.a;
										var _v5 = _v4.b;
										var y = _v5.a;
										var _v6 = _v5.b;
										var z = _v6.a;
										return _List_fromArray(
											[x, y, z]);
									} else {
										break _v0$5;
									}
								default:
									if (_v0.b.b.b.b && _v0.b.b.b.b.b) {
										var _v7 = _v0.b;
										var x = _v7.a;
										var _v8 = _v7.b;
										var y = _v8.a;
										var _v9 = _v8.b;
										var z = _v9.a;
										var _v10 = _v9.b;
										var w = _v10.a;
										var tl = _v10.b;
										return (ctr > 1000) ? A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A2($elm$core$List$takeTailRec, n - 4, tl))))) : A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A3($elm$core$List$takeFast, ctr + 1, n - 4, tl)))));
									} else {
										break _v0$5;
									}
							}
						} else {
							if (_v0.a === 1) {
								break _v0$1;
							} else {
								break _v0$5;
							}
						}
					}
				}
				return list;
			}
			var _v1 = _v0.b;
			var x = _v1.a;
			return _List_fromArray(
				[x]);
		}
	});
var $elm$core$List$take = F2(
	function (n, list) {
		return A3($elm$core$List$takeFast, 0, n, list);
	});
var $author$project$Grid$findAdjacentHouseLocation = F4(
	function (mapConfig, gridConfig, buildings, buildingOccupancy) {
		var houseSize = $author$project$Types$Medium;
		var adjacentCells = A2(
			$elm$core$List$take,
			100,
			A2(
				$elm$core$List$filter,
				function (_v0) {
					var gx = _v0.a;
					var gy = _v0.b;
					return A7($author$project$Grid$isValidBuildingPlacement, gx, gy, houseSize, mapConfig, gridConfig, buildingOccupancy, buildings);
				},
				A2(
					$elm$core$List$concatMap,
					function (b) {
						return A2($author$project$Grid$getBuildingAreaCells, b, 1);
					},
					buildings)));
		return $elm$core$List$head(adjacentCells);
	});
var $author$project$Update$isClickOnViewbox = F4(
	function (model, minimapConfig, clickX, clickY) {
		var scale = A2($author$project$Update$getMinimapScale, minimapConfig, model.mapConfig);
		var viewboxLeft = minimapConfig.padding + (model.camera.x * scale);
		var viewboxTop = minimapConfig.padding + (model.camera.y * scale);
		var _v0 = model.windowSize;
		var winWidth = _v0.a;
		var winHeight = _v0.b;
		var viewboxHeight = winHeight * scale;
		var viewboxWidth = winWidth * scale;
		return (_Utils_cmp(clickX, viewboxLeft) > -1) && ((_Utils_cmp(clickX, viewboxLeft + viewboxWidth) < 1) && ((_Utils_cmp(clickY, viewboxTop) > -1) && (_Utils_cmp(clickY, viewboxTop + viewboxHeight) < 1)));
	});
var $author$project$Update$minimapClickOffset = F4(
	function (model, minimapConfig, clickX, clickY) {
		var scale = A2($author$project$Update$getMinimapScale, minimapConfig, model.mapConfig);
		var viewboxLeft = minimapConfig.padding + (model.camera.x * scale);
		var viewboxTop = minimapConfig.padding + (model.camera.y * scale);
		var offsetY = clickY - viewboxTop;
		var offsetX = clickX - viewboxLeft;
		return {x: offsetX, y: offsetY};
	});
var $author$project$Update$minimapDragToCamera = F4(
	function (model, offset, clickX, clickY) {
		var minimapConfig = {height: 150, padding: 10, width: 200};
		var scale = A2($author$project$Update$getMinimapScale, minimapConfig, model.mapConfig);
		var worldX = ((clickX - minimapConfig.padding) - offset.x) / scale;
		var worldY = ((clickY - minimapConfig.padding) - offset.y) / scale;
		return {x: worldX, y: worldY};
	});
var $elm$core$Basics$modBy = _Basics_modBy;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$GameHelpers$recalculateAllPaths = F4(
	function (gridConfig, mapConfig, occupancy, units) {
		return A2(
			$elm$core$List$map,
			function (unit) {
				if ($elm$core$List$isEmpty(unit.path)) {
					return unit;
				} else {
					var _v0 = unit.location;
					if (_v0.$ === 'OnMap') {
						var x = _v0.a;
						var y = _v0.b;
						var _v1 = $elm$core$List$head(
							$elm$core$List$reverse(unit.path));
						if (_v1.$ === 'Just') {
							var goalCell = _v1.a;
							var newPath = A6($author$project$Pathfinding$calculateUnitPath, gridConfig, mapConfig, occupancy, x, y, goalCell);
							return _Utils_update(
								unit,
								{path: newPath});
						} else {
							return unit;
						}
					} else {
						return unit;
					}
				}
			},
			units);
	});
var $author$project$Grid$removeUnitOccupancy = F4(
	function (gridConfig, worldX, worldY, occupancy) {
		var decrementCell = F2(
			function (cell, dict) {
				return A3(
					$elm$core$Dict$update,
					cell,
					function (maybeCount) {
						if (maybeCount.$ === 'Just') {
							var count = maybeCount.a;
							return (count <= 1) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(count - 1);
						} else {
							return $elm$core$Maybe$Nothing;
						}
					},
					dict);
			});
		var cells = A3($author$project$Grid$getUnitPathfindingCells, gridConfig, worldX, worldY);
		return A3($elm$core$List$foldl, decrementCell, occupancy, cells);
	});
var $elm$core$Basics$round = _Basics_round;
var $author$project$BuildingBehavior$updateBuildingBehavior = F2(
	function (deltaSeconds, building) {
		var _v0 = building.behavior;
		switch (_v0.$) {
			case 'Idle':
				return _Utils_Tuple2(building, false);
			case 'UnderConstruction':
				return _Utils_Tuple2(building, false);
			case 'SpawnHouse':
				var newTimer = building.behaviorTimer + deltaSeconds;
				if (_Utils_cmp(newTimer, building.behaviorDuration) > -1) {
					var randomValue = A2(
						$elm$core$Basics$modBy,
						15000,
						(building.id * 1000) + $elm$core$Basics$round(building.behaviorTimer * 1000)) / 1000.0;
					var newDuration = 30.0 + randomValue;
					return _Utils_Tuple2(
						_Utils_update(
							building,
							{behaviorDuration: newDuration, behaviorTimer: 0}),
						true);
				} else {
					return _Utils_Tuple2(
						_Utils_update(
							building,
							{behaviorTimer: newTimer}),
						false);
				}
			case 'GenerateGold':
				var newTimer = building.behaviorTimer + deltaSeconds;
				if (_Utils_cmp(newTimer, building.behaviorDuration) > -1) {
					var randomSeed = (building.id * 1000) + $elm$core$Basics$round(building.behaviorTimer * 1000);
					var durationRandomValue = A2($elm$core$Basics$modBy, 30000, randomSeed) / 1000.0;
					var newDuration = 15.0 + durationRandomValue;
					var _v1 = (building.buildingType === 'House') ? _Utils_Tuple2(45, 90) : _Utils_Tuple2(450, 900);
					var minGold = _v1.a;
					var maxGold = _v1.b;
					var goldRange = maxGold - minGold;
					var goldRandomValue = A2($elm$core$Basics$modBy, goldRange + 1, randomSeed + 12345);
					var goldAmount = minGold + goldRandomValue;
					return _Utils_Tuple2(
						_Utils_update(
							building,
							{behaviorDuration: newDuration, behaviorTimer: 0, coffer: building.coffer + goldAmount}),
						false);
				} else {
					return _Utils_Tuple2(
						_Utils_update(
							building,
							{behaviorTimer: newTimer}),
						false);
				}
			case 'BuildingDead':
				return _Utils_Tuple2(building, false);
			default:
				return _Utils_Tuple2(building, false);
		}
	});
var $author$project$UnitBehavior$updateGarrisonSpawning = F2(
	function (deltaSeconds, building) {
		var _v0 = A3(
			$elm$core$List$foldl,
			F2(
				function (slot, _v1) {
					var accConfig = _v1.a;
					var accSpawn = _v1.b;
					if (_Utils_cmp(slot.currentCount, slot.maxCount) < 0) {
						var newTimer = slot.spawnTimer + deltaSeconds;
						return (newTimer >= 30.0) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_update(
									slot,
									{currentCount: slot.currentCount + 1, spawnTimer: 0}),
								accConfig),
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(slot.unitType, building.id),
								accSpawn)) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_update(
									slot,
									{spawnTimer: newTimer}),
								accConfig),
							accSpawn);
					} else {
						return _Utils_Tuple2(
							A2($elm$core$List$cons, slot, accConfig),
							accSpawn);
					}
				}),
			_Utils_Tuple2(_List_Nil, _List_Nil),
			building.garrisonConfig);
		var updatedConfig = _v0.a;
		var unitsToSpawn = _v0.b;
		var totalOccupied = A3(
			$elm$core$List$foldl,
			F2(
				function (slot, acc) {
					return acc + slot.currentCount;
				}),
			0,
			updatedConfig);
		return _Utils_Tuple2(
			_Utils_update(
				building,
				{
					garrisonConfig: $elm$core$List$reverse(updatedConfig),
					garrisonOccupied: totalOccupied
				}),
			$elm$core$List$reverse(unitsToSpawn));
	});
var $author$project$Types$Dead = {$: 'Dead'};
var $author$project$Types$DebugError = function (a) {
	return {$: 'DebugError', a: a};
};
var $author$project$Types$GoingToSleep = {$: 'GoingToSleep'};
var $author$project$Types$LookForBuildRepairTarget = {$: 'LookForBuildRepairTarget'};
var $author$project$Types$LookForTaxTarget = {$: 'LookForTaxTarget'};
var $author$project$Types$LookingForTask = {$: 'LookingForTask'};
var $author$project$Types$MovingToBuildRepairTarget = {$: 'MovingToBuildRepairTarget'};
var $author$project$Types$Repairing = {$: 'Repairing'};
var $author$project$Types$WithoutHome = {$: 'WithoutHome'};
var $author$project$Types$OnMap = F2(
	function (a, b) {
		return {$: 'OnMap', a: a, b: b};
	});
var $author$project$Grid$getBuildingEntrance = function (building) {
	var _v0 = building.size;
	switch (_v0.$) {
		case 'Small':
			return _Utils_Tuple2(building.gridX, building.gridY);
		case 'Medium':
			return _Utils_Tuple2(building.gridX, building.gridY + 1);
		case 'Large':
			return _Utils_Tuple2(building.gridX + 1, building.gridY + 2);
		default:
			return _Utils_Tuple2(building.gridX + 1, building.gridY + 3);
	}
};
var $author$project$GameHelpers$exitGarrison = F2(
	function (homeBuilding, unit) {
		var buildGridSize = 64;
		var _v0 = $author$project$Grid$getBuildingEntrance(homeBuilding);
		var entranceGridX = _v0.a;
		var entranceGridY = _v0.b;
		var exitGridX = entranceGridX;
		var worldX = (exitGridX * buildGridSize) + (buildGridSize / 2);
		var exitGridY = entranceGridY + 1;
		var worldY = (exitGridY * buildGridSize) + (buildGridSize / 2);
		return _Utils_update(
			unit,
			{
				location: A2($author$project$Types$OnMap, worldX, worldY)
			});
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $elm$core$Basics$sqrt = _Basics_sqrt;
var $author$project$GameHelpers$findNearestDamagedBuilding = F3(
	function (unitX, unitY, buildings) {
		var damagedBuildings = A2(
			$elm$core$List$filter,
			function (b) {
				return _Utils_cmp(b.hp, b.maxHp) < 0;
			},
			buildings);
		var buildGridSize = 64;
		var buildingWithDistance = function (b) {
			var buildingCenterY = (b.gridY * buildGridSize) + (($author$project$Types$buildingSizeToGridCells(b.size) * buildGridSize) / 2);
			var dy = unitY - buildingCenterY;
			var buildingCenterX = (b.gridX * buildGridSize) + (($author$project$Types$buildingSizeToGridCells(b.size) * buildGridSize) / 2);
			var dx = unitX - buildingCenterX;
			var distance = $elm$core$Basics$sqrt((dx * dx) + (dy * dy));
			return _Utils_Tuple2(b, distance);
		};
		var sortedByDistance = A2(
			$elm$core$List$map,
			$elm$core$Tuple$first,
			A2(
				$elm$core$List$sortBy,
				$elm$core$Tuple$second,
				A2($elm$core$List$map, buildingWithDistance, damagedBuildings)));
		return $elm$core$List$head(sortedByDistance);
	});
var $author$project$UnitBehavior$updateUnitBehavior = F3(
	function (deltaSeconds, buildings, unit) {
		var _v0 = unit.behavior;
		switch (_v0.$) {
			case 'Dead':
				return _Utils_Tuple2(unit, false);
			case 'DebugError':
				return _Utils_Tuple2(unit, false);
			case 'WithoutHome':
				var newTimer = unit.behaviorTimer + deltaSeconds;
				return (_Utils_cmp(newTimer, unit.behaviorDuration) > -1) ? _Utils_Tuple2(
					_Utils_update(
						unit,
						{
							behavior: $author$project$Types$Dead,
							behaviorDuration: 45.0 + (A2($elm$core$Basics$modBy, 15000, unit.id) / 1000.0),
							behaviorTimer: 0
						}),
					false) : _Utils_Tuple2(
					_Utils_update(
						unit,
						{behaviorTimer: newTimer}),
					false);
			case 'LookingForTask':
				var _v1 = unit.unitType;
				switch (_v1) {
					case 'Peasant':
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$LookForBuildRepairTarget, behaviorTimer: 0}),
							false);
					case 'Tax Collector':
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$LookForTaxTarget, behaviorTimer: 0}),
							false);
					case 'Castle Guard':
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$GoingToSleep, behaviorTimer: 0}),
							false);
					default:
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$GoingToSleep, behaviorTimer: 0}),
							false);
				}
			case 'GoingToSleep':
				var _v2 = unit.homeBuilding;
				if (_v2.$ === 'Nothing') {
					return _Utils_Tuple2(
						_Utils_update(
							unit,
							{
								behavior: $author$project$Types$WithoutHome,
								behaviorDuration: 15.0 + (A2($elm$core$Basics$modBy, 15000, unit.id) / 1000.0),
								behaviorTimer: 0
							}),
						false);
				} else {
					var homeBuildingId = _v2.a;
					var _v3 = $elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (b) {
								return _Utils_eq(b.id, homeBuildingId);
							},
							buildings));
					if (_v3.$ === 'Nothing') {
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{
									behavior: $author$project$Types$WithoutHome,
									behaviorDuration: 15.0 + (A2($elm$core$Basics$modBy, 15000, unit.id) / 1000.0),
									behaviorTimer: 0,
									homeBuilding: $elm$core$Maybe$Nothing
								}),
							false);
					} else {
						var homeBuilding = _v3.a;
						var _v4 = unit.location;
						if (_v4.$ === 'Garrisoned') {
							return _Utils_Tuple2(
								_Utils_update(
									unit,
									{behavior: $author$project$Types$Sleeping, behaviorTimer: 0}),
								false);
						} else {
							var x = _v4.a;
							var y = _v4.b;
							var buildGridSize = 64;
							var _v5 = $author$project$Grid$getBuildingEntrance(homeBuilding);
							var entranceGridX = _v5.a;
							var entranceGridY = _v5.b;
							var exitGridX = entranceGridX;
							var exitX = (exitGridX * buildGridSize) + (buildGridSize / 2);
							var dx = x - exitX;
							var exitGridY = entranceGridY + 1;
							var exitY = (exitGridY * buildGridSize) + (buildGridSize / 2);
							var dy = y - exitY;
							var distance = $elm$core$Basics$sqrt((dx * dx) + (dy * dy));
							var isAtEntrance = distance < 32;
							if (isAtEntrance) {
								return _Utils_Tuple2(
									_Utils_update(
										unit,
										{
											behavior: $author$project$Types$Sleeping,
											behaviorTimer: 0,
											location: $author$project$Types$Garrisoned(homeBuildingId)
										}),
									false);
							} else {
								var targetCellY = $elm$core$Basics$floor(exitY / 32);
								var targetCellX = $elm$core$Basics$floor(exitX / 32);
								return _Utils_Tuple2(
									_Utils_update(
										unit,
										{
											targetDestination: $elm$core$Maybe$Just(
												_Utils_Tuple2(targetCellX, targetCellY))
										}),
									true);
							}
						}
					}
				}
			case 'Sleeping':
				var newTimer = unit.behaviorTimer + deltaSeconds;
				var shouldLookForTask = newTimer >= 1.0;
				var healAmount = (unit.maxHp * 0.1) * deltaSeconds;
				var newHp = A2(
					$elm$core$Basics$min,
					unit.maxHp,
					unit.hp + $elm$core$Basics$round(healAmount));
				return shouldLookForTask ? _Utils_Tuple2(
					_Utils_update(
						unit,
						{behavior: $author$project$Types$LookingForTask, behaviorTimer: 0, hp: newHp}),
					false) : _Utils_Tuple2(
					_Utils_update(
						unit,
						{behaviorTimer: newTimer, hp: newHp}),
					false);
			case 'LookForBuildRepairTarget':
				var _v6 = unit.location;
				if (_v6.$ === 'Garrisoned') {
					var buildingId = _v6.a;
					var _v7 = $elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (b) {
								return _Utils_eq(b.id, buildingId);
							},
							buildings));
					if (_v7.$ === 'Just') {
						var homeBuilding = _v7.a;
						var exitedUnit = A2($author$project$GameHelpers$exitGarrison, homeBuilding, unit);
						var _v8 = function () {
							var _v9 = exitedUnit.location;
							if (_v9.$ === 'OnMap') {
								var x = _v9.a;
								var y = _v9.b;
								return _Utils_Tuple2(x, y);
							} else {
								return _Utils_Tuple2(0, 0);
							}
						}();
						var finalX = _v8.a;
						var finalY = _v8.b;
						var _v10 = A3($author$project$GameHelpers$findNearestDamagedBuilding, finalX, finalY, buildings);
						if (_v10.$ === 'Just') {
							var targetBuilding = _v10.a;
							var buildGridSize = 64;
							var targetX = (targetBuilding.gridX * buildGridSize) + (($author$project$Types$buildingSizeToGridCells(targetBuilding.size) * buildGridSize) / 2);
							var targetCellX = $elm$core$Basics$floor(targetX / 32);
							var targetY = (targetBuilding.gridY * buildGridSize) + (($author$project$Types$buildingSizeToGridCells(targetBuilding.size) * buildGridSize) / 2);
							var targetCellY = $elm$core$Basics$floor(targetY / 32);
							return _Utils_Tuple2(
								_Utils_update(
									exitedUnit,
									{
										behavior: $author$project$Types$MovingToBuildRepairTarget,
										behaviorTimer: 0,
										targetDestination: $elm$core$Maybe$Just(
											_Utils_Tuple2(targetCellX, targetCellY))
									}),
								true);
						} else {
							return _Utils_Tuple2(
								_Utils_update(
									exitedUnit,
									{behavior: $author$project$Types$GoingToSleep, behaviorTimer: 0}),
								false);
						}
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{
									behavior: $author$project$Types$DebugError('Home building not found')
								}),
							false);
					}
				} else {
					var x = _v6.a;
					var y = _v6.b;
					var _v11 = A3($author$project$GameHelpers$findNearestDamagedBuilding, x, y, buildings);
					if (_v11.$ === 'Just') {
						var targetBuilding = _v11.a;
						var buildGridSize = 64;
						var targetX = (targetBuilding.gridX * buildGridSize) + (($author$project$Types$buildingSizeToGridCells(targetBuilding.size) * buildGridSize) / 2);
						var targetCellX = $elm$core$Basics$floor(targetX / 32);
						var targetY = (targetBuilding.gridY * buildGridSize) + (($author$project$Types$buildingSizeToGridCells(targetBuilding.size) * buildGridSize) / 2);
						var targetCellY = $elm$core$Basics$floor(targetY / 32);
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{
									behavior: $author$project$Types$MovingToBuildRepairTarget,
									behaviorTimer: 0,
									targetDestination: $elm$core$Maybe$Just(
										_Utils_Tuple2(targetCellX, targetCellY))
								}),
							true);
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$GoingToSleep, behaviorTimer: 0}),
							false);
					}
				}
			case 'MovingToBuildRepairTarget':
				var _v12 = unit.location;
				if (_v12.$ === 'OnMap') {
					var x = _v12.a;
					var y = _v12.b;
					var _v13 = A3($author$project$GameHelpers$findNearestDamagedBuilding, x, y, buildings);
					if (_v13.$ === 'Just') {
						var targetBuilding = _v13.a;
						var buildGridSize = 64;
						var buildingMinX = targetBuilding.gridX * buildGridSize;
						var buildingMinY = targetBuilding.gridY * buildGridSize;
						var buildingSize = $author$project$Types$buildingSizeToGridCells(targetBuilding.size) * buildGridSize;
						var buildingMaxX = buildingMinX + buildingSize;
						var buildingMaxY = buildingMinY + buildingSize;
						var isNear = ((_Utils_cmp(x, buildingMinX - 48) > -1) && (_Utils_cmp(x, buildingMaxX + 48) < 1)) && ((_Utils_cmp(y, buildingMinY - 48) > -1) && (_Utils_cmp(y, buildingMaxY + 48) < 1));
						return isNear ? _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$Repairing, behaviorTimer: 0}),
							false) : _Utils_Tuple2(unit, false);
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$LookForBuildRepairTarget, behaviorTimer: 0}),
							false);
					}
				} else {
					return _Utils_Tuple2(
						_Utils_update(
							unit,
							{
								behavior: $author$project$Types$DebugError('Moving while garrisoned')
							}),
						false);
				}
			case 'Repairing':
				var _v14 = unit.location;
				if (_v14.$ === 'OnMap') {
					var x = _v14.a;
					var y = _v14.b;
					var _v15 = A3($author$project$GameHelpers$findNearestDamagedBuilding, x, y, buildings);
					if (_v15.$ === 'Just') {
						var targetBuilding = _v15.a;
						var newTimer = unit.behaviorTimer + deltaSeconds;
						var canBuild = newTimer >= 0.15;
						var buildGridSize = 64;
						var buildingMinX = targetBuilding.gridX * buildGridSize;
						var buildingMinY = targetBuilding.gridY * buildGridSize;
						var buildingSize = $author$project$Types$buildingSizeToGridCells(targetBuilding.size) * buildGridSize;
						var buildingMaxX = buildingMinX + buildingSize;
						var buildingMaxY = buildingMinY + buildingSize;
						var isNear = ((_Utils_cmp(x, buildingMinX - 48) > -1) && (_Utils_cmp(x, buildingMaxX + 48) < 1)) && ((_Utils_cmp(y, buildingMinY - 48) > -1) && (_Utils_cmp(y, buildingMaxY + 48) < 1));
						return (isNear && canBuild) ? ((_Utils_cmp(targetBuilding.hp + 5, targetBuilding.maxHp) > -1) ? _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$LookForBuildRepairTarget, behaviorTimer: 0}),
							false) : _Utils_Tuple2(
							_Utils_update(
								unit,
								{behaviorTimer: 0}),
							false)) : (isNear ? _Utils_Tuple2(
							_Utils_update(
								unit,
								{behaviorTimer: newTimer}),
							false) : _Utils_Tuple2(unit, false));
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								unit,
								{behavior: $author$project$Types$LookForBuildRepairTarget, behaviorTimer: 0}),
							false);
					}
				} else {
					return _Utils_Tuple2(
						_Utils_update(
							unit,
							{
								behavior: $author$project$Types$DebugError('Repairing while garrisoned')
							}),
						false);
				}
			case 'LookForTaxTarget':
				return _Utils_Tuple2(unit, false);
			case 'CollectingTaxes':
				return _Utils_Tuple2(unit, false);
			case 'ReturnToCastle':
				return _Utils_Tuple2(unit, false);
			default:
				return _Utils_Tuple2(unit, false);
		}
	});
var $author$project$GameHelpers$updateUnitMovement = F5(
	function (gridConfig, mapConfig, occupancy, deltaSeconds, unit) {
		var _v0 = unit.location;
		if (_v0.$ === 'OnMap') {
			var x = _v0.a;
			var y = _v0.b;
			var _v1 = unit.path;
			if (!_v1.b) {
				return unit;
			} else {
				var nextCell = _v1.a;
				var restOfPath = _v1.b;
				var targetY = (nextCell.b * gridConfig.pathfindingGridSize) + (gridConfig.pathfindingGridSize / 2);
				var targetX = (nextCell.a * gridConfig.pathfindingGridSize) + (gridConfig.pathfindingGridSize / 2);
				var moveDistance = (unit.movementSpeed * gridConfig.pathfindingGridSize) * deltaSeconds;
				var dy = targetY - y;
				var dx = targetX - x;
				var distance = $elm$core$Basics$sqrt((dx * dx) + (dy * dy));
				if (_Utils_cmp(distance, moveDistance) < 1) {
					var _v2 = _Utils_Tuple2(unit.targetDestination, restOfPath);
					if ((_v2.a.$ === 'Just') && _v2.b.b) {
						var targetCell = _v2.a.a;
						var _v3 = _v2.b;
						var newPath = A6($author$project$Pathfinding$calculateUnitPath, gridConfig, mapConfig, occupancy, targetX, targetY, targetCell);
						return _Utils_update(
							unit,
							{
								location: A2($author$project$Types$OnMap, targetX, targetY),
								path: newPath
							});
					} else {
						return _Utils_update(
							unit,
							{
								location: A2($author$project$Types$OnMap, targetX, targetY),
								path: restOfPath
							});
					}
				} else {
					var normalizedDy = dy / distance;
					var normalizedDx = dx / distance;
					var newY = y + (normalizedDy * moveDistance);
					var newX = x + (normalizedDx * moveDistance);
					return _Utils_update(
						unit,
						{
							location: A2($author$project$Types$OnMap, newX, newY)
						});
				}
			}
		} else {
			return unit;
		}
	});
var $author$project$Update$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 'WindowResize':
				var width = msg.a;
				var height = msg.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							windowSize: _Utils_Tuple2(width, height)
						}),
					$elm$core$Platform$Cmd$none);
			case 'MouseDown':
				var x = msg.a;
				var y = msg.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							dragState: $author$project$Types$DraggingViewport(
								{x: x, y: y})
						}),
					$elm$core$Platform$Cmd$none);
			case 'MouseMove':
				var x = msg.a;
				var y = msg.b;
				var _v1 = model.dragState;
				if (_v1.$ === 'DraggingViewport') {
					var startPos = _v1.a;
					var dy = startPos.y - y;
					var dx = startPos.x - x;
					var newCamera = A3(
						$author$project$Update$constrainCamera,
						model.mapConfig,
						model.windowSize,
						{x: model.camera.x + dx, y: model.camera.y + dy});
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								camera: newCamera,
								dragState: $author$project$Types$DraggingViewport(
									{x: x, y: y})
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 'MouseUp':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{dragState: $author$project$Types$NotDragging}),
					$elm$core$Platform$Cmd$none);
			case 'MinimapMouseDown':
				var clientX = msg.a;
				var clientY = msg.b;
				var minimapWidth = 200;
				var minimapHeight = 150;
				var minimapConfig = {height: 150, padding: 10, width: 200};
				var _v2 = model.windowSize;
				var winWidth = _v2.a;
				var winHeight = _v2.b;
				var minimapTop = ((winHeight - 20) - 154) + 2;
				var offsetY = A3($elm$core$Basics$clamp, 0, minimapHeight, clientY - minimapTop);
				var minimapLeft = ((winWidth - 20) - 204) + 2;
				var offsetX = A3($elm$core$Basics$clamp, 0, minimapWidth, clientX - minimapLeft);
				var clickedOnViewbox = A4($author$project$Update$isClickOnViewbox, model, minimapConfig, offsetX, offsetY);
				var _v3 = function () {
					if (clickedOnViewbox) {
						return _Utils_Tuple2(
							model.camera,
							A4($author$project$Update$minimapClickOffset, model, minimapConfig, offsetX, offsetY));
					} else {
						var scale = A2($author$project$Update$getMinimapScale, minimapConfig, model.mapConfig);
						var centered = A3(
							$author$project$Update$constrainCamera,
							model.mapConfig,
							model.windowSize,
							A4($author$project$Update$centerCameraOnMinimapClick, model, minimapConfig, offsetX, offsetY));
						var centerOffset = {x: (winWidth * scale) / 2, y: (winHeight * scale) / 2};
						return _Utils_Tuple2(centered, centerOffset);
					}
				}();
				var newCamera = _v3.a;
				var dragOffset = _v3.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							camera: newCamera,
							dragState: $author$project$Types$DraggingMinimap(dragOffset)
						}),
					$elm$core$Platform$Cmd$none);
			case 'MinimapMouseMove':
				var clientX = msg.a;
				var clientY = msg.b;
				var _v4 = model.dragState;
				if (_v4.$ === 'DraggingMinimap') {
					var offset = _v4.a;
					var minimapWidth = 200;
					var minimapHeight = 150;
					var _v5 = model.windowSize;
					var winWidth = _v5.a;
					var winHeight = _v5.b;
					var minimapTop = ((winHeight - 20) - 154) + 2;
					var offsetY = A3($elm$core$Basics$clamp, 0, minimapHeight, clientY - minimapTop);
					var minimapLeft = ((winWidth - 20) - 204) + 2;
					var offsetX = A3($elm$core$Basics$clamp, 0, minimapWidth, clientX - minimapLeft);
					var newCamera = A3(
						$author$project$Update$constrainCamera,
						model.mapConfig,
						model.windowSize,
						A4($author$project$Update$minimapDragToCamera, model, offset, offsetX, offsetY));
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{camera: newCamera}),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 'ShapesGenerated':
				var shapes = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{decorativeShapes: shapes}),
					$elm$core$Platform$Cmd$none);
			case 'GotViewport':
				var viewport = msg.a;
				var width = $elm$core$Basics$round(viewport.viewport.width);
				var height = $elm$core$Basics$round(viewport.viewport.height);
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							windowSize: _Utils_Tuple2(width, height)
						}),
					$elm$core$Platform$Cmd$none);
			case 'SelectThing':
				var thing = msg.a;
				var newBuildMode = function () {
					if (thing.$ === 'GlobalButtonBuild') {
						return model.buildMode;
					} else {
						return $elm$core$Maybe$Nothing;
					}
				}();
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							buildMode: newBuildMode,
							selected: $elm$core$Maybe$Just(thing)
						}),
					$elm$core$Platform$Cmd$none);
			case 'ToggleBuildGrid':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showBuildGrid: !model.showBuildGrid}),
					$elm$core$Platform$Cmd$none);
			case 'TogglePathfindingGrid':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showPathfindingGrid: !model.showPathfindingGrid}),
					$elm$core$Platform$Cmd$none);
			case 'GoldInputChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{goldInputValue: value}),
					$elm$core$Platform$Cmd$none);
			case 'SetGoldFromInput':
				var _v7 = $elm$core$String$toInt(model.goldInputValue);
				if (_v7.$ === 'Just') {
					var amount = _v7.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{gold: amount, goldInputValue: ''}),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 'TogglePathfindingOccupancy':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showPathfindingOccupancy: !model.showPathfindingOccupancy}),
					$elm$core$Platform$Cmd$none);
			case 'EnterBuildMode':
				var template = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							buildMode: $elm$core$Maybe$Just(template)
						}),
					$elm$core$Platform$Cmd$none);
			case 'ExitBuildMode':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{buildMode: $elm$core$Maybe$Nothing}),
					$elm$core$Platform$Cmd$none);
			case 'WorldMouseMove':
				var worldX = msg.a;
				var worldY = msg.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							mouseWorldPos: $elm$core$Maybe$Just(
								_Utils_Tuple2(worldX, worldY))
						}),
					$elm$core$Platform$Cmd$none);
			case 'PlaceBuilding':
				var _v8 = _Utils_Tuple2(model.buildMode, model.mouseWorldPos);
				if ((_v8.a.$ === 'Just') && (_v8.b.$ === 'Just')) {
					var template = _v8.a.a;
					var _v9 = _v8.b.a;
					var worldX = _v9.a;
					var worldY = _v9.b;
					var sizeCells = $author$project$Types$buildingSizeToGridCells(template.size);
					var gridY = $elm$core$Basics$floor(worldY / model.gridConfig.buildGridSize);
					var gridX = $elm$core$Basics$floor(worldX / model.gridConfig.buildGridSize);
					var centeredGridY = gridY - ((sizeCells / 2) | 0);
					var centeredGridX = gridX - ((sizeCells / 2) | 0);
					var isValid = A7($author$project$Grid$isValidBuildingPlacement, centeredGridX, centeredGridY, template.size, model.mapConfig, model.gridConfig, model.buildingOccupancy, model.buildings);
					var canAfford = _Utils_cmp(model.gold, template.cost) > -1;
					if (isValid && canAfford) {
						var newGameState = (_Utils_eq(model.gameState, $author$project$Types$PreGame) && (template.name === 'Castle')) ? $author$project$Types$Playing : model.gameState;
						var isCastle = template.name === 'Castle';
						var initialHp = isCastle ? template.maxHp : A2($elm$core$Basics$max, 1, (template.maxHp / 10) | 0);
						var initialGarrisonConfig = isCastle ? _List_fromArray(
							[
								{currentCount: 1, maxCount: 2, spawnTimer: 0, unitType: 'Castle Guard'},
								{currentCount: 1, maxCount: 1, spawnTimer: 0, unitType: 'Tax Collector'},
								{currentCount: 1, maxCount: 3, spawnTimer: 0, unitType: 'Peasant'}
							]) : _List_Nil;
						var initialGarrisonOccupied = A3(
							$elm$core$List$foldl,
							F2(
								function (slot, acc) {
									return acc + slot.currentCount;
								}),
							0,
							initialGarrisonConfig);
						var _v10 = isCastle ? _Utils_Tuple2(
							$author$project$Types$SpawnHouse,
							_List_fromArray(
								[$author$project$Types$BuildingTag, $author$project$Types$ObjectiveTag])) : _Utils_Tuple2(
							$author$project$Types$UnderConstruction,
							_List_fromArray(
								[$author$project$Types$BuildingTag]));
						var buildingBehavior = _v10.a;
						var buildingTags = _v10.b;
						var initialDuration = function () {
							switch (buildingBehavior.$) {
								case 'SpawnHouse':
									return 30.0 + (A2($elm$core$Basics$modBy, 15000, model.nextBuildingId * 1000) / 1000.0);
								case 'GenerateGold':
									return 15.0 + (A2($elm$core$Basics$modBy, 30000, model.nextBuildingId * 1000) / 1000.0);
								default:
									return 0;
							}
						}();
						var newBuilding = {activeRadius: 192, behavior: buildingBehavior, behaviorDuration: initialDuration, behaviorTimer: 0, buildingType: template.name, coffer: 0, garrisonConfig: initialGarrisonConfig, garrisonOccupied: initialGarrisonOccupied, garrisonSlots: template.garrisonSlots, gridX: centeredGridX, gridY: centeredGridY, hp: initialHp, id: model.nextBuildingId, maxHp: template.maxHp, owner: $author$project$Types$Player, searchRadius: 384, size: template.size, tags: buildingTags};
						var _v11 = function () {
							if (isCastle) {
								var unitsToCreate = _List_fromArray(
									[
										_Utils_Tuple2('Castle Guard', model.nextUnitId),
										_Utils_Tuple2('Tax Collector', model.nextUnitId + 1),
										_Utils_Tuple2('Peasant', model.nextUnitId + 2)
									]);
								return _Utils_Tuple2(
									A2(
										$elm$core$List$map,
										function (_v12) {
											var unitType = _v12.a;
											var unitId = _v12.b;
											return A4($author$project$GameHelpers$createHenchman, unitType, unitId, model.nextBuildingId, newBuilding);
										},
										unitsToCreate),
									model.nextUnitId + 3);
							} else {
								return _Utils_Tuple2(_List_Nil, model.nextUnitId);
							}
						}();
						var initialUnits = _v11.a;
						var nextUnitIdAfterInitial = _v11.b;
						var newBuildingOccupancy = A2($author$project$Grid$addBuildingGridOccupancy, newBuilding, model.buildingOccupancy);
						var newPathfindingOccupancy = A3($author$project$Grid$addBuildingOccupancy, model.gridConfig, newBuilding, model.pathfindingOccupancy);
						var updatedUnits = A4(
							$author$project$GameHelpers$recalculateAllPaths,
							model.gridConfig,
							model.mapConfig,
							newPathfindingOccupancy,
							_Utils_ap(model.units, initialUnits));
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									buildMode: $elm$core$Maybe$Nothing,
									buildingOccupancy: newBuildingOccupancy,
									buildings: A2($elm$core$List$cons, newBuilding, model.buildings),
									gameState: newGameState,
									gold: model.gold - template.cost,
									nextBuildingId: model.nextBuildingId + 1,
									nextUnitId: nextUnitIdAfterInitial,
									pathfindingOccupancy: newPathfindingOccupancy,
									units: updatedUnits
								}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 'ToggleBuildingOccupancy':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showBuildingOccupancy: !model.showBuildingOccupancy}),
					$elm$core$Platform$Cmd$none);
			case 'ToggleCityActiveArea':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showCityActiveArea: !model.showCityActiveArea}),
					$elm$core$Platform$Cmd$none);
			case 'ToggleCitySearchArea':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showCitySearchArea: !model.showCitySearchArea}),
					$elm$core$Platform$Cmd$none);
			case 'TooltipEnter':
				var elementId = msg.a;
				var x = msg.b;
				var y = msg.c;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							tooltipHover: $elm$core$Maybe$Just(
								{elementId: elementId, hoverTime: 0, mouseX: x, mouseY: y})
						}),
					$elm$core$Platform$Cmd$none);
			case 'TooltipLeave':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{tooltipHover: $elm$core$Maybe$Nothing}),
					$elm$core$Platform$Cmd$none);
			case 'SetSimulationSpeed':
				var speed = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{simulationSpeed: speed}),
					$elm$core$Platform$Cmd$none);
			case 'SetDebugTab':
				var tab = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{debugTab: tab}),
					$elm$core$Platform$Cmd$none);
			case 'SetBuildingTab':
				var tab = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{buildingTab: tab}),
					$elm$core$Platform$Cmd$none);
			default:
				var delta = msg.a;
				var updatedTooltipHover = function () {
					var _v44 = model.tooltipHover;
					if (_v44.$ === 'Just') {
						var tooltipState = _v44.a;
						return $elm$core$Maybe$Just(
							_Utils_update(
								tooltipState,
								{hoverTime: tooltipState.hoverTime + delta}));
					} else {
						return $elm$core$Maybe$Nothing;
					}
				}();
				var speedMultiplier = function () {
					var _v43 = model.simulationSpeed;
					switch (_v43.$) {
						case 'Pause':
							return 0;
						case 'Speed1x':
							return 1;
						case 'Speed2x':
							return 2;
						case 'Speed10x':
							return 10;
						default:
							return 100;
					}
				}();
				var simulationTimestep = 50.0;
				var isPaused = (delta > 1000) || _Utils_eq(model.simulationSpeed, $author$project$Types$Pause);
				var newAccumulatedTime = isPaused ? model.accumulatedTime : (model.accumulatedTime + (delta * speedMultiplier));
				var shouldSimulate = (_Utils_cmp(newAccumulatedTime, simulationTimestep) > -1) && (!isPaused);
				if (shouldSimulate) {
					var remainingTime = newAccumulatedTime - simulationTimestep;
					var newSimulationDeltas = A2(
						$elm$core$List$take,
						3,
						A2($elm$core$List$cons, newAccumulatedTime, model.lastSimulationDeltas));
					var deltaSeconds = simulationTimestep / 1000.0;
					var _v14 = A3(
						$elm$core$List$foldl,
						F2(
							function (unit, _v15) {
								var accUnits = _v15.a;
								var accOccupancy = _v15.b;
								var accNeedingPaths = _v15.c;
								var _v16 = unit.location;
								if (_v16.$ === 'OnMap') {
									var oldX = _v16.a;
									var oldY = _v16.b;
									var occupancyWithoutUnit = A4($author$project$Grid$removeUnitOccupancy, model.gridConfig, oldX, oldY, accOccupancy);
									var _v17 = A3($author$project$UnitBehavior$updateUnitBehavior, deltaSeconds, model.buildings, unit);
									var behaviorUpdatedUnit = _v17.a;
									var shouldGeneratePath = _v17.b;
									var movedUnit = A5($author$project$GameHelpers$updateUnitMovement, model.gridConfig, model.mapConfig, occupancyWithoutUnit, deltaSeconds, behaviorUpdatedUnit);
									var newOccupancyForUnit = function () {
										var _v18 = movedUnit.location;
										if (_v18.$ === 'OnMap') {
											var newX = _v18.a;
											var newY = _v18.b;
											return A4($author$project$Grid$addUnitOccupancy, model.gridConfig, newX, newY, occupancyWithoutUnit);
										} else {
											return occupancyWithoutUnit;
										}
									}();
									var needsPath = shouldGeneratePath ? A2($elm$core$List$cons, movedUnit, accNeedingPaths) : accNeedingPaths;
									return _Utils_Tuple3(
										A2($elm$core$List$cons, movedUnit, accUnits),
										newOccupancyForUnit,
										needsPath);
								} else {
									var _v19 = A3($author$project$UnitBehavior$updateUnitBehavior, deltaSeconds, model.buildings, unit);
									var behaviorUpdatedUnit = _v19.a;
									var shouldGeneratePath = _v19.b;
									var needsPath = shouldGeneratePath ? A2($elm$core$List$cons, behaviorUpdatedUnit, accNeedingPaths) : accNeedingPaths;
									return _Utils_Tuple3(
										A2($elm$core$List$cons, behaviorUpdatedUnit, accUnits),
										accOccupancy,
										needsPath);
								}
							}),
						_Utils_Tuple3(_List_Nil, model.pathfindingOccupancy, _List_Nil),
						model.units);
					var updatedUnits = _v14.a;
					var updatedOccupancy = _v14.b;
					var unitsNeedingPaths = _v14.c;
					var _v20 = A3(
						$elm$core$List$foldl,
						F2(
							function (building, _v21) {
								var accBuildings = _v21.a;
								var accNeedingHouseSpawn = _v21.b;
								var accHenchmenSpawn = _v21.c;
								var _v22 = A2($author$project$BuildingBehavior$updateBuildingBehavior, deltaSeconds, building);
								var behaviorUpdatedBuilding = _v22.a;
								var shouldSpawnHouse = _v22.b;
								var _v23 = A2($author$project$UnitBehavior$updateGarrisonSpawning, deltaSeconds, behaviorUpdatedBuilding);
								var garrisonUpdatedBuilding = _v23.a;
								var unitsToSpawn = _v23.b;
								var needsHouseSpawn = shouldSpawnHouse ? A2($elm$core$List$cons, garrisonUpdatedBuilding, accNeedingHouseSpawn) : accNeedingHouseSpawn;
								return _Utils_Tuple3(
									A2($elm$core$List$cons, garrisonUpdatedBuilding, accBuildings),
									needsHouseSpawn,
									_Utils_ap(unitsToSpawn, accHenchmenSpawn));
							}),
						_Utils_Tuple3(_List_Nil, _List_Nil, _List_Nil),
						model.buildings);
					var updatedBuildings = _v20.a;
					var buildingsNeedingHouseSpawn = _v20.b;
					var henchmenToSpawn = _v20.c;
					var _v24 = A3(
						$elm$core$List$foldl,
						F2(
							function (castleBuilding, _v27) {
								var _v28 = _v27.a;
								var accBuildings = _v28.a;
								var accBuildOcc = _v28.b;
								var _v29 = _v27.b;
								var accPfOcc = _v29.a;
								var currentBuildingId = _v29.b;
								var _v30 = A4($author$project$Grid$findAdjacentHouseLocation, model.mapConfig, model.gridConfig, accBuildings, accBuildOcc);
								if (_v30.$ === 'Just') {
									var _v31 = _v30.a;
									var gridX = _v31.a;
									var gridY = _v31.b;
									var newHouse = {
										activeRadius: 192,
										behavior: $author$project$Types$GenerateGold,
										behaviorDuration: 15.0 + (A2($elm$core$Basics$modBy, 30000, currentBuildingId * 1000) / 1000.0),
										behaviorTimer: 0,
										buildingType: 'House',
										coffer: 0,
										garrisonConfig: _List_Nil,
										garrisonOccupied: 0,
										garrisonSlots: 0,
										gridX: gridX,
										gridY: gridY,
										hp: 500,
										id: currentBuildingId,
										maxHp: 500,
										owner: $author$project$Types$Player,
										searchRadius: 384,
										size: $author$project$Types$Medium,
										tags: _List_fromArray(
											[$author$project$Types$BuildingTag, $author$project$Types$CofferTag])
									};
									var newPfOcc = A3($author$project$Grid$addBuildingOccupancy, model.gridConfig, newHouse, accPfOcc);
									var newBuildOcc = A2($author$project$Grid$addBuildingGridOccupancy, newHouse, accBuildOcc);
									return _Utils_Tuple2(
										_Utils_Tuple2(
											A2($elm$core$List$cons, newHouse, accBuildings),
											newBuildOcc),
										_Utils_Tuple2(newPfOcc, currentBuildingId + 1));
								} else {
									return _Utils_Tuple2(
										_Utils_Tuple2(accBuildings, accBuildOcc),
										_Utils_Tuple2(accPfOcc, currentBuildingId));
								}
							}),
						_Utils_Tuple2(
							_Utils_Tuple2(updatedBuildings, model.buildingOccupancy),
							_Utils_Tuple2(updatedOccupancy, model.nextBuildingId)),
						buildingsNeedingHouseSpawn);
					var _v25 = _v24.a;
					var buildingsAfterHouseSpawn = _v25.a;
					var buildingOccupancyAfterHouses = _v25.b;
					var _v26 = _v24.b;
					var pathfindingOccupancyAfterHouses = _v26.a;
					var nextBuildingIdAfterHouses = _v26.b;
					var _v32 = A3(
						$elm$core$List$foldl,
						F2(
							function (_v33, _v34) {
								var unitType = _v33.a;
								var buildingId = _v33.b;
								var accUnits = _v34.a;
								var currentUnitId = _v34.b;
								var _v35 = $elm$core$List$head(
									A2(
										$elm$core$List$filter,
										function (b) {
											return _Utils_eq(b.id, buildingId);
										},
										updatedBuildings));
								if (_v35.$ === 'Just') {
									var homeBuilding = _v35.a;
									var newUnit = A4($author$project$GameHelpers$createHenchman, unitType, currentUnitId, buildingId, homeBuilding);
									return _Utils_Tuple2(
										A2($elm$core$List$cons, newUnit, accUnits),
										currentUnitId + 1);
								} else {
									return _Utils_Tuple2(accUnits, currentUnitId);
								}
							}),
						_Utils_Tuple2(_List_Nil, model.nextUnitId),
						henchmenToSpawn);
					var newHenchmen = _v32.a;
					var nextUnitIdAfterSpawning = _v32.b;
					var allUnits = _Utils_ap(updatedUnits, newHenchmen);
					var unitsAfterHouseSpawn = $elm$core$List$isEmpty(buildingsNeedingHouseSpawn) ? allUnits : A4($author$project$GameHelpers$recalculateAllPaths, model.gridConfig, model.mapConfig, pathfindingOccupancyAfterHouses, allUnits);
					var buildingsAfterRepairs = A2(
						$elm$core$List$map,
						function (building) {
							var repairingPeasants = A2(
								$elm$core$List$filter,
								function (unit) {
									var _v40 = _Utils_Tuple2(unit.behavior, unit.location);
									if ((_v40.a.$ === 'Repairing') && (_v40.b.$ === 'OnMap')) {
										var _v41 = _v40.a;
										var _v42 = _v40.b;
										var x = _v42.a;
										var y = _v42.b;
										var canBuild = unit.behaviorTimer >= 0.15;
										var buildGridSize = 64;
										var buildingMinX = building.gridX * buildGridSize;
										var buildingMinY = building.gridY * buildGridSize;
										var buildingSize = $author$project$Types$buildingSizeToGridCells(building.size) * buildGridSize;
										var buildingMaxX = buildingMinX + buildingSize;
										var buildingMaxY = buildingMinY + buildingSize;
										var isNear = ((_Utils_cmp(x, buildingMinX - 48) > -1) && (_Utils_cmp(x, buildingMaxX + 48) < 1)) && ((_Utils_cmp(y, buildingMinY - 48) > -1) && (_Utils_cmp(y, buildingMaxY + 48) < 1));
										return isNear && (canBuild && (_Utils_cmp(building.hp, building.maxHp) < 0));
									} else {
										return false;
									}
								},
								unitsAfterHouseSpawn);
							var hpGain = $elm$core$List$length(repairingPeasants) * 5;
							var newHp = A2($elm$core$Basics$min, building.maxHp, building.hp + hpGain);
							var isConstructionComplete = _Utils_eq(building.behavior, $author$project$Types$UnderConstruction) && (_Utils_cmp(newHp, building.maxHp) > -1);
							var _v38 = function () {
								if (isConstructionComplete) {
									var _v39 = building.buildingType;
									switch (_v39) {
										case 'Warrior\'s Guild':
											return _Utils_Tuple3(
												$author$project$Types$GenerateGold,
												_List_fromArray(
													[$author$project$Types$BuildingTag, $author$project$Types$GuildTag, $author$project$Types$CofferTag]),
												15.0 + (A2($elm$core$Basics$modBy, 30000, building.id * 1000) / 1000.0));
										case 'House':
											return _Utils_Tuple3(
												$author$project$Types$GenerateGold,
												_List_fromArray(
													[$author$project$Types$BuildingTag, $author$project$Types$CofferTag]),
												15.0 + (A2($elm$core$Basics$modBy, 30000, building.id * 1000) / 1000.0));
										default:
											return _Utils_Tuple3(building.behavior, building.tags, building.behaviorDuration);
									}
								} else {
									return _Utils_Tuple3(building.behavior, building.tags, building.behaviorDuration);
								}
							}();
							var completedBehavior = _v38.a;
							var completedTags = _v38.b;
							var completedDuration = _v38.c;
							return _Utils_update(
								building,
								{behavior: completedBehavior, behaviorDuration: completedDuration, behaviorTimer: 0, hp: newHp, tags: completedTags});
						},
						buildingsAfterHouseSpawn);
					var newGameState = A2(
						$elm$core$List$any,
						function (b) {
							return A2($elm$core$List$member, $author$project$Types$ObjectiveTag, b.tags) && (b.hp <= 0);
						},
						buildingsAfterRepairs) ? $author$project$Types$GameOver : model.gameState;
					var unitsWithPaths = A2(
						$elm$core$List$map,
						function (unit) {
							var _v36 = _Utils_Tuple2(unit.location, unit.targetDestination);
							if ((_v36.a.$ === 'OnMap') && (_v36.b.$ === 'Just')) {
								var _v37 = _v36.a;
								var x = _v37.a;
								var y = _v37.b;
								var targetCell = _v36.b.a;
								var newPath = A6($author$project$Pathfinding$calculateUnitPath, model.gridConfig, model.mapConfig, pathfindingOccupancyAfterHouses, x, y, targetCell);
								return _Utils_update(
									unit,
									{path: newPath});
							} else {
								return unit;
							}
						},
						unitsAfterHouseSpawn);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{accumulatedTime: remainingTime, buildingOccupancy: buildingOccupancyAfterHouses, buildings: buildingsAfterRepairs, gameState: newGameState, lastSimulationDeltas: newSimulationDeltas, nextBuildingId: nextBuildingIdAfterHouses, nextUnitId: nextUnitIdAfterSpawning, pathfindingOccupancy: pathfindingOccupancyAfterHouses, simulationFrameCount: model.simulationFrameCount + 1, tooltipHover: updatedTooltipHover, units: unitsWithPaths}),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{accumulatedTime: newAccumulatedTime, tooltipHover: updatedTooltipHover}),
						$elm$core$Platform$Cmd$none);
				}
		}
	});
var $elm$json$Json$Encode$string = _Json_wrap;
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$div = _VirtualDom_node('div');
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$View$viewGameOverOverlay = function (model) {
	var _v0 = model.gameState;
	if (_v0.$ === 'GameOver') {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('overlay pe-none bg-black-alpha-9')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('font-mono font-bold text-red text-64')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('GAME OVER')
						]))
				]));
	} else {
		return $elm$html$Html$text('');
	}
};
var $author$project$Types$GlobalButtonBuild = {$: 'GlobalButtonBuild'};
var $author$project$Types$GlobalButtonDebug = {$: 'GlobalButtonDebug'};
var $author$project$Message$SelectThing = function (a) {
	return {$: 'SelectThing', a: a};
};
var $elm$core$String$fromFloat = _String_fromNumber;
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 'Normal', a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $author$project$View$viewGlobalButtonsPanel = F2(
	function (model, leftPosition) {
		var panelSize = 120;
		var button = F3(
			function (label, selectable, isSelected) {
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							'button text-12 font-bold' + (isSelected ? ' button--selected' : '')),
							$elm$html$Html$Attributes$class('w-full h-36'),
							$elm$html$Html$Events$onClick(
							$author$project$Message$SelectThing(selectable))
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(label)
						]));
			});
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('panel panel-col p-8 gap-6 abs bottom-20'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromFloat(leftPosition) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromInt(panelSize) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromInt(panelSize) + 'px')
				]),
			_List_fromArray(
				[
					A3(
					button,
					'Debug',
					$author$project$Types$GlobalButtonDebug,
					_Utils_eq(
						model.selected,
						$elm$core$Maybe$Just($author$project$Types$GlobalButtonDebug))),
					A3(
					button,
					'Build',
					$author$project$Types$GlobalButtonBuild,
					_Utils_eq(
						model.selected,
						$elm$core$Maybe$Just($author$project$Types$GlobalButtonBuild)))
				]));
	});
var $author$project$View$viewGoldCounter = function (model) {
	var isPaused = _Utils_eq(model.simulationSpeed, $author$project$Types$Pause);
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('flex items-center gap-8 rounded border-2 border-gold abs py-8 px-12 bottom-190 right-20 bg-black-alpha-7')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('square-20 rounded-full bg-gold border-2 border-gold')
					]),
				_List_Nil),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('text-gold font-mono font-bold text-18')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text(
						$elm$core$String$fromInt(model.gold))
					])),
				isPaused ? A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('font-mono font-bold text-12 text-red-6b')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('PAUSED')
					])) : $elm$html$Html$text('')
			]));
};
var $author$project$Message$MouseDown = F2(
	function (a, b) {
		return {$: 'MouseDown', a: a, b: b};
	});
var $author$project$Message$PlaceBuilding = {$: 'PlaceBuilding'};
var $author$project$Message$WorldMouseMove = F2(
	function (a, b) {
		return {$: 'WorldMouseMove', a: a, b: b};
	});
var $author$project$View$viewBuildingOccupancy = F3(
	function (model, viewportWidth, viewportHeight) {
		if (!model.showBuildingOccupancy) {
			return A2($elm$html$Html$div, _List_Nil, _List_Nil);
		} else {
			var gridSize = model.gridConfig.buildGridSize;
			var renderCell = function (_v0) {
				var x = _v0.a;
				var y = _v0.b;
				var worldY = y * gridSize;
				var worldX = x * gridSize;
				var screenY = worldY - model.camera.y;
				var screenX = worldX - model.camera.x;
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(screenX) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(screenY) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							$elm$html$Html$Attributes$class('bg-orange-alpha')
						]),
					_List_Nil);
			};
			var startGridX = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.x / gridSize));
			var startGridY = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.y / gridSize));
			var endGridY = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.height / gridSize),
				$elm$core$Basics$ceiling((model.camera.y + viewportHeight) / gridSize));
			var endGridX = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.width / gridSize),
				$elm$core$Basics$ceiling((model.camera.x + viewportWidth) / gridSize));
			var cellsY = A2($elm$core$List$range, startGridY, endGridY);
			var cellsX = A2($elm$core$List$range, startGridX, endGridX);
			var allCells = A2(
				$elm$core$List$concatMap,
				function (x) {
					return A2(
						$elm$core$List$map,
						function (y) {
							return _Utils_Tuple2(x, y);
						},
						cellsY);
				},
				cellsX);
			var occupiedCells = A2(
				$elm$core$List$filter,
				function (cell) {
					return A2($elm$core$Dict$member, cell, model.buildingOccupancy);
				},
				allCells);
			return A2(
				$elm$html$Html$div,
				_List_Nil,
				A2($elm$core$List$map, renderCell, occupiedCells));
		}
	});
var $author$project$View$viewBuildingPreview = function (model) {
	var _v0 = _Utils_Tuple2(model.buildMode, model.mouseWorldPos);
	if ((_v0.a.$ === 'Just') && (_v0.b.$ === 'Just')) {
		var template = _v0.a.a;
		var _v1 = _v0.b.a;
		var worldX = _v1.a;
		var worldY = _v1.b;
		var sizeCells = $author$project$Types$buildingSizeToGridCells(template.size);
		var gridY = $elm$core$Basics$floor(worldY / model.gridConfig.buildGridSize);
		var gridX = $elm$core$Basics$floor(worldX / model.gridConfig.buildGridSize);
		var centeredGridY = gridY - ((sizeCells / 2) | 0);
		var worldPosY = centeredGridY * model.gridConfig.buildGridSize;
		var screenY = worldPosY - model.camera.y;
		var centeredGridX = gridX - ((sizeCells / 2) | 0);
		var isValid = A7($author$project$Grid$isValidBuildingPlacement, centeredGridX, centeredGridY, template.size, model.mapConfig, model.gridConfig, model.buildingOccupancy, model.buildings) && (_Utils_cmp(model.gold, template.cost) > -1);
		var previewColor = isValid ? 'rgba(0, 255, 0, 0.5)' : 'rgba(255, 0, 0, 0.5)';
		var worldPosX = centeredGridX * model.gridConfig.buildGridSize;
		var screenX = worldPosX - model.camera.x;
		var buildingSizePx = sizeCells * model.gridConfig.buildGridSize;
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('abs pe-none'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromFloat(screenX) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromFloat(screenY) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat(buildingSizePx) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromFloat(buildingSizePx) + 'px'),
					A2($elm$html$Html$Attributes$style, 'background-color', previewColor),
					$elm$html$Html$Attributes$class('border-white-alpha flex items-center justify-center text-fff text-14 font-bold')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text(template.name)
				]));
	} else {
		return A2($elm$html$Html$div, _List_Nil, _List_Nil);
	}
};
var $author$project$Types$BuildingSelected = function (a) {
	return {$: 'BuildingSelected', a: a};
};
var $author$project$View$viewBuilding = F2(
	function (model, building) {
		var worldY = building.gridY * model.gridConfig.buildGridSize;
		var worldX = building.gridX * model.gridConfig.buildGridSize;
		var sizeCells = $author$project$Types$buildingSizeToGridCells(building.size);
		var screenY = worldY - model.camera.y;
		var screenX = worldX - model.camera.x;
		var isSelected = function () {
			var _v2 = model.selected;
			if ((_v2.$ === 'Just') && (_v2.a.$ === 'BuildingSelected')) {
				var id = _v2.a.a;
				return _Utils_eq(id, building.id);
			} else {
				return false;
			}
		}();
		var entranceTileSize = model.gridConfig.buildGridSize;
		var buildingSizePx = sizeCells * model.gridConfig.buildGridSize;
		var buildingColor = function () {
			var _v1 = building.buildingType;
			if (_v1 === 'Test Building') {
				return '#8B4513';
			} else {
				return '#666';
			}
		}();
		var _v0 = $author$project$Grid$getBuildingEntrance(building);
		var entranceGridX = _v0.a;
		var entranceGridY = _v0.b;
		var entranceOffsetX = (entranceGridX - building.gridX) * model.gridConfig.buildGridSize;
		var entranceOffsetY = (entranceGridY - building.gridY) * model.gridConfig.buildGridSize;
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('abs flex items-center justify-center text-white text-12 font-bold cursor-pointer select-none'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromFloat(screenX) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromFloat(screenY) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat(buildingSizePx) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromFloat(buildingSizePx) + 'px'),
					A2($elm$html$Html$Attributes$style, 'background-color', buildingColor),
					$elm$html$Html$Attributes$class('border-333'),
					$elm$html$Html$Events$onClick(
					$author$project$Message$SelectThing(
						$author$project$Types$BuildingSelected(building.id)))
				]),
			_List_fromArray(
				[
					$elm$html$Html$text(
					_Utils_ap(
						building.buildingType,
						_Utils_eq(building.behavior, $author$project$Types$UnderConstruction) ? ' (under construction)' : '')),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(entranceOffsetX) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(entranceOffsetY) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(entranceTileSize) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(entranceTileSize) + 'px'),
							$elm$html$Html$Attributes$class('bg-brown-entrance border-entrance')
						]),
					_List_Nil),
					isSelected ? A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none rounded bg-gold-selection'),
							A2($elm$html$Html$Attributes$style, 'inset', '0'),
							A2($elm$html$Html$Attributes$style, 'box-shadow', 'inset 0 0 10px rgba(255, 215, 0, 0.6)')
						]),
					_List_Nil) : $elm$html$Html$text(''),
					function () {
					var healthPercent = building.hp / building.maxHp;
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('bar bottom--8'),
								A2($elm$html$Html$Attributes$style, 'height', '4px')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('bar__fill'),
										A2(
										$elm$html$Html$Attributes$style,
										'width',
										$elm$core$String$fromFloat(healthPercent * 100) + '%')
									]),
								_List_Nil)
							]));
				}()
				]));
	});
var $author$project$View$viewBuildings = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_Nil,
		A2(
			$elm$core$List$map,
			$author$project$View$viewBuilding(model),
			model.buildings));
};
var $author$project$Grid$getCityActiveArea = function (buildings) {
	return $elm$core$Dict$keys(
		A3(
			$elm$core$List$foldl,
			F2(
				function (cell, acc) {
					return A3($elm$core$Dict$insert, cell, _Utils_Tuple0, acc);
				}),
			$elm$core$Dict$empty,
			A2(
				$elm$core$List$concatMap,
				function (b) {
					return A2($author$project$Grid$getBuildingAreaCells, b, 3);
				},
				A2(
					$elm$core$List$filter,
					function (b) {
						return _Utils_eq(b.owner, $author$project$Types$Player);
					},
					buildings))));
};
var $author$project$View$viewCityActiveArea = F3(
	function (model, viewportWidth, viewportHeight) {
		if (!model.showCityActiveArea) {
			return A2($elm$html$Html$div, _List_Nil, _List_Nil);
		} else {
			var gridSize = model.gridConfig.buildGridSize;
			var renderCell = function (_v0) {
				var x = _v0.a;
				var y = _v0.b;
				var worldY = y * gridSize;
				var worldX = x * gridSize;
				var screenY = worldY - model.camera.y;
				var screenX = worldX - model.camera.x;
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(screenX) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(screenY) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							$elm$html$Html$Attributes$class('bg-green-alpha-2')
						]),
					_List_Nil);
			};
			var startGridX = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.x / gridSize));
			var startGridY = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.y / gridSize));
			var endGridY = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.height / gridSize),
				$elm$core$Basics$ceiling((model.camera.y + viewportHeight) / gridSize));
			var endGridX = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.width / gridSize),
				$elm$core$Basics$ceiling((model.camera.x + viewportWidth) / gridSize));
			var cityCells = $author$project$Grid$getCityActiveArea(model.buildings);
			var cityDict = A3(
				$elm$core$List$foldl,
				F2(
					function (cell, acc) {
						return A3($elm$core$Dict$insert, cell, _Utils_Tuple0, acc);
					}),
				$elm$core$Dict$empty,
				cityCells);
			var cellsY = A2($elm$core$List$range, startGridY, endGridY);
			var cellsX = A2($elm$core$List$range, startGridX, endGridX);
			var allVisibleCells = A2(
				$elm$core$List$concatMap,
				function (x) {
					return A2(
						$elm$core$List$map,
						function (y) {
							return _Utils_Tuple2(x, y);
						},
						cellsY);
				},
				cellsX);
			var visibleCityCells = A2(
				$elm$core$List$filter,
				function (cell) {
					return A2($elm$core$Dict$member, cell, cityDict);
				},
				allVisibleCells);
			return A2(
				$elm$html$Html$div,
				_List_Nil,
				A2($elm$core$List$map, renderCell, visibleCityCells));
		}
	});
var $author$project$View$viewCitySearchArea = F3(
	function (model, viewportWidth, viewportHeight) {
		if (!model.showCitySearchArea) {
			return A2($elm$html$Html$div, _List_Nil, _List_Nil);
		} else {
			var gridSize = model.gridConfig.buildGridSize;
			var renderCell = function (_v0) {
				var x = _v0.a;
				var y = _v0.b;
				var worldY = y * gridSize;
				var worldX = x * gridSize;
				var screenY = worldY - model.camera.y;
				var screenX = worldX - model.camera.x;
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(screenX) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(screenY) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							$elm$html$Html$Attributes$class('bg-green-alpha-1')
						]),
					_List_Nil);
			};
			var startGridX = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.x / gridSize));
			var startGridY = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.y / gridSize));
			var endGridY = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.height / gridSize),
				$elm$core$Basics$ceiling((model.camera.y + viewportHeight) / gridSize));
			var endGridX = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.width / gridSize),
				$elm$core$Basics$ceiling((model.camera.x + viewportWidth) / gridSize));
			var cityCells = $author$project$Grid$getCitySearchArea(model.buildings);
			var cityDict = A3(
				$elm$core$List$foldl,
				F2(
					function (cell, acc) {
						return A3($elm$core$Dict$insert, cell, _Utils_Tuple0, acc);
					}),
				$elm$core$Dict$empty,
				cityCells);
			var cellsY = A2($elm$core$List$range, startGridY, endGridY);
			var cellsX = A2($elm$core$List$range, startGridX, endGridX);
			var allVisibleCells = A2(
				$elm$core$List$concatMap,
				function (x) {
					return A2(
						$elm$core$List$map,
						function (y) {
							return _Utils_Tuple2(x, y);
						},
						cellsY);
				},
				cellsX);
			var visibleCityCells = A2(
				$elm$core$List$filter,
				function (cell) {
					return A2($elm$core$Dict$member, cell, cityDict);
				},
				allVisibleCells);
			return A2(
				$elm$html$Html$div,
				_List_Nil,
				A2($elm$core$List$map, renderCell, visibleCityCells));
		}
	});
var $author$project$View$viewShape = F2(
	function (model, shape) {
		var screenY = shape.y - model.camera.y;
		var screenX = shape.x - model.camera.x;
		var _v0 = function () {
			var _v1 = shape.shapeType;
			if (_v1.$ === 'Circle') {
				return _Utils_Tuple2(
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('rounded-full')
						]),
					shape.size / 2);
			} else {
				return _Utils_Tuple2(_List_Nil, 0);
			}
		}();
		var shapeStyle = _v0.a;
		var shapeRadius = _v0.b;
		return A2(
			$elm$html$Html$div,
			_Utils_ap(
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('abs'),
						A2(
						$elm$html$Html$Attributes$style,
						'left',
						$elm$core$String$fromFloat(screenX - shapeRadius) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'top',
						$elm$core$String$fromFloat(screenY - shapeRadius) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'width',
						$elm$core$String$fromFloat(shape.size) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'height',
						$elm$core$String$fromFloat(shape.size) + 'px'),
						A2($elm$html$Html$Attributes$style, 'background-color', shape.color)
					]),
				shapeStyle),
			_List_Nil);
	});
var $author$project$View$viewDecorativeShapes = F3(
	function (model, viewportWidth, viewportHeight) {
		return A2(
			$elm$html$Html$div,
			_List_Nil,
			A2(
				$elm$core$List$map,
				$author$project$View$viewShape(model),
				model.decorativeShapes));
	});
var $author$project$View$viewGrid = F5(
	function (model, gridSize, color, viewportWidth, viewportHeight) {
		var terrainTop = 0 - model.camera.y;
		var terrainLeft = 0 - model.camera.x;
		var startY = A2(
			$elm$core$Basics$max,
			0,
			$elm$core$Basics$floor(model.camera.y / gridSize)) * $elm$core$Basics$round(gridSize);
		var startX = A2(
			$elm$core$Basics$max,
			0,
			$elm$core$Basics$floor(model.camera.x / gridSize)) * $elm$core$Basics$round(gridSize);
		var endY = A2($elm$core$Basics$min, model.mapConfig.height, model.camera.y + viewportHeight);
		var horizontalLines = A2(
			$elm$core$List$map,
			function (y) {
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none h-1'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(terrainLeft) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(y - model.camera.y) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(model.mapConfig.width) + 'px'),
							A2($elm$html$Html$Attributes$style, 'background-color', color)
						]),
					_List_Nil);
			},
			A2(
				$elm$core$List$map,
				function (i) {
					return i * $elm$core$Basics$round(gridSize);
				},
				A2(
					$elm$core$List$range,
					(startY / $elm$core$Basics$round(gridSize)) | 0,
					($elm$core$Basics$round(endY) / $elm$core$Basics$round(gridSize)) | 0)));
		var endX = A2($elm$core$Basics$min, model.mapConfig.width, model.camera.x + viewportWidth);
		var verticalLines = A2(
			$elm$core$List$map,
			function (x) {
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none w-1'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(x - model.camera.x) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(terrainTop) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(model.mapConfig.height) + 'px'),
							A2($elm$html$Html$Attributes$style, 'background-color', color)
						]),
					_List_Nil);
			},
			A2(
				$elm$core$List$map,
				function (i) {
					return i * $elm$core$Basics$round(gridSize);
				},
				A2(
					$elm$core$List$range,
					(startX / $elm$core$Basics$round(gridSize)) | 0,
					($elm$core$Basics$round(endX) / $elm$core$Basics$round(gridSize)) | 0)));
		return _Utils_ap(verticalLines, horizontalLines);
	});
var $author$project$View$viewGrids = F3(
	function (model, viewportWidth, viewportHeight) {
		return A2(
			$elm$html$Html$div,
			_List_Nil,
			_Utils_ap(
				model.showBuildGrid ? A5($author$project$View$viewGrid, model, model.gridConfig.buildGridSize, 'rgba(255, 255, 0, 0.3)', viewportWidth, viewportHeight) : _List_Nil,
				model.showPathfindingGrid ? A5($author$project$View$viewGrid, model, model.gridConfig.pathfindingGridSize, 'rgba(0, 255, 255, 0.3)', viewportWidth, viewportHeight) : _List_Nil));
	});
var $author$project$View$viewPathfindingOccupancy = F3(
	function (model, viewportWidth, viewportHeight) {
		if (!model.showPathfindingOccupancy) {
			return A2($elm$html$Html$div, _List_Nil, _List_Nil);
		} else {
			var gridSize = model.gridConfig.pathfindingGridSize;
			var renderCell = function (_v0) {
				var x = _v0.a;
				var y = _v0.b;
				var worldY = y * gridSize;
				var worldX = x * gridSize;
				var screenY = worldY - model.camera.y;
				var screenX = worldX - model.camera.x;
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(screenX) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(screenY) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(gridSize) + 'px'),
							$elm$html$Html$Attributes$class('bg-dark-blue')
						]),
					_List_Nil);
			};
			var startPfX = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.x / gridSize));
			var startPfY = A2(
				$elm$core$Basics$max,
				0,
				$elm$core$Basics$floor(model.camera.y / gridSize));
			var endPfY = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.height / gridSize),
				$elm$core$Basics$ceiling((model.camera.y + viewportHeight) / gridSize));
			var endPfX = A2(
				$elm$core$Basics$min,
				$elm$core$Basics$floor(model.mapConfig.width / gridSize),
				$elm$core$Basics$ceiling((model.camera.x + viewportWidth) / gridSize));
			var cellsY = A2($elm$core$List$range, startPfY, endPfY);
			var cellsX = A2($elm$core$List$range, startPfX, endPfX);
			var allCells = A2(
				$elm$core$List$concatMap,
				function (x) {
					return A2(
						$elm$core$List$map,
						function (y) {
							return _Utils_Tuple2(x, y);
						},
						cellsY);
				},
				cellsX);
			var occupiedCells = A2(
				$elm$core$List$filter,
				function (cell) {
					return A2($author$project$Grid$isPathfindingCellOccupied, cell, model.pathfindingOccupancy);
				},
				allCells);
			return A2(
				$elm$html$Html$div,
				_List_Nil,
				A2($elm$core$List$map, renderCell, occupiedCells));
		}
	});
var $author$project$View$viewSelectedUnitPath = function (model) {
	var _v0 = model.selected;
	if ((_v0.$ === 'Just') && (_v0.a.$ === 'UnitSelected')) {
		var unitId = _v0.a.a;
		var maybeUnit = $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (u) {
					return _Utils_eq(u.id, unitId);
				},
				model.units));
		if (maybeUnit.$ === 'Just') {
			var unit = maybeUnit.a;
			return A2(
				$elm$html$Html$div,
				_List_Nil,
				A2(
					$elm$core$List$map,
					function (_v2) {
						var cellX = _v2.a;
						var cellY = _v2.b;
						var worldY = (cellY * model.gridConfig.pathfindingGridSize) + (model.gridConfig.pathfindingGridSize / 2);
						var worldX = (cellX * model.gridConfig.pathfindingGridSize) + (model.gridConfig.pathfindingGridSize / 2);
						var screenY = worldY - model.camera.y;
						var screenX = worldX - model.camera.x;
						var dotSize = 6;
						return A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('abs pe-none rounded-full bg-gold border border-gold opacity-80'),
									A2(
									$elm$html$Html$Attributes$style,
									'left',
									$elm$core$String$fromFloat(screenX - (dotSize / 2)) + 'px'),
									A2(
									$elm$html$Html$Attributes$style,
									'top',
									$elm$core$String$fromFloat(screenY - (dotSize / 2)) + 'px'),
									A2(
									$elm$html$Html$Attributes$style,
									'width',
									$elm$core$String$fromFloat(dotSize) + 'px'),
									A2(
									$elm$html$Html$Attributes$style,
									'height',
									$elm$core$String$fromFloat(dotSize) + 'px')
								]),
							_List_Nil);
					},
					unit.path));
		} else {
			return $elm$html$Html$text('');
		}
	} else {
		return $elm$html$Html$text('');
	}
};
var $author$project$View$viewTerrain = F3(
	function (model, viewportWidth, viewportHeight) {
		var terrainWidth = model.mapConfig.width;
		var terrainTop = 0 - model.camera.y;
		var terrainLeft = 0 - model.camera.x;
		var terrainHeight = model.mapConfig.height;
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('abs'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromFloat(terrainLeft) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromFloat(terrainTop) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat(terrainWidth) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromFloat(terrainHeight) + 'px'),
					$elm$html$Html$Attributes$class('bg-map')
				]),
			_List_Nil);
	});
var $author$project$View$viewUnitRadii = function (model) {
	var _v0 = model.selected;
	if ((_v0.$ === 'Just') && (_v0.a.$ === 'UnitSelected')) {
		var unitId = _v0.a.a;
		var maybeUnit = $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (u) {
					return _Utils_eq(u.id, unitId);
				},
				model.units));
		if (maybeUnit.$ === 'Just') {
			var unit = maybeUnit.a;
			var _v2 = unit.location;
			if (_v2.$ === 'OnMap') {
				var x = _v2.a;
				var y = _v2.b;
				var screenY = y - model.camera.y;
				var screenX = x - model.camera.x;
				var searchCircle = A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none rounded-full'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(screenX - unit.searchRadius) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(screenY - unit.searchRadius) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(unit.searchRadius * 2) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(unit.searchRadius * 2) + 'px'),
							$elm$html$Html$Attributes$class('border-yellow-alpha-3')
						]),
					_List_Nil);
				var activeCircle = A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none rounded-full'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromFloat(screenX - unit.activeRadius) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromFloat(screenY - unit.activeRadius) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(unit.activeRadius * 2) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(unit.activeRadius * 2) + 'px'),
							$elm$html$Html$Attributes$class('border-yellow-alpha-6')
						]),
					_List_Nil);
				return A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[searchCircle, activeCircle]));
			} else {
				return A2($elm$html$Html$div, _List_Nil, _List_Nil);
			}
		} else {
			return A2($elm$html$Html$div, _List_Nil, _List_Nil);
		}
	} else {
		return A2($elm$html$Html$div, _List_Nil, _List_Nil);
	}
};
var $author$project$Types$UnitSelected = function (a) {
	return {$: 'UnitSelected', a: a};
};
var $author$project$View$viewUnit = F4(
	function (model, unit, worldX, worldY) {
		var visualDiameter = model.gridConfig.pathfindingGridSize / 2;
		var visualRadius = visualDiameter / 2;
		var selectionDiameter = visualDiameter * 2;
		var selectionRadius = selectionDiameter / 2;
		var screenY = worldY - model.camera.y;
		var screenX = worldX - model.camera.x;
		var isSelected = function () {
			var _v1 = model.selected;
			if ((_v1.$ === 'Just') && (_v1.a.$ === 'UnitSelected')) {
				var id = _v1.a.a;
				return _Utils_eq(id, unit.id);
			} else {
				return false;
			}
		}();
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('abs cursor-pointer select-none flex items-center justify-center'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromFloat(screenX - selectionRadius) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromFloat(screenY - selectionRadius) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat(selectionDiameter) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromFloat(selectionDiameter) + 'px'),
					$elm$html$Html$Events$onClick(
					$author$project$Message$SelectThing(
						$author$project$Types$UnitSelected(unit.id)))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('rounded-full flex items-center justify-center text-white font-bold pe-none border-333 text-8'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(visualDiameter) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(visualDiameter) + 'px'),
							A2($elm$html$Html$Attributes$style, 'background-color', unit.color)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(
							function () {
								var _v0 = unit.unitType;
								switch (_v0) {
									case 'Peasant':
										return 'P';
									case 'Tax Collector':
										return 'T';
									case 'Castle Guard':
										return 'G';
									default:
										return '?';
								}
							}())
						])),
					isSelected ? A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('abs pe-none rounded-full bg-gold-selection'),
							A2(
							$elm$html$Html$Attributes$style,
							'width',
							$elm$core$String$fromFloat(visualDiameter) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromFloat(visualDiameter) + 'px'),
							A2($elm$html$Html$Attributes$style, 'box-shadow', 'inset 0 0 10px rgba(255, 215, 0, 0.6)')
						]),
					_List_Nil) : $elm$html$Html$text(''),
					function () {
					var healthPercent = unit.hp / unit.maxHp;
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('bar'),
								A2(
								$elm$html$Html$Attributes$style,
								'bottom',
								$elm$core$String$fromFloat((selectionRadius - visualRadius) - 6) + 'px'),
								A2($elm$html$Html$Attributes$style, 'height', '3px')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('bar__fill'),
										A2(
										$elm$html$Html$Attributes$style,
										'width',
										$elm$core$String$fromFloat(healthPercent * 100) + '%')
									]),
								_List_Nil)
							]));
				}()
				]));
	});
var $author$project$View$viewUnits = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_Nil,
		A2(
			$elm$core$List$filterMap,
			function (unit) {
				var _v0 = unit.location;
				if (_v0.$ === 'OnMap') {
					var x = _v0.a;
					var y = _v0.b;
					return $elm$core$Maybe$Just(
						A4($author$project$View$viewUnit, model, unit, x, y));
				} else {
					return $elm$core$Maybe$Nothing;
				}
			},
			model.units));
};
var $author$project$View$viewMainViewport = F4(
	function (model, cursor, viewportWidth, viewportHeight) {
		var handleMouseMove = function () {
			var _v1 = model.buildMode;
			if (_v1.$ === 'Just') {
				return A2(
					$elm$html$Html$Events$on,
					'mousemove',
					A3(
						$elm$json$Json$Decode$map2,
						F2(
							function (clientX, clientY) {
								var worldY = model.camera.y + clientY;
								var worldX = model.camera.x + clientX;
								return A2($author$project$Message$WorldMouseMove, worldX, worldY);
							}),
						A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
						A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float)));
			} else {
				return $elm$html$Html$Attributes$class('');
			}
		}();
		var handleMouseDown = function () {
			var _v0 = model.buildMode;
			if (_v0.$ === 'Just') {
				return A2(
					$elm$html$Html$Events$on,
					'mousedown',
					$elm$json$Json$Decode$succeed($author$project$Message$PlaceBuilding));
			} else {
				return A2(
					$elm$html$Html$Events$on,
					'mousedown',
					A3(
						$elm$json$Json$Decode$map2,
						$author$project$Message$MouseDown,
						A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
						A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float)));
			}
		}();
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('main-viewport'),
					A2($elm$html$Html$Attributes$style, 'cursor', cursor),
					handleMouseDown,
					handleMouseMove
				]),
			_List_fromArray(
				[
					A3($author$project$View$viewTerrain, model, viewportWidth, viewportHeight),
					A3($author$project$View$viewDecorativeShapes, model, viewportWidth, viewportHeight),
					$author$project$View$viewBuildings(model),
					$author$project$View$viewUnits(model),
					$author$project$View$viewSelectedUnitPath(model),
					A3($author$project$View$viewGrids, model, viewportWidth, viewportHeight),
					A3($author$project$View$viewPathfindingOccupancy, model, viewportWidth, viewportHeight),
					A3($author$project$View$viewBuildingOccupancy, model, viewportWidth, viewportHeight),
					A3($author$project$View$viewCitySearchArea, model, viewportWidth, viewportHeight),
					A3($author$project$View$viewCityActiveArea, model, viewportWidth, viewportHeight),
					$author$project$View$viewBuildingPreview(model),
					$author$project$View$viewUnitRadii(model)
				]));
	});
var $author$project$Message$MinimapMouseDown = F2(
	function (a, b) {
		return {$: 'MinimapMouseDown', a: a, b: b};
	});
var $author$project$View$decodeMinimapMouseEvent = function (msg) {
	return A3(
		$elm$json$Json$Decode$map2,
		F2(
			function (x, y) {
				return _Utils_Tuple2(
					A2(msg, x, y),
					true);
			}),
		A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
		A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float));
};
var $elm$virtual_dom$VirtualDom$MayStopPropagation = function (a) {
	return {$: 'MayStopPropagation', a: a};
};
var $elm$html$Html$Events$stopPropagationOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayStopPropagation(decoder));
	});
var $author$project$View$viewMinimapBuilding = F3(
	function (scale, buildGridSize, building) {
		var worldY = building.gridY * buildGridSize;
		var worldX = building.gridX * buildGridSize;
		var minimapY = worldY * scale;
		var minimapX = worldX * scale;
		var buildingSizeCells = $author$project$Types$buildingSizeToGridCells(building.size);
		var worldHeight = buildingSizeCells * buildGridSize;
		var minimapHeight = worldHeight * scale;
		var worldWidth = buildingSizeCells * buildGridSize;
		var minimapWidth = worldWidth * scale;
		var buildingColor = function () {
			var _v0 = building.owner;
			if (_v0.$ === 'Player') {
				return '#7FFFD4';
			} else {
				return '#FF0000';
			}
		}();
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('abs'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromFloat(minimapX) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromFloat(minimapY) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat(minimapWidth) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromFloat(minimapHeight) + 'px'),
					A2($elm$html$Html$Attributes$style, 'background-color', buildingColor),
					$elm$html$Html$Attributes$class('pe-none')
				]),
			_List_Nil);
	});
var $author$project$View$viewMinimapUnit = F2(
	function (scale, unit) {
		var _v0 = unit.location;
		if (_v0.$ === 'OnMap') {
			var worldX = _v0.a;
			var worldY = _v0.b;
			var unitColor = function () {
				var _v1 = unit.owner;
				if (_v1.$ === 'Player') {
					return '#7FFFD4';
				} else {
					return '#FF0000';
				}
			}();
			var minimapY = worldY * scale;
			var minimapX = worldX * scale;
			var dotSize = 3;
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('abs pe-none'),
						A2(
						$elm$html$Html$Attributes$style,
						'left',
						$elm$core$String$fromFloat(minimapX - (dotSize / 2)) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'top',
						$elm$core$String$fromFloat(minimapY - (dotSize / 2)) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'width',
						$elm$core$String$fromFloat(dotSize) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'height',
						$elm$core$String$fromFloat(dotSize) + 'px'),
						A2($elm$html$Html$Attributes$style, 'background-color', unitColor),
						$elm$html$Html$Attributes$class('rounded-full')
					]),
				_List_Nil);
		} else {
			return $elm$html$Html$text('');
		}
	});
var $author$project$View$viewMinimap = function (model) {
	var padding = 10;
	var minimapWidth = 200;
	var minimapHeight = 150;
	var scale = A2($elm$core$Basics$min, (minimapWidth - (padding * 2)) / model.mapConfig.width, (minimapHeight - (padding * 2)) / model.mapConfig.height);
	var viewportIndicatorX = padding + (model.camera.x * scale);
	var viewportIndicatorY = padding + (model.camera.y * scale);
	var cursor = function () {
		var _v1 = model.dragState;
		switch (_v1.$) {
			case 'DraggingViewport':
				return 'grabbing';
			case 'DraggingMinimap':
				return 'grabbing';
			default:
				return 'grab';
		}
	}();
	var _v0 = model.windowSize;
	var winWidth = _v0.a;
	var winHeight = _v0.b;
	var viewportIndicatorHeight = winHeight * scale;
	var viewportIndicatorWidth = winWidth * scale;
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('abs bottom-20 right-20 overflow-visible bg-333 border-fff'),
				A2(
				$elm$html$Html$Attributes$style,
				'width',
				$elm$core$String$fromInt(minimapWidth) + 'px'),
				A2(
				$elm$html$Html$Attributes$style,
				'height',
				$elm$core$String$fromInt(minimapHeight) + 'px'),
				A2($elm$html$Html$Attributes$style, 'cursor', cursor),
				A2(
				$elm$html$Html$Events$stopPropagationOn,
				'mousedown',
				$author$project$View$decodeMinimapMouseEvent($author$project$Message$MinimapMouseDown))
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						A2(
						$elm$html$Html$Attributes$style,
						'width',
						$elm$core$String$fromFloat(model.mapConfig.width * scale) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'height',
						$elm$core$String$fromFloat(model.mapConfig.height * scale) + 'px'),
						$elm$html$Html$Attributes$class('bg-map rel border-fff-1'),
						A2(
						$elm$html$Html$Attributes$style,
						'left',
						$elm$core$String$fromFloat(padding) + 'px'),
						A2(
						$elm$html$Html$Attributes$style,
						'top',
						$elm$core$String$fromFloat(padding) + 'px')
					]),
				_Utils_ap(
					A2(
						$elm$core$List$map,
						A2($author$project$View$viewMinimapBuilding, scale, model.gridConfig.buildGridSize),
						model.buildings),
					_Utils_ap(
						A2(
							$elm$core$List$map,
							$author$project$View$viewMinimapUnit(scale),
							model.units),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('abs pe-none minimap-viewport'),
										A2(
										$elm$html$Html$Attributes$style,
										'left',
										$elm$core$String$fromFloat(model.camera.x * scale) + 'px'),
										A2(
										$elm$html$Html$Attributes$style,
										'top',
										$elm$core$String$fromFloat(model.camera.y * scale) + 'px'),
										A2(
										$elm$html$Html$Attributes$style,
										'width',
										$elm$core$String$fromFloat(viewportIndicatorWidth) + 'px'),
										A2(
										$elm$html$Html$Attributes$style,
										'height',
										$elm$core$String$fromFloat(viewportIndicatorHeight) + 'px')
									]),
								_List_Nil)
							]))))
			]));
};
var $author$project$View$viewPreGameOverlay = function (model) {
	var _v0 = model.gameState;
	if (_v0.$ === 'PreGame') {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('panel font-mono font-bold text-gold pe-none fix right-20 border-gold py-16 px-24 border-gold-3 text-18'),
					A2($elm$html$Html$Attributes$style, 'top', '20px'),
					A2($elm$html$Html$Attributes$style, 'z-index', '1000')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Site your Castle')
				]));
	} else {
		return $elm$html$Html$text('');
	}
};
var $author$project$Types$ControlsTab = {$: 'ControlsTab'};
var $author$project$Message$EnterBuildMode = function (a) {
	return {$: 'EnterBuildMode', a: a};
};
var $author$project$Message$ExitBuildMode = {$: 'ExitBuildMode'};
var $author$project$Message$GoldInputChanged = function (a) {
	return {$: 'GoldInputChanged', a: a};
};
var $author$project$Types$InfoTab = {$: 'InfoTab'};
var $author$project$Message$SetBuildingTab = function (a) {
	return {$: 'SetBuildingTab', a: a};
};
var $author$project$Message$SetDebugTab = function (a) {
	return {$: 'SetDebugTab', a: a};
};
var $author$project$Message$SetGoldFromInput = {$: 'SetGoldFromInput'};
var $author$project$Message$SetSimulationSpeed = function (a) {
	return {$: 'SetSimulationSpeed', a: a};
};
var $author$project$Types$Speed100x = {$: 'Speed100x'};
var $author$project$Types$Speed10x = {$: 'Speed10x'};
var $author$project$Types$Speed2x = {$: 'Speed2x'};
var $author$project$Message$ToggleBuildGrid = {$: 'ToggleBuildGrid'};
var $author$project$Message$ToggleBuildingOccupancy = {$: 'ToggleBuildingOccupancy'};
var $author$project$Message$ToggleCityActiveArea = {$: 'ToggleCityActiveArea'};
var $author$project$Message$ToggleCitySearchArea = {$: 'ToggleCitySearchArea'};
var $author$project$Message$TogglePathfindingGrid = {$: 'TogglePathfindingGrid'};
var $author$project$Message$TogglePathfindingOccupancy = {$: 'TogglePathfindingOccupancy'};
var $author$project$Message$TooltipEnter = F3(
	function (a, b, c) {
		return {$: 'TooltipEnter', a: a, b: b, c: c};
	});
var $author$project$Message$TooltipLeave = {$: 'TooltipLeave'};
var $author$project$Types$VisualizationTab = {$: 'VisualizationTab'};
var $author$project$Types$Huge = {$: 'Huge'};
var $author$project$BuildingTemplates$castleTemplate = {cost: 10000, garrisonSlots: 6, maxHp: 5000, name: 'Castle', size: $author$project$Types$Huge};
var $elm$html$Html$Attributes$classList = function (classes) {
	return $elm$html$Html$Attributes$class(
		A2(
			$elm$core$String$join,
			' ',
			A2(
				$elm$core$List$map,
				$elm$core$Tuple$first,
				A2($elm$core$List$filter, $elm$core$Tuple$second, classes))));
};
var $elm$html$Html$input = _VirtualDom_node('input');
var $elm$core$List$intersperse = F2(
	function (sep, xs) {
		if (!xs.b) {
			return _List_Nil;
		} else {
			var hd = xs.a;
			var tl = xs.b;
			var step = F2(
				function (x, rest) {
					return A2(
						$elm$core$List$cons,
						sep,
						A2($elm$core$List$cons, x, rest));
				});
			var spersed = A3($elm$core$List$foldr, step, _List_Nil, tl);
			return A2($elm$core$List$cons, hd, spersed);
		}
	});
var $elm$html$Html$Events$alwaysStop = function (x) {
	return _Utils_Tuple2(x, true);
};
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $elm$json$Json$Decode$string = _Json_decodeString;
var $elm$html$Html$Events$targetValue = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'value']),
	$elm$json$Json$Decode$string);
var $elm$html$Html$Events$onInput = function (tagger) {
	return A2(
		$elm$html$Html$Events$stopPropagationOn,
		'input',
		A2(
			$elm$json$Json$Decode$map,
			$elm$html$Html$Events$alwaysStop,
			A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetValue)));
};
var $elm$html$Html$Events$onMouseLeave = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseleave',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$html$Html$Attributes$placeholder = $elm$html$Html$Attributes$stringProperty('placeholder');
var $author$project$BuildingTemplates$testBuildingTemplate = {cost: 500, garrisonSlots: 5, maxHp: 500, name: 'Test Building', size: $author$project$Types$Medium};
var $elm$html$Html$Attributes$type_ = $elm$html$Html$Attributes$stringProperty('type');
var $elm$html$Html$Attributes$value = $elm$html$Html$Attributes$stringProperty('value');
var $author$project$Types$Large = {$: 'Large'};
var $author$project$BuildingTemplates$warriorsGuildTemplate = {cost: 1500, garrisonSlots: 0, maxHp: 1000, name: 'Warrior\'s Guild', size: $author$project$Types$Large};
var $author$project$View$viewSelectionPanel = F2(
	function (model, panelWidth) {
		var unitSelectedContent = function (unitId) {
			var maybeUnit = $elm$core$List$head(
				A2(
					$elm$core$List$filter,
					function (u) {
						return _Utils_eq(u.id, unitId);
					},
					model.units));
			if (maybeUnit.$ === 'Just') {
				var unit = maybeUnit.a;
				var tagToString = function (tag) {
					switch (tag.$) {
						case 'BuildingTag':
							return 'Building';
						case 'HeroTag':
							return 'Hero';
						case 'HenchmanTag':
							return 'Henchman';
						case 'GuildTag':
							return 'Guild';
						case 'ObjectiveTag':
							return 'Objective';
						default:
							return 'Coffer';
					}
				};
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('p-12 font-mono text-11 flex gap-16 text-fff')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('flex flex-col gap-4')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('font-bold text-12')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(unit.unitType)
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('text-9 text-aaa flex gap-4')
										]),
									_Utils_ap(
										_List_fromArray(
											[
												$elm$html$Html$text('[')
											]),
										_Utils_ap(
											A2(
												$elm$core$List$intersperse,
												$elm$html$Html$text(', '),
												A2(
													$elm$core$List$map,
													function (tag) {
														return A2(
															$elm$html$Html$div,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('cursor-help'),
																	A2(
																	$elm$html$Html$Events$on,
																	'mouseenter',
																	A3(
																		$elm$json$Json$Decode$map2,
																		F2(
																			function (x, y) {
																				return A3(
																					$author$project$Message$TooltipEnter,
																					'tag-' + tagToString(tag),
																					x,
																					y);
																			}),
																		A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
																		A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
																	$elm$html$Html$Events$onMouseLeave($author$project$Message$TooltipLeave)
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text(
																	tagToString(tag))
																]));
													},
													unit.tags)),
											_List_fromArray(
												[
													$elm$html$Html$text(']')
												])))),
									A2(
									$elm$html$Html$div,
									_List_Nil,
									_List_fromArray(
										[
											$elm$html$Html$text(
											'HP: ' + ($elm$core$String$fromInt(unit.hp) + ('/' + $elm$core$String$fromInt(unit.maxHp))))
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('flex flex-col gap-4')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_Nil,
									_List_fromArray(
										[
											$elm$html$Html$text(
											'Speed: ' + ($elm$core$String$fromFloat(unit.movementSpeed) + ' cells/s'))
										])),
									A2(
									$elm$html$Html$div,
									_List_Nil,
									_List_fromArray(
										[
											$elm$html$Html$text(
											'Owner: ' + function () {
												var _v14 = unit.owner;
												if (_v14.$ === 'Player') {
													return 'Player';
												} else {
													return 'Enemy';
												}
											}())
										])),
									A2(
									$elm$html$Html$div,
									_List_Nil,
									_List_fromArray(
										[
											$elm$html$Html$text(
											'Location: ' + function () {
												var _v15 = unit.location;
												if (_v15.$ === 'OnMap') {
													var x = _v15.a;
													var y = _v15.b;
													return '(' + ($elm$core$String$fromInt(
														$elm$core$Basics$round(x)) + (', ' + ($elm$core$String$fromInt(
														$elm$core$Basics$round(y)) + ')')));
												} else {
													var buildingId = _v15.a;
													return 'Garrisoned in #' + $elm$core$String$fromInt(buildingId);
												}
											}())
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cursor-help'),
											A2(
											$elm$html$Html$Events$on,
											'mouseenter',
											A3(
												$elm$json$Json$Decode$map2,
												F2(
													function (x, y) {
														return A3(
															$author$project$Message$TooltipEnter,
															'behavior-' + function () {
																var _v16 = unit.behavior;
																switch (_v16.$) {
																	case 'Dead':
																		return 'Dead';
																	case 'DebugError':
																		var msg = _v16.a;
																		return 'Error: ' + msg;
																	case 'WithoutHome':
																		return 'Without Home';
																	case 'LookingForTask':
																		return 'Looking for Task';
																	case 'GoingToSleep':
																		return 'Going to Sleep';
																	case 'Sleeping':
																		return 'Sleeping';
																	case 'LookForBuildRepairTarget':
																		return 'Looking for Build/Repair';
																	case 'MovingToBuildRepairTarget':
																		return 'Moving to Building';
																	case 'Repairing':
																		return 'Repairing';
																	case 'LookForTaxTarget':
																		return 'Looking for Tax Target';
																	case 'CollectingTaxes':
																		return 'Collecting Taxes';
																	case 'ReturnToCastle':
																		return 'Returning to Castle';
																	default:
																		return 'Delivering Gold';
																}
															}(),
															x,
															y);
													}),
												A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
												A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
											$elm$html$Html$Events$onMouseLeave($author$project$Message$TooltipLeave)
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											'Behavior: ' + function () {
												var _v17 = unit.behavior;
												switch (_v17.$) {
													case 'Dead':
														return 'Dead';
													case 'DebugError':
														var msg = _v17.a;
														return 'Error: ' + msg;
													case 'WithoutHome':
														return 'Without Home';
													case 'LookingForTask':
														return 'Looking for Task';
													case 'GoingToSleep':
														return 'Going to Sleep';
													case 'Sleeping':
														return 'Sleeping';
													case 'LookForBuildRepairTarget':
														return 'Looking for Build/Repair';
													case 'MovingToBuildRepairTarget':
														return 'Moving to Building';
													case 'Repairing':
														return 'Repairing';
													case 'LookForTaxTarget':
														return 'Looking for Tax Target';
													case 'CollectingTaxes':
														return 'Collecting Taxes';
													case 'ReturnToCastle':
														return 'Returning to Castle';
													default:
														return 'Delivering Gold';
												}
											}())
										]))
								]))
						]));
			} else {
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('p-12 text-red text-12')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Unit not found')
						]));
			}
		};
		var panelHeight = 120;
		var noSelectionContent = A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('p-12 italic flex items-center text-14'),
					A2($elm$html$Html$Attributes$style, 'color', '#888'),
					A2($elm$html$Html$Attributes$style, 'height', '100%')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('No selection')
				]));
		var debugVisualizationContent = function () {
			var checkbox = F3(
				function (isChecked, label, onClick) {
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex items-center gap-8 cursor-pointer'),
								$elm$html$Html$Events$onClick(onClick)
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('square-14 border-neon-green rounded-sm'),
										A2(
										$elm$html$Html$Attributes$style,
										'background-color',
										isChecked ? '#0f0' : 'transparent')
									]),
								_List_Nil),
								$elm$html$Html$text(label)
							]));
				});
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('p-12 font-mono text-11 flex gap-16 text-green')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex flex-col gap-6')
							]),
						_List_fromArray(
							[
								A3(checkbox, model.showBuildGrid, 'Build Grid', $author$project$Message$ToggleBuildGrid),
								A3(checkbox, model.showPathfindingGrid, 'Pathfinding Grid', $author$project$Message$TogglePathfindingGrid)
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex flex-col gap-6')
							]),
						_List_fromArray(
							[
								A3(checkbox, model.showPathfindingOccupancy, 'PF Occupancy', $author$project$Message$TogglePathfindingOccupancy),
								A3(checkbox, model.showBuildingOccupancy, 'Build Occupancy', $author$project$Message$ToggleBuildingOccupancy)
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex flex-col gap-6')
							]),
						_List_fromArray(
							[
								A3(checkbox, model.showCityActiveArea, 'City Active', $author$project$Message$ToggleCityActiveArea),
								A3(checkbox, model.showCitySearchArea, 'City Search', $author$project$Message$ToggleCitySearchArea)
							]))
					]));
		}();
		var debugStatsContent = function (m) {
			var avgDelta = $elm$core$List$isEmpty(m.lastSimulationDeltas) ? 0 : ($elm$core$List$sum(m.lastSimulationDeltas) / $elm$core$List$length(m.lastSimulationDeltas));
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('p-12 font-mono text-11 flex gap-16 text-green')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex flex-col gap-6')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_Nil,
								_List_fromArray(
									[
										$elm$html$Html$text('Camera: ('),
										$elm$html$Html$text(
										$elm$core$String$fromFloat(m.camera.x)),
										$elm$html$Html$text(', '),
										$elm$html$Html$text(
										$elm$core$String$fromFloat(m.camera.y)),
										$elm$html$Html$text(')')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_Nil),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-gold text-12 font-bold')
									]),
								_List_Nil)
							]))
					]));
		};
		var debugInfoSection = function () {
			var avgDelta = $elm$core$List$isEmpty(model.lastSimulationDeltas) ? 0 : ($elm$core$List$sum(model.lastSimulationDeltas) / $elm$core$List$length(model.lastSimulationDeltas));
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('p-12 font-mono text-11 flex flex-col gap-6 text-neon-green shrink-0')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								$elm$html$Html$text('Camera: ('),
								$elm$html$Html$text(
								$elm$core$String$fromFloat(model.camera.x)),
								$elm$html$Html$text(', '),
								$elm$html$Html$text(
								$elm$core$String$fromFloat(model.camera.y)),
								$elm$html$Html$text(')')
							])),
						A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								$elm$html$Html$text('Gold: '),
								$elm$html$Html$text(
								$elm$core$String$fromInt(model.gold))
							])),
						A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								$elm$html$Html$text('Sim Frame: '),
								$elm$html$Html$text(
								$elm$core$String$fromInt(model.simulationFrameCount))
							])),
						A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								$elm$html$Html$text('Avg Delta: '),
								$elm$html$Html$text(
								$elm$core$String$fromFloat(
									function (x) {
										return x / 10;
									}(
										$elm$core$Basics$round(avgDelta * 10)))),
								$elm$html$Html$text('ms')
							]))
					]));
		}();
		var debugGridSection = A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('p-12 font-mono text-11 flex flex-col gap-6'),
					A2($elm$html$Html$Attributes$style, 'color', '#0f0'),
					A2($elm$html$Html$Attributes$style, 'flex-shrink', '0'),
					A2($elm$html$Html$Attributes$style, 'border-left', '1px solid #0f0')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex items-center gap-8 cursor-pointer'),
							$elm$html$Html$Events$onClick($author$project$Message$ToggleBuildGrid)
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('square-14 border-2 border-neon rounded-sm'),
									$elm$html$Html$Attributes$classList(
									_List_fromArray(
										[
											_Utils_Tuple2('bg-neon', model.showBuildGrid)
										]))
								]),
							_List_Nil),
							$elm$html$Html$text('Build Grid')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex items-center gap-8 cursor-pointer'),
							$elm$html$Html$Events$onClick($author$project$Message$TogglePathfindingGrid)
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('square-14 border-2 border-neon rounded-sm'),
									$elm$html$Html$Attributes$classList(
									_List_fromArray(
										[
											_Utils_Tuple2('bg-neon', model.showPathfindingGrid)
										]))
								]),
							_List_Nil),
							$elm$html$Html$text('Pathfinding Grid')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex items-center gap-8 cursor-pointer'),
							$elm$html$Html$Events$onClick($author$project$Message$TogglePathfindingOccupancy)
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('square-14 border-2 border-neon rounded-sm'),
									$elm$html$Html$Attributes$classList(
									_List_fromArray(
										[
											_Utils_Tuple2('bg-neon', model.showPathfindingOccupancy)
										]))
								]),
							_List_Nil),
							$elm$html$Html$text('PF Occupancy')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex items-center gap-8 cursor-pointer'),
							$elm$html$Html$Events$onClick($author$project$Message$ToggleBuildingOccupancy)
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('square-14 border-2 border-neon rounded-sm'),
									$elm$html$Html$Attributes$classList(
									_List_fromArray(
										[
											_Utils_Tuple2('bg-neon', model.showBuildingOccupancy)
										]))
								]),
							_List_Nil),
							$elm$html$Html$text('Build Occupancy')
						]))
				]));
		var debugControlsContent = function () {
			var speedRadio = F2(
				function (speed, label) {
					var isSelected = _Utils_eq(model.simulationSpeed, speed);
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex items-center gap-6 cursor-pointer'),
								$elm$html$Html$Events$onClick(
								$author$project$Message$SetSimulationSpeed(speed))
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('square-12 rounded-full border-neon-green flex items-center justify-center')
									]),
								_List_fromArray(
									[
										isSelected ? A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('square-6 rounded-full bg-neon-green')
											]),
										_List_Nil) : $elm$html$Html$text('')
									])),
								$elm$html$Html$text(label)
							]));
				});
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('p-12 font-mono text-11 flex gap-16 text-green')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex flex-col gap-6')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_Nil,
								_List_fromArray(
									[
										$elm$html$Html$text('Speed:')
									])),
								A2(speedRadio, $author$project$Types$Pause, '0x'),
								A2(speedRadio, $author$project$Types$Speed1x, '1x'),
								A2(speedRadio, $author$project$Types$Speed2x, '2x'),
								A2(speedRadio, $author$project$Types$Speed10x, '10x'),
								A2(speedRadio, $author$project$Types$Speed100x, '100x')
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex flex-col gap-10')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex flex-col gap-6')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_Nil,
										_List_fromArray(
											[
												$elm$html$Html$text('Gold:')
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('flex gap-4')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$input,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$type_('text'),
														$elm$html$Html$Attributes$value(model.goldInputValue),
														$elm$html$Html$Attributes$placeholder('Amount'),
														$elm$html$Html$Events$onInput($author$project$Message$GoldInputChanged),
														$elm$html$Html$Attributes$class('w-80 p-4 bg-222 text-neon-green border-neon-1 rounded-sm'),
														$elm$html$Html$Attributes$class('font-mono text-11')
													]),
												_List_Nil),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('py-4 px-8 bg-neon-green text-000 rounded-sm cursor-pointer font-bold text-10'),
														$elm$html$Html$Events$onClick($author$project$Message$SetGoldFromInput)
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('SET')
													]))
											]))
									]))
							]))
					]));
		}();
		var debugTabbedContent = function (m) {
			var tabContent = function () {
				var _v12 = m.debugTab;
				switch (_v12.$) {
					case 'StatsTab':
						return debugStatsContent(m);
					case 'VisualizationTab':
						return debugVisualizationContent;
					default:
						return debugControlsContent;
				}
			}();
			var tabButton = F2(
				function (tab, label) {
					var isActive = _Utils_eq(m.debugTab, tab);
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('button font-mono text-10 font-bold py-6 px-12'),
								A2(
								$elm$html$Html$Attributes$style,
								'background-color',
								isActive ? '#0f0' : '#222'),
								A2(
								$elm$html$Html$Attributes$style,
								'color',
								isActive ? '#000' : '#0f0'),
								$elm$html$Html$Attributes$class('rounded-3'),
								$elm$html$Html$Events$onClick(
								$author$project$Message$SetDebugTab(tab))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(label)
							]));
				});
			var tabsColumn = A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('flex flex-col gap-4 p-8'),
						A2($elm$html$Html$Attributes$style, 'border-right', '1px solid #0f0'),
						A2($elm$html$Html$Attributes$style, 'flex-shrink', '0')
					]),
				_List_fromArray(
					[
						A2(tabButton, $author$project$Types$StatsTab, 'STATS'),
						A2(tabButton, $author$project$Types$VisualizationTab, 'VISUAL'),
						A2(tabButton, $author$project$Types$ControlsTab, 'CONTROLS')
					]));
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('flex')
					]),
				_List_fromArray(
					[tabsColumn, tabContent]));
		};
		var buildingSelectedContent = function (buildingId) {
			var maybeBuilding = $elm$core$List$head(
				A2(
					$elm$core$List$filter,
					function (b) {
						return _Utils_eq(b.id, buildingId);
					},
					model.buildings));
			if (maybeBuilding.$ === 'Just') {
				var building = maybeBuilding.a;
				var tagToString = function (tag) {
					switch (tag.$) {
						case 'BuildingTag':
							return 'Building';
						case 'HeroTag':
							return 'Hero';
						case 'HenchmanTag':
							return 'Henchman';
						case 'GuildTag':
							return 'Guild';
						case 'ObjectiveTag':
							return 'Objective';
						default:
							return 'Coffer';
					}
				};
				var tabContent = function () {
					var _v7 = model.buildingTab;
					if (_v7.$ === 'MainTab') {
						return A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('flex gap-16 items-start')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('flex flex-col gap-4')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('font-bold text-12')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(
													_Utils_ap(
														building.buildingType,
														_Utils_eq(building.behavior, $author$project$Types$UnderConstruction) ? ' (under construction)' : ''))
												])),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('text-9 text-muted flex gap-4')
												]),
											_Utils_ap(
												_List_fromArray(
													[
														$elm$html$Html$text('[')
													]),
												_Utils_ap(
													A2(
														$elm$core$List$intersperse,
														$elm$html$Html$text(', '),
														A2(
															$elm$core$List$map,
															function (tag) {
																return A2(
																	$elm$html$Html$div,
																	_List_fromArray(
																		[
																			A2($elm$html$Html$Attributes$style, 'cursor', 'help'),
																			A2(
																			$elm$html$Html$Events$on,
																			'mouseenter',
																			A3(
																				$elm$json$Json$Decode$map2,
																				F2(
																					function (x, y) {
																						return A3(
																							$author$project$Message$TooltipEnter,
																							'tag-' + tagToString(tag),
																							x,
																							y);
																					}),
																				A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
																				A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
																			$elm$html$Html$Events$onMouseLeave($author$project$Message$TooltipLeave)
																		]),
																	_List_fromArray(
																		[
																			$elm$html$Html$text(
																			tagToString(tag))
																		]));
															},
															building.tags)),
													_List_fromArray(
														[
															$elm$html$Html$text(']')
														])))),
											A2(
											$elm$html$Html$div,
											_List_Nil,
											_List_fromArray(
												[
													$elm$html$Html$text(
													'HP: ' + ($elm$core$String$fromInt(building.hp) + ('/' + $elm$core$String$fromInt(building.maxHp))))
												])),
											A2(
											$elm$html$Html$div,
											_List_Nil,
											_List_fromArray(
												[
													$elm$html$Html$text(
													'Owner: ' + function () {
														var _v8 = building.owner;
														if (_v8.$ === 'Player') {
															return 'Player';
														} else {
															return 'Enemy';
														}
													}())
												]))
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('flex flex-col gap-4')
										]),
									$elm$core$List$isEmpty(building.garrisonConfig) ? _List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													A2($elm$html$Html$Attributes$style, 'cursor', 'help'),
													A2(
													$elm$html$Html$Events$on,
													'mouseenter',
													A3(
														$elm$json$Json$Decode$map2,
														F2(
															function (x, y) {
																return A3(
																	$author$project$Message$TooltipEnter,
																	'garrison-' + $elm$core$String$fromInt(building.id),
																	x,
																	y);
															}),
														A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
														A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
													$elm$html$Html$Events$onMouseLeave($author$project$Message$TooltipLeave)
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(
													'Garrison: ' + ($elm$core$String$fromInt(building.garrisonOccupied) + ('/' + $elm$core$String$fromInt(building.garrisonSlots))))
												]))
										]) : _Utils_ap(
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_Nil,
												_List_fromArray(
													[
														$elm$html$Html$text('Garrison:')
													]))
											]),
										A2(
											$elm$core$List$map,
											function (slot) {
												return A2(
													$elm$html$Html$div,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$class('text-10 text-muted'),
															A2($elm$html$Html$Attributes$style, 'padding-left', '8px')
														]),
													_List_fromArray(
														[
															$elm$html$Html$text(
															'  ' + (slot.unitType + (': ' + ($elm$core$String$fromInt(slot.currentCount) + ('/' + $elm$core$String$fromInt(slot.maxCount))))))
														]));
											},
											building.garrisonConfig)))
								]));
					} else {
						return A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('flex gap-16 items-start')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('flex flex-col gap-8')
										]),
									_Utils_ap(
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														A2($elm$html$Html$Attributes$style, 'cursor', 'help'),
														A2(
														$elm$html$Html$Events$on,
														'mouseenter',
														A3(
															$elm$json$Json$Decode$map2,
															F2(
																function (x, y) {
																	return A3(
																		$author$project$Message$TooltipEnter,
																		'behavior-' + function () {
																			var _v9 = building.behavior;
																			switch (_v9.$) {
																				case 'Idle':
																					return 'Idle';
																				case 'UnderConstruction':
																					return 'Under Construction';
																				case 'SpawnHouse':
																					return 'Spawn House';
																				case 'GenerateGold':
																					return 'Generate Gold';
																				case 'BuildingDead':
																					return 'Dead';
																				default:
																					var msg = _v9.a;
																					return 'Error: ' + msg;
																			}
																		}(),
																		x,
																		y);
																}),
															A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
															A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
														$elm$html$Html$Events$onMouseLeave($author$project$Message$TooltipLeave)
													]),
												_List_fromArray(
													[
														$elm$html$Html$text(
														'Behavior: ' + function () {
															var _v10 = building.behavior;
															switch (_v10.$) {
																case 'Idle':
																	return 'Idle';
																case 'UnderConstruction':
																	return 'Under Construction';
																case 'SpawnHouse':
																	return 'Spawn House';
																case 'GenerateGold':
																	return 'Generate Gold';
																case 'BuildingDead':
																	return 'Dead';
																default:
																	var msg = _v10.a;
																	return 'Error: ' + msg;
															}
														}())
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('text-10 text-aaa')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text(
														'Timer: ' + ($elm$core$String$fromFloat(
															function (x) {
																return x / 10;
															}(
																$elm$core$Basics$round(building.behaviorTimer * 10))) + ('s / ' + ($elm$core$String$fromFloat(
															function (x) {
																return x / 10;
															}(
																$elm$core$Basics$round(building.behaviorDuration * 10))) + 's'))))
													]))
											]),
										A2($elm$core$List$member, $author$project$Types$CofferTag, building.tags) ? _List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_Nil,
												_List_fromArray(
													[
														$elm$html$Html$text(
														'Coffer: ' + ($elm$core$String$fromInt(building.coffer) + ' gold'))
													]))
											]) : _List_Nil)),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('flex flex-col gap-4')
										]),
									(!$elm$core$List$isEmpty(building.garrisonConfig)) ? _Utils_ap(
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_Nil,
												_List_fromArray(
													[
														$elm$html$Html$text('Garrison Cooldowns:')
													]))
											]),
										A2(
											$elm$core$List$map,
											function (slot) {
												return A2(
													$elm$html$Html$div,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$class('text-10 text-muted'),
															A2($elm$html$Html$Attributes$style, 'padding-left', '8px')
														]),
													_List_fromArray(
														[
															$elm$html$Html$text(
															'  ' + (slot.unitType + (': ' + ((_Utils_cmp(slot.currentCount, slot.maxCount) < 0) ? ($elm$core$String$fromFloat(
																function (x) {
																	return x / 10;
																}(
																	$elm$core$Basics$round(slot.spawnTimer * 10))) + 's / 30.0s') : 'Full'))))
														]));
											},
											building.garrisonConfig)) : _List_Nil)
								]));
					}
				}();
				var tabButton = F2(
					function (label, tab) {
						return A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('py-6 px-12 cursor-pointer rounded-top text-10 font-bold select-none'),
									A2(
									$elm$html$Html$Attributes$style,
									'background-color',
									_Utils_eq(model.buildingTab, tab) ? '#555' : '#333'),
									$elm$html$Html$Events$onClick(
									$author$project$Message$SetBuildingTab(tab))
								]),
							_List_fromArray(
								[
									$elm$html$Html$text(label)
								]));
					});
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex flex-col')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('flex gap-4 pt-8 pr-8 pl-8 pb-0')
								]),
							_List_fromArray(
								[
									A2(tabButton, 'Main', $author$project$Types$MainTab),
									A2(tabButton, 'Info', $author$project$Types$InfoTab)
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('p-12 font-mono text-11'),
									A2($elm$html$Html$Attributes$style, 'color', '#fff')
								]),
							_List_fromArray(
								[tabContent]))
						]));
			} else {
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('p-12 text-red text-12')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Building not found')
						]));
			}
		};
		var buildingOption = function (template) {
			var sizeLabel = function () {
				var _v5 = template.size;
				switch (_v5.$) {
					case 'Small':
						return '1×1';
					case 'Medium':
						return '2×2';
					case 'Large':
						return '3×3';
					default:
						return '4×4';
				}
			}();
			var isActive = function () {
				var _v4 = model.buildMode;
				if (_v4.$ === 'Just') {
					var activeTemplate = _v4.a;
					return _Utils_eq(activeTemplate.name, template.name);
				} else {
					return false;
				}
			}();
			var canAfford = _Utils_cmp(model.gold, template.cost) > -1;
			var clickHandler = canAfford ? (isActive ? $elm$html$Html$Events$onClick($author$project$Message$ExitBuildMode) : $elm$html$Html$Events$onClick(
				$author$project$Message$EnterBuildMode(template))) : $elm$html$Html$Attributes$class('');
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('flex flex-col items-center gap-4 p-8 rounded shrink-0 rel border-2'),
						$elm$html$Html$Attributes$classList(
						_List_fromArray(
							[
								_Utils_Tuple2('bg-333', canAfford),
								_Utils_Tuple2('bg-222', !canAfford),
								_Utils_Tuple2('border-dark', !canAfford),
								_Utils_Tuple2('cursor-pointer', canAfford),
								_Utils_Tuple2('cursor-not-allowed', !canAfford),
								_Utils_Tuple2('opacity-50', !canAfford)
							])),
						clickHandler,
						A2(
						$elm$html$Html$Events$on,
						'mouseenter',
						A3(
							$elm$json$Json$Decode$map2,
							F2(
								function (x, y) {
									return A3($author$project$Message$TooltipEnter, 'building-' + template.name, x, y);
								}),
							A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
							A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float))),
						$elm$html$Html$Events$onMouseLeave($author$project$Message$TooltipLeave)
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-12 text-fff font-bold')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(template.name)
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-10 text-muted')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(sizeLabel)
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-gold text-12 font-bold')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm$core$String$fromInt(template.cost) + 'g')
							])),
						isActive ? A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('abs pe-none rounded bg-white-alpha-3'),
								A2($elm$html$Html$Attributes$style, 'inset', '0'),
								A2($elm$html$Html$Attributes$style, 'box-shadow', 'inset 0 0 10px rgba(255, 255, 255, 0.6)')
							]),
						_List_Nil) : $elm$html$Html$text('')
					]));
		};
		var buildContent = function () {
			var _v3 = model.gameState;
			switch (_v3.$) {
				case 'PreGame':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex gap-8 p-8')
							]),
						_List_fromArray(
							[
								buildingOption($author$project$BuildingTemplates$castleTemplate)
							]));
				case 'Playing':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex gap-8 p-8')
							]),
						_List_fromArray(
							[
								buildingOption($author$project$BuildingTemplates$testBuildingTemplate),
								buildingOption($author$project$BuildingTemplates$warriorsGuildTemplate)
							]));
				default:
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('p-12 text-red font-mono text-14 font-bold')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('GAME OVER')
							]));
			}
		}();
		var content = function () {
			var _v0 = model.selected;
			if (_v0.$ === 'Nothing') {
				return _List_fromArray(
					[noSelectionContent]);
			} else {
				switch (_v0.a.$) {
					case 'GlobalButtonDebug':
						var _v1 = _v0.a;
						return _List_fromArray(
							[
								debugTabbedContent(model)
							]);
					case 'GlobalButtonBuild':
						var _v2 = _v0.a;
						return _List_fromArray(
							[buildContent]);
					case 'BuildingSelected':
						var buildingId = _v0.a.a;
						return _List_fromArray(
							[
								buildingSelectedContent(buildingId)
							]);
					default:
						var unitId = _v0.a.a;
						return _List_fromArray(
							[
								unitSelectedContent(unitId)
							]);
				}
			}
		}();
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('panel abs bottom-20 right-224'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat(panelWidth) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromInt(panelHeight) + 'px'),
					A2($elm$html$Html$Attributes$style, 'overflow-x', 'scroll'),
					A2($elm$html$Html$Attributes$style, 'overflow-y', 'hidden'),
					A2($elm$html$Html$Attributes$style, '-webkit-overflow-scrolling', 'touch'),
					A2($elm$html$Html$Attributes$style, 'scrollbar-width', 'auto'),
					A2($elm$html$Html$Attributes$style, 'scrollbar-color', '#888 #222')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex items-start w-max'),
							A2($elm$html$Html$Attributes$style, 'min-width', '100%')
						]),
					content)
				]));
	});
var $author$project$BuildingTemplates$houseTemplate = {cost: 0, garrisonSlots: 0, maxHp: 500, name: 'House', size: $author$project$Types$Medium};
var $author$project$View$viewTooltip = function (model) {
	var _v0 = model.tooltipHover;
	if (_v0.$ === 'Just') {
		var tooltipState = _v0.a;
		if (tooltipState.hoverTime >= 500) {
			var _v1 = tooltipState.elementId;
			switch (_v1) {
				case 'building-Test Building':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none py-8 px-12'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 100) + 'px')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('font-bold'),
										A2($elm$html$Html$Attributes$style, 'margin-bottom', '4px')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Test Building')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'HP: ' + $elm$core$String$fromInt($author$project$BuildingTemplates$testBuildingTemplate.maxHp))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Size: 2×2')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'Garrison: ' + $elm$core$String$fromInt($author$project$BuildingTemplates$testBuildingTemplate.garrisonSlots))
									]))
							]));
				case 'building-Castle':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none py-8 px-12'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 120) + 'px')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('font-bold'),
										A2($elm$html$Html$Attributes$style, 'margin-bottom', '4px')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Castle')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'HP: ' + $elm$core$String$fromInt($author$project$BuildingTemplates$castleTemplate.maxHp))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Size: 4×4')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'Garrison: ' + ($elm$core$String$fromInt($author$project$BuildingTemplates$castleTemplate.garrisonSlots) + ' henchmen'))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-gold'),
										A2($elm$html$Html$Attributes$style, 'margin-top', '4px')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Mission-critical building')
									]))
							]));
				case 'building-House':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none py-8 px-12'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 100) + 'px')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('font-bold'),
										A2($elm$html$Html$Attributes$style, 'margin-bottom', '4px')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('House')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'HP: ' + $elm$core$String$fromInt($author$project$BuildingTemplates$houseTemplate.maxHp))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Size: 2×2')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-gold'),
										A2($elm$html$Html$Attributes$style, 'margin-top', '4px')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Generates gold')
									]))
							]));
				case 'building-Warrior\'s Guild':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none py-8 px-12'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 100) + 'px')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('font-bold'),
										A2($elm$html$Html$Attributes$style, 'margin-bottom', '4px')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Warrior\'s Guild')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'HP: ' + $elm$core$String$fromInt($author$project$BuildingTemplates$warriorsGuildTemplate.maxHp))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-muted')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Size: 3×3')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-gold'),
										A2($elm$html$Html$Attributes$style, 'margin-top', '4px')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Trains warriors, generates gold')
									]))
							]));
				case 'tag-Building':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('This is a building')
							]));
				case 'tag-Hero':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('This is a hero')
							]));
				case 'tag-Henchman':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('This is a henchman')
							]));
				case 'tag-Guild':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('This building produces and houses Heroes')
							]));
				case 'tag-Objective':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('If this dies, the player loses the game')
							]));
				case 'tag-Coffer':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('This building has a Gold Coffer')
							]));
				case 'behavior-Idle':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('The building is not performing any actions')
							]));
				case 'behavior-Under Construction':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('The building is under construction')
							]));
				case 'behavior-Spawn House':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('The Castle is periodically spawning Houses for the kingdom')
							]));
				case 'behavior-Generate Gold':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('The building is generating gold into its coffer')
							]));
				case 'behavior-Thinking':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('The unit is pausing before deciding on next action')
							]));
				case 'behavior-Finding Target':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('The unit is calculating a path to a random destination')
							]));
				case 'behavior-Moving':
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('tooltip pe-none'),
								A2(
								$elm$html$Html$Attributes$style,
								'left',
								$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
								A2(
								$elm$html$Html$Attributes$style,
								'top',
								$elm$core$String$fromFloat(tooltipState.mouseY - 50) + 'px')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('The unit is following its path to the destination')
							]));
				default:
					if (A2($elm$core$String$startsWith, 'garrison-', tooltipState.elementId)) {
						var buildingIdStr = A2($elm$core$String$dropLeft, 9, tooltipState.elementId);
						var maybeBuildingId = $elm$core$String$toInt(buildingIdStr);
						var maybeBuilding = function () {
							if (maybeBuildingId.$ === 'Just') {
								var buildingId = maybeBuildingId.a;
								return $elm$core$List$head(
									A2(
										$elm$core$List$filter,
										function (b) {
											return _Utils_eq(b.id, buildingId);
										},
										model.buildings));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						}();
						if (maybeBuilding.$ === 'Just') {
							var building = maybeBuilding.a;
							return A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('tooltip pe-none py-8 px-12'),
										A2(
										$elm$html$Html$Attributes$style,
										'left',
										$elm$core$String$fromFloat(tooltipState.mouseX) + 'px'),
										A2(
										$elm$html$Html$Attributes$style,
										'top',
										$elm$core$String$fromFloat(tooltipState.mouseY - 80) + 'px')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('font-bold'),
												A2($elm$html$Html$Attributes$style, 'margin-bottom', '4px')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Garrison')
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-muted')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(
												'Current: ' + $elm$core$String$fromInt(building.garrisonOccupied))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-muted')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(
												'Capacity: ' + $elm$core$String$fromInt(building.garrisonSlots))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-muted')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Next unit: Not implemented')
											]))
									]));
						} else {
							return $elm$html$Html$text('');
						}
					} else {
						return $elm$html$Html$text('');
					}
			}
		} else {
			return $elm$html$Html$text('');
		}
	} else {
		return $elm$html$Html$text('');
	}
};
var $author$project$View$view = function (model) {
	var selectionPanelMinWidth = 100;
	var selectionPanelMaxWidth = 700;
	var selectionPanelBorder = 4;
	var panelGap = 10;
	var minimapWidth = 204;
	var minimapMargin = 20;
	var globalButtonsWidth = 120;
	var globalButtonsMargin = 20;
	var globalButtonsBorder = 4;
	var cursor = function () {
		var _v1 = model.dragState;
		switch (_v1.$) {
			case 'DraggingViewport':
				return 'grabbing';
			case 'DraggingMinimap':
				return 'grabbing';
			default:
				return 'grab';
		}
	}();
	var aspectRatio = 4 / 3;
	var _v0 = model.windowSize;
	var winWidth = _v0.a;
	var winHeight = _v0.b;
	var viewportHeight = winHeight;
	var initialAvailableWidth = (winWidth - (minimapWidth + minimapMargin)) - selectionPanelBorder;
	var trialSelectionPanelWidth = A3($elm$core$Basics$clamp, selectionPanelMinWidth, selectionPanelMaxWidth, initialAvailableWidth);
	var totalPanelsWidth = (((globalButtonsWidth + globalButtonsBorder) + panelGap) + $elm$core$Basics$round(trialSelectionPanelWidth)) + selectionPanelBorder;
	var canStickToPanel = _Utils_cmp(totalPanelsWidth, ((winWidth - minimapWidth) - minimapMargin) - globalButtonsMargin) < 1;
	var selectionPanelWidth = function () {
		if (canStickToPanel) {
			return trialSelectionPanelWidth;
		} else {
			var reducedAvailableWidth = winWidth - (((((((minimapWidth + minimapMargin) + selectionPanelBorder) + panelGap) + globalButtonsWidth) + globalButtonsBorder) + globalButtonsMargin) + panelGap);
			return A3($elm$core$Basics$clamp, selectionPanelMinWidth, selectionPanelMaxWidth, reducedAvailableWidth);
		}
	}();
	var globalButtonsLeft = canStickToPanel ? ((((((winWidth - (minimapWidth + minimapMargin)) - selectionPanelWidth) - selectionPanelBorder) - panelGap) - globalButtonsWidth) - globalButtonsBorder) : globalButtonsMargin;
	var viewportWidth = winWidth;
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('root-container')
			]),
		_List_fromArray(
			[
				A4($author$project$View$viewMainViewport, model, cursor, viewportWidth, viewportHeight),
				$author$project$View$viewGoldCounter(model),
				A2($author$project$View$viewGlobalButtonsPanel, model, globalButtonsLeft),
				A2($author$project$View$viewSelectionPanel, model, selectionPanelWidth),
				$author$project$View$viewMinimap(model),
				$author$project$View$viewTooltip(model),
				$author$project$View$viewPreGameOverlay(model),
				$author$project$View$viewGameOverOverlay(model)
			]));
};
var $author$project$Main$main = $elm$browser$Browser$element(
	{init: $author$project$Update$init, subscriptions: $author$project$Update$subscriptions, update: $author$project$Update$update, view: $author$project$View$view});
_Platform_export({'Main':{'init':$author$project$Main$main(
	$elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});}(this));