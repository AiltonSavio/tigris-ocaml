open Absyn

let name = Symbol.name
let map  = List.map
let mkt s = Tree.mkt [s]

let tree_of_option f = function
  | None -> mkt "" []
  | Some x -> f x

let string_of_oper = function
  | PlusOp  -> "+"
  | MinusOp -> "-"
  | TimesOp -> "*"
  | DivOp   -> "/"
  | ModOp   -> "%"
  | PowOp   -> "^"
  | EqOp    -> "="
  | NeOp    -> "<>"
  | LtOp    -> "<"
  | LeOp    -> "<="
  | GtOp    -> ">"
  | GeOp    -> ">="
  | AndOp   -> "&"
  | OrOp    -> "|"

let escape_dot s =
  Util.implode
    (List.fold_right
       (fun c cs ->
         match c with
           | '\n' -> '\\' :: 'n' :: cs
           | '<' | '{' | '|' | '}' | '>' | ' ' -> '\\' :: c :: cs
           | _ -> c :: cs
       )
       (Util.explode s)
       [])

let node_txt xs = String.concat ":" xs

let node_dot s =
  let node_dot = function
    | [] -> ""
    | [x] -> escape_dot x
    | xs -> "{ " ^ String.concat " | " (List.map escape_dot xs) ^ " }"
  in
  let s' = node_dot s in
  (* print_string s'; *)
  s'

let root s =
  [s]

let rec tree_of_exp exp =
  let mktr s = Tree.mkt (root s) in
  match exp with
  | BoolExp x          -> mktr ("BoolExp " ^ string_of_bool x) []
  | IntExp x           -> mktr ("IntExp " ^ string_of_int x) []
  | RealExp x          -> mktr ("RealExp " ^ string_of_float x) []
  | StringExp x        -> mktr ("StringExp " ^ x) []
  | VarExp v           -> mktr "VarExp" [tree_of_lvar v]
  | AssignExp (v,e)    -> mktr "AssignExp" [tree_of_lvar v; tree_of_lexp e]
  | CallExp (f,xs)     -> mktr "CallExp" [mkt (name f) []; mkt "Args" (map tree_of_lexp xs)]
  | MinExp (op, e)     -> mktr ("OpExp " ^ string_of_oper op) [tree_of_lexp e]
  | OpExp (op,e1,e2)   -> mktr ("OpExp " ^ string_of_oper op) [tree_of_lexp e1; tree_of_lexp e2]
  | IfExp (cond,e1,e2) -> mktr "IfExp" [tree_of_lexp cond; tree_of_lexp e1; tree_of_option tree_of_lexp e2]
  | WhileExp (cond,e)  -> mktr "WhileExp" [tree_of_lexp cond; tree_of_lexp e]
  | BreakExp           -> mktr "BreakExp" []
  | EndExp             -> mktr "EndExp" []
  | SeqExp es          -> mktr "SeqExp" (map tree_of_lexp es)
  | LetExp (ds,e)      -> mktr "LetExp" [mkt "Decls" (map tree_of_ldec ds); tree_of_lexp e]

and tree_of_var = function
  | SimpleVar v -> mkt ("SimpleVar " ^ name v) []

and tree_of_dec = function
  | VarDec (v,t,e)        -> mkt "VarDec"
                               [ mkt (name v) []
                               ; tree_of_option tree_of_lsymbol t
                               ; tree_of_lexp e
                               ]
  | MutualFunctionDecs fs -> mkt "MutualFunDecs" (map tree_of_lfundec fs)
  | MutualTypeDecs ts     -> mkt "MutualTypDecs"
                               (map
                               (fun (_,(t,ty)) ->
                                 mkt "TypeDec" [mkt (name t) []; tree_of_ltcons ty])
                               ts)

and tree_of_fundec (f,ps,r,b) =
  mkt ("Function: " ^ name f)
    [ mkt "Params" (map
                      (fun (_,(n,t)) ->
                        mkt (name n) [ mkt (name t) [] ])
                      ps)
    ; mkt (match r with None -> "FunctionDec" | Some (_,k) -> name k) []
    ; tree_of_lexp b
    ]

and tree_of_tcons = function
  | NameCons t -> mkt "NameCons" [mkt (name t) []]

and tree_of_lexp (_,x) = tree_of_exp x
and tree_of_lvar (_,x) = tree_of_var x
and tree_of_ldec (_,x) = tree_of_dec x
and tree_of_lfundec (_,x) = tree_of_fundec x
and tree_of_ltcons (_,x) = tree_of_tcons x
and tree_of_lsymbol (_,x) = tree_of_symbol x
and tree_of_symbol x = mkt (name x) []
