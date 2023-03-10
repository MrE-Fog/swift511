// RUN: %target-typecheck-verify-swift

infix operator %%%
infix operator %%%%

func %%%() {} // expected-error {{operators must have one or two arguments}}
func %%%%(a: Int, b: Int, c: Int) {} // expected-error {{operators must have one or two arguments}}

struct X {}
struct Y {}

func +(lhs: X, rhs: X) -> X {} // okay

func +++(lhs: X, rhs: X) -> X {} // expected-error {{operator implementation without matching operator declaration}}

infix operator ++++ : ReallyHighPrecedence
precedencegroup ReallyHighPrecedence {
  higherThan: BitwiseShiftPrecedence
  associativity: left
}

infix func fn_binary(_ lhs: Int, rhs: Int) {}  // expected-error {{'infix' modifier is not required or allowed on func declarations}}


func ++++(lhs: X, rhs: X) -> X {}
func ++++(lhs: Y, rhs: Y) -> Y {} // okay

func useInt(_ x: Int) {}
func test() {
  var x : Int  
  let y : Int = 42
  // Produce a diagnostic for using the result of an assignment as a value.
  // rdar://12961094
  useInt(x = y)  // expected-error{{cannot convert value of type '()' to expected argument type 'Int'}}
  _ = x
}

prefix operator ~~
postfix operator ~~
infix operator ~~

postfix func foo(_ x: Int) {} // expected-error {{'postfix' requires a function with an operator identifier}}
postfix func ~~(x: Int) -> Float { return Float(x) }
postfix func ~~(x: Int, y: Int) {} // expected-error {{'postfix' requires a function with one argument}}
prefix func ~~(x: Float) {}
func test_postfix(_ x: Int) {
  ~~x~~
}

prefix operator ~~~ // expected-note 2{{prefix operator found here}}

// Unary operators require a prefix or postfix attribute
func ~~~(x: Float) {} // expected-error{{prefix unary operator missing 'prefix' modifier}}{{1-1=prefix }}

protocol P {
  static func ~~~(x: Self) // expected-error{{prefix unary operator missing 'prefix' modifier}}{{10-10=prefix }}
}

prefix func +// this should be a comment, not an operator
(arg: Int) -> Int { return arg }

prefix func -/* this also should be a comment, not an operator */
(arg: Int) -> Int { return arg }

func +*/ () {}   // expected-error {{expected identifier in function declaration}} expected-error {{unexpected end of block comment}} expected-error {{closure expression is unused}} expected-error{{top-level statement cannot begin with a closure expression}} expected-note{{did you mean to use a 'do' statement?}} {{13-13=do }}
func errors() {
  */    // expected-error {{unexpected end of block comment}}
  
  // rdar://12962712 - reject */ in an operator as it should end a block comment.
  */+    // expected-error {{unexpected end of block comment}}
}

prefix operator ...

prefix func ... (arg: Int) -> Int { return arg }
func resyncParser() {}

// Operator decl refs (<op>)

infix operator +-+
prefix operator +-+

prefix operator -+-
postfix operator -+-

infix operator +-+=

infix func +-+ (x: Int, y: Int) -> Int {} // expected-error {{'infix' modifier is not required or allowed on func declarations}} {{1-7=}}
prefix func +-+ (x: Int) -> Int {}

prefix func -+- (y: inout Int) -> Int {} // expected-note 2{{found this candidate}}
postfix func -+- (x: inout Int) -> Int {} // expected-note 2{{found this candidate}}

infix func +-+= (x: inout Int, y: Int) -> Int {} // expected-error {{'infix' modifier is not required or allowed on func declarations}} {{1-7=}}

var n = 0

// Infix by context
_ = (+-+)(1, 2)
// Prefix by context
_ = (+-+)(1)

// Ambiguous -- could be prefix or postfix
(-+-)(&n) // expected-error{{ambiguous use of operator '-+-'}}

// Assignment operator refs become inout functions
_ = (+-+=)(&n, 12)
(+-+=)(n, 12)   // expected-error {{passing value of type 'Int' to an inout parameter requires explicit '&'}} {{8-8=&}}

var f1 : (Int, Int) -> Int = (+-+)
var f2 : (Int) -> Int = (+-+)
var f3 : (inout Int) -> Int = (-+-) // expected-error{{ambiguous use of operator '-+-'}}
var f4 : (inout Int, Int) -> Int = (+-+=)
var r5 : (a : (Int, Int) -> Int, b : (Int, Int) -> Int) = (+, -)
var r6 : (a : (Int, Int) -> Int, b : (Int, Int) -> Int) = (b : +, a : -)

struct f6_S {
  subscript(op : (Int, Int) -> Int) -> Int {
    return 42
  }
}
var f6_s : f6_S
var junk = f6_s[+]

// Unicode operator names
infix operator ???
infix operator ?????? // Operators can contain (but not start with) combining characters

func ???(x: Int, y: Int) -> Bool { return x == y }
func ??????(x: Int, y: Int) -> Bool { return x != y }

var x, y : Int
_ = x???y
_ = x??????y

// rdar://14705150 - crash on invalid
func test_14705150() {
  let a = 4
  var b! = a  // expected-error {{type annotation missing in pattern}}
  // expected-error @-1 {{consecutive statements on a line must be separated by ';'}} {{8-8=;}}
  // expected-error @-2 {{expected expression}}

}

prefix postfix func ++(x: Int) {} // expected-error {{'postfix' contradicts previous modifier 'prefix'}} {{8-16=}}
postfix prefix func ++(x: Float) {} // expected-error {{'prefix' contradicts previous modifier 'postfix'}} {{9-16=}}
postfix prefix infix func ++(x: Double) {} // expected-error {{'prefix' contradicts previous modifier 'postfix'}} {{9-16=}} expected-error {{'infix' contradicts previous modifier 'postfix'}} {{16-22=}}
infix prefix func +-+(x: Int, y: Int) {} // expected-error {{'infix' modifier is not required or allowed on func declarations}} {{1-7=}} expected-error{{'prefix' contradicts previous modifier 'infix'}} {{7-14=}}

// Don't allow one to define a postfix '!'; it's built into the
// language. Also illegal to have any postfix operator starting with '!'.
postfix operator !  // expected-error {{cannot declare a custom postfix '!' operator}} expected-error {{expected operator name in operator declaration}}
prefix operator &  // expected-error {{cannot declare a custom prefix '&' operator}}

// <rdar://problem/14607026> Restrict use of '<' and '>' as prefix/postfix operator names
postfix operator >  // expected-error {{cannot declare a custom postfix '>' operator}}
prefix operator <  // expected-error {{cannot declare a custom prefix '<' operator}}

postfix func !(x: Int) { } // expected-error{{cannot declare a custom postfix '!' operator}}
postfix func!(x: Int8) { } // expected-error{{cannot declare a custom postfix '!' operator}}
prefix func & (x: Int) {} // expected-error {{cannot declare a custom prefix '&' operator}}

// Only allow operators at global scope:
func operator_in_func_bad () {
    prefix func + (input: String) -> String { return "+" + input } // expected-error {{operator functions can only be declared at global or in type scope}}
}

infix operator ?  // expected-error {{expected operator name in operator declaration}} 

infix operator ??=

func ??= <T>(result : inout T?, rhs : Int) {  // ok
}



// <rdar://problem/14296004> [QoI] Poor diagnostic/recovery when two operators (e.g., == and -) are adjacted without spaces.
_ = n*-4       // expected-error {{missing whitespace between '*' and '-' operators}} {{6-6= }} {{7-7= }}
if n==-1 {}    // expected-error {{missing whitespace between '==' and '-' operators}} {{5-5= }} {{7-7= }}

prefix operator ??????
prefix func??????(a : Int) -> Int { return a }
postfix operator ??????
postfix func??????(a : Int) -> Int { return a }

_ = n?????? ?????? n   // Ok.
_ = n ?????? ??????n   // Ok.
_ = n ???????????? n   // expected-error {{use of unresolved operator '????????????'}}
_ = n????????????n     // expected-error {{ambiguous missing whitespace between unary and binary operators}}
// expected-note @-1 {{could be binary '??????' and prefix '??????'}} {{12-12= }} {{18-18= }}
// expected-note @-2 {{could be postfix '??????' and binary '??????'}} {{6-6= }} {{12-12= }}

_ = n???????????? // expected-error {{unary operators must not be juxtaposed; parenthesize inner expression}}
_ = ~!n  // expected-error {{unary operators must not be juxtaposed; parenthesize inner expression}}
_ = -+n  // expected-error {{unary operators must not be juxtaposed; parenthesize inner expression}}
_ = -++n // expected-error {{unary operators must not be juxtaposed; parenthesize inner expression}}

// <rdar://problem/16230507> Cannot use a negative constant as the second operator of ... operator
_ = 3...-5  // expected-error {{ambiguous missing whitespace between unary and binary operators}} expected-note {{could be postfix '...' and binary '-'}} expected-note {{could be binary '...' and prefix '-'}}


protocol P0 {
  static func %%%(lhs: Self, rhs: Self) -> Self
}

protocol P1 {
  func %%%(lhs: Self, rhs: Self) -> Self // expected-warning{{operator '%%%' declared in protocol must be 'static'}}{{3-3=static }}
}

struct S0 {
  static func %%%(lhs: S0, rhs: S0) -> S0 { return lhs }
}

extension S0 {
  static func %%%%(lhs: S0, rhs: S0) -> S0 { return lhs }
}

struct S1 {
  func %%%(lhs: S1, rhs: S1) -> S1 { return lhs } // expected-error{{operator '%%%' declared in type 'S1' must be 'static'}}{{3-3=static }}
}

extension S1 {
  func %%%%(lhs: S1, rhs: S1) -> S1 { return lhs } // expected-error{{operator '%%%%' declared in type 'S1' must be 'static'}}{{3-3=static }}
}

class C0 {
  static func %%%(lhs: C0, rhs: C0) -> C0 { return lhs }
}

class C1 {
  final func %%%(lhs: C1, rhs: C1) -> C1 { return lhs } // expected-error{{operator '%%%' declared in type 'C1' must be 'static'}}{{3-3=static }}
}

final class C2 {
  class func %%%(lhs: C2, rhs: C2) -> C2 { return lhs }
}

class C3 {
  class func %%%(lhs: C3, rhs: C3) -> C3 { return lhs } // expected-error{{operator '%%%' declared in non-final class 'C3' must be 'final'}}{{3-3=final }}
}

class C4 {
  func %%%(lhs: C4, rhs: C4) -> C4 { return lhs } // expected-error{{operator '%%%' declared in type 'C4' must be 'static'}}{{3-3=static }}
}

struct Unrelated { }

struct S2 {
  static func %%%(lhs: Unrelated, rhs: Unrelated) -> Unrelated { }
  // expected-error@-1{{member operator '%%%' must have at least one argument of type 'S2'}}

  static func %%%(lhs: Unrelated, rhs: Unrelated) -> S2 { }
  // expected-error@-1{{member operator '%%%' must have at least one argument of type 'S2'}}

  static func %%%(lhs: Unrelated, rhs: Unrelated) -> S2.Type { }
  // expected-error@-1{{member operator '%%%' must have at least one argument of type 'S2'}}

  // Okay: refers to S2
  static func %%%(lhs: S2, rhs: Unrelated) -> Unrelated { }
  static func %%%(lhs: inout S2, rhs: Unrelated) -> Unrelated { }
  static func %%%(lhs: S2.Type, rhs: Unrelated) -> Unrelated { }
  static func %%%(lhs: inout S2.Type, rhs: Unrelated) -> Unrelated { }
  static func %%%(lhs: Unrelated, rhs: S2) -> Unrelated { }
  static func %%%(lhs: Unrelated, rhs: inout S2) -> Unrelated { }
  static func %%%(lhs: Unrelated, rhs: S2.Type) -> Unrelated { }
  static func %%%(lhs: Unrelated, rhs: inout S2.Type) -> Unrelated { }
}

extension S2 {
  static func %%%%(lhs: Unrelated, rhs: Unrelated) -> Unrelated { }
  // expected-error@-1{{member operator '%%%%' must have at least one argument of type 'S2'}}

  static func %%%%(lhs: Unrelated, rhs: Unrelated) -> S2 { }
  // expected-error@-1{{member operator '%%%%' must have at least one argument of type 'S2'}}

  static func %%%%(lhs: Unrelated, rhs: Unrelated) -> S2.Type { }
  // expected-error@-1{{member operator '%%%%' must have at least one argument of type 'S2'}}

  // Okay: refers to S2
  static func %%%%(lhs: S2, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: inout S2, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: S2.Type, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: inout S2.Type, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: S2) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: inout S2) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: S2.Type) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: inout S2.Type) -> Unrelated { }
}

protocol P2 {
  static func %%%(lhs: Unrelated, rhs: Unrelated) -> Unrelated
  // expected-error@-1{{member operator '%%%' of protocol 'P2' must have at least one argument of type 'Self'}}

  static func %%%(lhs: Unrelated, rhs: Unrelated) -> Self
  // expected-error@-1{{member operator '%%%' of protocol 'P2' must have at least one argument of type 'Self'}}

  static func %%%(lhs: Unrelated, rhs: Unrelated) -> Self.Type
  // expected-error@-1{{member operator '%%%' of protocol 'P2' must have at least one argument of type 'Self'}}

  // Okay: refers to Self
  static func %%%(lhs: Self, rhs: Unrelated) -> Unrelated
  static func %%%(lhs: inout Self, rhs: Unrelated) -> Unrelated
  static func %%%(lhs: Self.Type, rhs: Unrelated) -> Unrelated
  static func %%%(lhs: inout Self.Type, rhs: Unrelated) -> Unrelated
  static func %%%(lhs: Unrelated, rhs: Self) -> Unrelated
  static func %%%(lhs: Unrelated, rhs: inout Self) -> Unrelated
  static func %%%(lhs: Unrelated, rhs: Self.Type) -> Unrelated
  static func %%%(lhs: Unrelated, rhs: inout Self.Type) -> Unrelated
}

extension P2 {
  static func %%%%(lhs: Unrelated, rhs: Unrelated) -> Unrelated { }
  // expected-error@-1{{member operator '%%%%' of protocol 'P2' must have at least one argument of type 'Self'}}

  static func %%%%(lhs: Unrelated, rhs: Unrelated) -> Self { }
  // expected-error@-1{{member operator '%%%%' of protocol 'P2' must have at least one argument of type 'Self'}}

  static func %%%%(lhs: Unrelated, rhs: Unrelated) -> Self.Type { }
  // expected-error@-1{{member operator '%%%%' of protocol 'P2' must have at least one argument of type 'Self'}}

  // Okay: refers to Self
  static func %%%%(lhs: Self, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: inout Self, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: Self.Type, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: inout Self.Type, rhs: Unrelated) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: Self) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: inout Self) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: Self.Type) -> Unrelated { }
  static func %%%%(lhs: Unrelated, rhs: inout Self.Type) -> Unrelated { }
}

protocol P3 {
  // Okay: refers to P3
  static func %%%(lhs: P3, rhs: Unrelated) -> Unrelated
}

extension P3 {
  // Okay: refers to P3
  static func %%%%(lhs: P3, rhs: Unrelated) -> Unrelated { }
}

// rdar://problem/27940842 - recovery with a non-static '=='.
class C5 {
  func == (lhs: C5, rhs: C5) -> Bool { return false } // expected-error{{operator '==' declared in type 'C5' must be 'static'}}

  func test1(x: C5) {
    _ = x == x
  }
}

class C6 {
  static func == (lhs: C6, rhs: C6) -> Bool { return false }

  func test1(x: C6) {
    if x == x && x = x { } // expected-error{{expression is not assignable: '&&' returns immutable value}}
  }
}
