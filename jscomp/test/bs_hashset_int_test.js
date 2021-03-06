'use strict';

var Mt              = require("./mt.js");
var Block           = require("../../lib/js/block.js");
var Bs_Array        = require("../../lib/js/bs_Array.js");
var Bs_SetInt       = require("../../lib/js/bs_SetInt.js");
var Bs_HashSetInt   = require("../../lib/js/bs_HashSetInt.js");
var Array_data_util = require("./array_data_util.js");

var suites = [/* [] */0];

var test_id = [0];

function eq(loc, x, y) {
  test_id[0] = test_id[0] + 1 | 0;
  suites[0] = /* :: */[
    /* tuple */[
      loc + (" id " + test_id[0]),
      (function () {
          return /* Eq */Block.__(0, [
                    x,
                    y
                  ]);
        })
    ],
    suites[0]
  ];
  return /* () */0;
}

var u = Bs_Array.append(Array_data_util.randomRange(30, 100), Array_data_util.randomRange(40, 120));

var v = Bs_HashSetInt.ofArray(u);

eq("File \"bs_hashset_int_test.ml\", line 17, characters 5-12", Bs_HashSetInt.length(v), 91);

var xs = Bs_SetInt.toArray(Bs_SetInt.ofArray(Bs_HashSetInt.toArray(v)));

eq("File \"bs_hashset_int_test.ml\", line 19, characters 5-12", xs, Array_data_util.range(30, 120));

var u$1 = Bs_Array.append(Array_data_util.randomRange(0, 100000), Array_data_util.randomRange(0, 100));

var v$1 = Bs_HashSetInt.create(40);

Bs_HashSetInt.addArray(v$1, u$1);

eq("File \"bs_hashset_int_test.ml\", line 25, characters 5-12", Bs_HashSetInt.length(v$1), 100001);

for(var i = 0; i <= 1000; ++i){
  Bs_HashSetInt.remove(v$1, i);
}

eq("File \"bs_hashset_int_test.ml\", line 29, characters 5-12", Bs_HashSetInt.length(v$1), 99000);

for(var i$1 = 0; i$1 <= 2000; ++i$1){
  Bs_HashSetInt.remove(v$1, i$1);
}

eq("File \"bs_hashset_int_test.ml\", line 33, characters 5-12", Bs_HashSetInt.length(v$1), 98000);

Mt.from_pair_suites("bs_hashset_int_test.ml", suites[0]);

var N = 0;

var S = 0;

var I = 0;

var $plus$plus = Bs_Array.append;

exports.suites     = suites;
exports.test_id    = test_id;
exports.eq         = eq;
exports.N          = N;
exports.S          = S;
exports.I          = I;
exports.$plus$plus = $plus$plus;
/* u Not a pure module */
