# Decimal
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import  unittest,
        ../decimal/decimal

suite "Basic Arithmetic":
  test "init Decimal":
    var d = newDecimal()
  test "Set Decimal from string":
    let s = "1.23456"
    var d = newDecimal(s)
    check $d == s
  test "Set Decimal from int":
    let s = 123456
    var d = newDecimal(s)
    let correct = "123456"
    check $d == correct

  test "Decimal Addition":
    var a = newDecimal("1.2")
    var b = newDecimal("3.5")
    var c1 = a + b
    var c2 = b + a
    let correct = "4.7"
    check $c1 == correct
    check $c2 == correct
  test "Decimal inplace Addition":
    var a = newDecimal("1.2")
    var b = newDecimal("3.6")
    a += b
    let correct = "4.8"
    check $a == correct
  test "Decimal-Int Addition":
    var a = newDecimal("1.2")
    var b = 5
    var c1 = a + b
    var c2 = b + a
    let correct = "6.2"
    check $c1 == correct
    check $c2 == correct
  test "Decimal-Int inplace Addition":
    var a = newDecimal("1.2")
    var b = 4
    a += b
    let correct = "5.2"
    check $a == correct

  test "Decimal Subtraction":
    var a = newDecimal("1.2")
    var b = newDecimal("3.5")
    var c = a - b
    let correct = "-2.3"
    check $c == correct
  test "Decimal Multiplication":
    var a = newDecimal("1.2")
    var b = newDecimal("3.5")
    var c = a * b
    let correct = "4.20"
    check $c == correct

  test "Decimal Division":
    var a = newDecimal("6.25")
    var b = newDecimal("2.5")
    var c = a / b
    let correct = "2.5"
    check $c == correct
  test "Decimal-Int Division":
    var a = newDecimal("10")
    var b = 5
    var c = a / b
    var d = b / a
    let correctC = "2"
    let correctD = "0.5"
    check $c == correctC
    check $d == correctD

  test "Decimal ==":
    var a = newDecimal("6.25")
    var b = newDecimal("2.5")
    check a == a
    check (a == b)  == false
  test "Decimal <":
    var a = newDecimal("6.25")
    var b = newDecimal("2.5")
    check b < a
    check (a < b) == false
  test "Decimal >":
    var a = newDecimal("6.25")
    var b = newDecimal("2.5")
    check a > b
    check (b > a) == false
  test "Decimal Power 1":
    var a = newDecimal("2.5")
    var b = newDecimal("2")
    var c = a ^ b
    check $c == "6.25"
  test "Decimal Power 2":
    var a = newDecimal("81")
    var b = newDecimal("0.5")
    var c = a ^ b
    check $c == "9.0000000000000000000000000000000000000"
  test "Decimal divint":
    let a = newDecimal("11")
    let b = newDecimal("3")
    let c = a // b
    check $c == "3"
  test "Decimal rem":
    let a = newDecimal("11")
    let b = newDecimal("3")
    let c = rem(a, b)
    check $c == "2"
  test "Decimal divmod":
    let a = newDecimal("11")
    let b = newDecimal("3")
    let (q, r) = divmod(a, b)
    check $q == "3"
    check $r == "2"
  test "Decimal exp":
    let a = newDecimal("2")
    let c = exp(a)
    check $c == "7.3890560989306502272304274605750078132"
  test "Decimal rem_near":
    let a = newDecimal("11")
    let b = newDecimal("3")
    let c = rem_near(a, b)
    check $c == "-1"
  test "Decimal fma":
    let a = newDecimal("11")
    let b = newDecimal("3")
    let c = newDecimal("2")
    let d = fma(a, b, c)
    check $d == "35"
  test "Decimal ln":
    let a = newDecimal("1")
    let b = exp(newDecimal("1"))
    let ln1 = ln(a)
    let ln2 = ln(b)
    check $ln1 == "0"
    check $ln2 == "1.0000000000000000000000000000000000000"
  test "Decimal log10":
    let a = newDecimal("1")
    let b = newDecimal("10")
    let c = newDecimal("20")
    let log1 = log10(a)
    let log2 = log10(b)
    let log3 = log10(c)
    check $log1 == "0"
    check $log2 == "1"
    check $log3 == "1.3010299956639811952137388947244930268"
  test "Decimal sqrt":
    let a = newDecimal("6.25")
    let b = sqrt(a)
    check $b == "2.5"
  test "Decimal invroot":
    let a = newDecimal("10")
    let b = invroot(a)
    check $b == "0.31622776601683793319988935444327185337"
  test "Decimal negate":
    let a = newDecimal("1.23")
    let b = newDecimal("-4.56")
    let a2 = -a
    let b2 = -b
    check $a2 == "-1.23"
    check $b2 == "4.56"
  test "Decimal abs":
    let a = newDecimal("7")
    let b = newDecimal("-8")
    let c = abs(a)
    let d = abs(b)
    check $c == "7"
    check $d == "8"
  test "Decimal quantize":
    let a = newDecimal("17.89843759")
    let b = newDecimal("1e-5")
    check $quantize(a,b) == "17.89844"
  test "Decimal max":
    let a = newDecimal("5")
    let b = newDecimal("-5")
    let c = newDecimal("2")
    check max(a, b) == a
    check max(b, c) == c
  test "Decimal max_mag":
    let a = newDecimal("5")
    let b = newDecimal("-6")
    let c = newDecimal("7")
    check max_mag(a, b) == b
    check max_mag(b, c) == c
  test "Decimal min":
    let a = newDecimal("5")
    let b = newDecimal("-5")
    let c = newDecimal("-2")
    check min(a, b) == b
    check min(b, c) == b
  test "Decimal min_mag":
    let a = newDecimal("5")
    let b = newDecimal("-6")
    let c = newDecimal("7")
    check min_mag(a, b) == a
    check min_mag(b, c) == b
  test "Decimal next_plus":
    let a = newDecimal("1.01")
    let b = next_plus(a)
    let correct = "1.0100000000000000000000000000000000001"
    check $b == correct
  test "Decimal next_minus":
    let a = newDecimal("1.01")
    let b = next_minus(a)
    let correct = "1.0099999999999999999999999999999999999"
    check $b == correct
  test "Decimal next_toward":
    let a = newDecimal("1.01")
    let b = newDecimal("2")
    let c = newDecimal("1")
    let correct1 = "1.0100000000000000000000000000000000001"
    let correct2 = "1.0099999999999999999999999999999999999"
    check $next_toward(a, b) == correct1
    check $next_toward(a, c) == correct2
  test "Decimal rescale":
    let a = newDecimal("2000")
    let b = rescale(a, 3)
    check $b == "2e+3"
  test "Decimal same_quantum":
    let a = newDecimal("2e-5")
    let b = newDecimal("20e-6")
    let c = newDecimal("20e-5")
    check: not(same_quantum(a, b))
    check same_quantum(a, c)
  test "Decimal reduce":
    let a = newDecimal("1.2345000000000000000")
    let b = newDecimal("1.2345")
    let c = reduce(a)
    check $c == $b
  test "Decimal round_to_intx":
    let a = newDecimal("1.49")
    let b = round_to_intx(a)
    check $b == "1"
  test "Decimal floor":
    let a = newDecimal("1.49")
    let b = floor(a)
    check $b == "1"
  test "Decimal ceil":
    let a = newDecimal("1.49")
    let b = ceil(a)
    check $b == "2"
  test "Decimal truncate":
    let a = newDecimal("10.12345678")
    let b = truncate(a)
    check $b == "10"
  test "Decimal logb":
    let a = newDecimal("76543")
    let b = logb(a)
    let correct = floor(log10(a))
    check b == correct
  test "Decimal scaleb":
    let a = newDecimal("23e4")
    let b = newDecimal("3")
    let c = scaleb(a, b)
    check $c == "2.3e+8"
  test "Decimal powmod":
    let base = newDecimal("2")
    let exp = newDecimal("5")
    let m = newDecimal("7")
    let correct = rem(base ^ exp, m)
    check powmod(base, exp, m) == correct
  test "Decimal shift":
    let a = newDecimal("1.23e7")
    let b = 2
    let c = shift(a, b)
    check $c == "1.2300e+9"
  test "Decimal rotate":
    let a = newDecimal("1.23e7")
    let b = newDecimal(2)
    let c = rotate(a, b)
    check $c == "1.2300e+9"
  test "Decimal elementwiseOr":
    let a = newDecimal("1110")
    let b = newDecimal("1010")
    check $elementwiseOr(a,b) == "1110"
  test "Decimal elementwiseAnd":
    let a = newDecimal("1110")
    let b = newDecimal("1010")
    check $elementwiseAnd(a,b) == "1010"
  test "Decimal elementwiseXor":
    let a = newDecimal("01110")
    let b = newDecimal("11010")
    check $elementwiseXor(a,b) == "10100"
  test "Decimal elementwiseInvert":
    let a = newDecimal("111010")
    check $elementwiseInvert(a) == "11111111111111111111111111111111000101"





