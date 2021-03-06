package pman;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using haxe.macro.ExprTools;
using haxe.macro.PositionTools;
using tannus.macro.MacroTools;

class GlobalMacros {
    /**
      * set [dest] to [value] when [value] passes tests and stuff 
      */
    public static macro function nullSet<T>(dest:ExprOf<T>, value:Expr, rest:Array<Expr>) {
        var trans:Expr = (macro _);
        var defaultValue:Null<Expr> = null;
        var valueTest:Expr = (macro (_ != null));

        switch ( rest ) {
            case [dv]:
                defaultValue = dv;

            case [dv, t]:
                defaultValue = dv;
                trans = t;

            case [dv, t, test]:
                defaultValue = dv;
                trans = t;
                valueTest = test;

            default:
                null;
        }

        if (defaultValue != null && defaultValue.expr.match(EConst(CIdent('null')))) {
            defaultValue = null;
        }

        var valueVar:Bool = !value.expr.match(EConst(CIdent(_)));
        var origValue:Expr = value;

        var valueVarDecl:Expr = (macro null);
        if ( valueVar ) {
            valueVarDecl = {
                pos: Context.currentPos(),
                expr: ExprDef.EVars([{
                    name: 'vtmp',
                    expr: value,
                    type: null
                }])
            };
        }

        valueTest = valueTest.replace(macro _, (valueVar ? macro vtmp : value));
        var valueRef:Expr = (valueVar ? macro vtmp : value);
        //value = (defaultValue != null ? (macro ($valueTest ? ${trans.replace(macro _, (valueVar ? valueVarExpr : value))} : $defaultValue)) : trans.replace(macro _, (valueVar ? valueVarExpr : value)));
        value = {
            if (defaultValue != null) {
                macro {
                    if ( $valueTest ) {
                        ${trans.replace(macro _, valueRef)};
                    }
                    else {
                        $defaultValue;
                    }
                };
            }
            else {
                trans.replace(macro _, valueRef);
            }
        };
        valueRef = (valueVar ? macro vtmp : value);

        var result:Expr = macro {
            $valueVarDecl;
            $dest = $valueRef;
        };
        return result;
    }

    /**
      * does the stuff
      */
    public static macro function nullOr<T>(args: Array<ExprOf<Null<T>>>):ExprOf<T> {
        if (args.length % 2 != 0) {
            args.push(macro null);
        }

	    function expr(e: ExprDef):Expr {
	        return {
	            pos: Context.currentPos(),
	            expr: e
	        };
        }

        function or(x:Expr, y:Expr):Expr {
            return macro (if ($x != null) $x else $y);
        }

	    function ors(i: Array<Expr>):Expr {
			//return expr(EBinop(Binop.OpBoolOr, i.shift(), (i.length >= 2 ? or( i ) : i.shift())));
			return or(i.shift(), (i.length >= 2 ? ors( i ) : i.shift()));
	    }

	    return ors( args );
    }

    /**
      * set [x] to [y], and if [x] wasn't already equal to [y], do [whileChanging]
      */
    public static macro function deltaSet<T>(x:ExprOf<T>, y:ExprOf<T>, whenChanging:Expr, rest:Array<Expr>) {
        var eqTest:Expr = (macro (_1 == _2));
        switch ( rest ) {
            case [test]:
                eqTest = test;

            case anythingElse:
                null;
        }

        var test:ExprOf<Bool> = (macro !$eqTest).replace(macro _1, x).replace(macro _2, y);
        return macro {
            var dif:Bool = (${test});
            $x = $y;
            if ( dif ) {
                $whenChanging;
            }
        };
    }

    /**
      * if [v] passes a non-null and an optional secondary test, do [whenValid]
      */
    public static macro function qm(v:Expr, whenValid:Expr, rest:Array<Expr>) {
        var test:Expr = (macro ($v != null));

        if (rest.length > 0) {
            test = rest.shift();
        }

        whenValid = whenValid.replace(macro _, v);

        return (macro {
            if ($test) {
                $whenValid;
            }
        });
    }

    /**
      * if [v] passes a non-null and an optional secondary test, do [whenValid]
      */
    public static macro function tqm(nullableValue:Expr, whenNotNull:Expr, whenNull:Expr, rest:Array<Expr>) {
        var test:Expr = (macro (_ != null));
        if (rest.length > 0) {
            test = rest.shift();
        }
        test = test.replace(macro _, nullableValue);

        whenNotNull = whenNotNull.replace(macro _, nullableValue);
        whenNull = whenNull.replace(macro _, nullableValue);

        return (macro {
            if ($test)
                $whenNotNull
            else 
                $whenNull;
        });
    }

    /**
      * utility method for creating a Void->Void method
      */
    public static macro function void(body: Expr):ExprOf<Void->Void> {
        return func([], body, Context.currentPos());
    }

    /**
      * roughly equivalent to CoffeeScript's "do {expr}" operator
      */
    public static macro function doo(block: Expr) {
        var funcExpr:Expr = func([], block, Context.currentPos());
        return (macro (${funcExpr}()));
    }

#if macro

    private static function func(params:Array<String>, body:Expr, pos:Position):Expr {
        var ps:String = params.join(', ');
        return parse('(function(${ps}) {
            _BODY_;
        })', pos).replace(macro _BODY_, body);
    }

    private static function parse(s:String, pos:Position):Expr {
        return Context.parse(s, pos);
    }

#end
}

