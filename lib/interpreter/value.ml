open Heavnot

type funct = { params : Ast.param list; body : Ast.t list } [@@deriving show]

type t =
  | Unit
  | Function of funct
  | IntValue of int
  | FloatValue of float
  | StringValue of string
  | Object of (string, t) Hashtbl.t

let rec show_object str (fields : (string * t) list) =
  let conc_str id value = str ^ id ^ ": " ^ show value in

  match fields with
  | (id, value) :: [] -> "{ " ^ conc_str id value ^ " }"
  | (id, value) :: fields -> show_object (conc_str id value ^ ", ") fields
  | [] -> "{}"

and show = function
  | Unit -> "()"
  | Function _ -> "function()"
  | IntValue value -> string_of_int value
  | FloatValue value -> string_of_float value
  | StringValue value -> value
  | Object fields -> show_object "" (List.of_seq (Hashtbl.to_seq fields))

let pp ppf value = Format.fprintf ppf "%s" (show value)
