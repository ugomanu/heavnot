let unexpected_token expected actual =
  raise
    (Failure
       ("Invalid token " ^ Token.show actual ^ " expected "
      ^ Token.show expected))

let invalid_token token = raise (Failure ("Invalid token " ^ Token.show token))
let unexpected_eof () = raise (Failure "Unexpected eof")

let rec parse_parameters params (tokens : Token.t list) =
  match tokens with
  | ParenClose :: tokens -> (tokens, List.rev params)
  | Identifier id :: Colon :: tokens -> (
      let tokens, type_ = parse_type tokens in
      let param : Ast.param = { identifier = id; type_ } in

      match tokens with
      | Token.Comma :: tokens -> parse_parameters (param :: params) tokens
      | ParenClose :: tokens -> (tokens, List.rev (param :: params))
      | token :: _ -> invalid_token token
      | [] -> unexpected_eof ())
  | token :: _ -> invalid_token token
  | [] -> unexpected_eof ()

and parse_parameter_statements statements (tokens : Token.t list) =
  match tokens with
  | ParenClose :: tokens -> (tokens, List.rev statements)
  | _ :: _ -> (
      let tokens, statement = parse_statement tokens in
      match tokens with
      | Token.Comma :: tokens ->
          parse_parameter_statements (statement :: statements) tokens
      | ParenClose :: tokens -> (tokens, List.rev (statement :: statements))
      | token :: _ -> invalid_token token
      | [] -> unexpected_eof ())
  | [] -> unexpected_eof ()

and parse_body body (tokens : Token.t list) =
  match tokens with
  | BraceClose :: tokens -> (tokens, List.rev body)
  | _ :: _ ->
      let tokens, statement = parse_statement tokens in
      parse_body (statement :: body) tokens
  | [] -> unexpected_eof ()

and parse_type (tokens : Token.t list) =
  let open Type in
  match tokens with
  | Int :: tokens -> (tokens, Int)
  | Float :: tokens -> (tokens, Float)
  | String :: tokens -> (tokens, String)
  | Identifier id :: tokens -> (tokens, Reference id)
  | token :: _ -> invalid_token token
  | [] -> unexpected_eof ()

and parse_variable (tokens : Token.t list) id (type_ : Type.t option) =
  let open Ast in
  match tokens with
  | Equal :: tokens ->
      let tokens, value = parse_statement tokens in
      (tokens, VariableDecl { identifier = id; type_; value })
  | token :: _ -> unexpected_token Token.Equal token
  | [] -> unexpected_eof ()

and parse_identifier (tokens : Token.t list) id =
  match tokens with
  | Colon :: Colon :: tokens ->
      let tokens, type_ = parse_type tokens in
      (tokens, Ast.TypeDecl { identifier = id; type_ })
  | Colon :: tokens ->
      let tokens, type_ = parse_type tokens in
      parse_variable tokens id (Some type_)
  | Equal :: _ -> parse_variable tokens id None
  | _ :: _ -> (tokens, VariableAccess id)
  | [] -> unexpected_eof ()

and parse_suffix (tokens : Token.t list) statement =
  let open Ast in
  match tokens with
  | ParenOpen :: tokens ->
      let tokens, statements = parse_parameter_statements [] tokens in

      (tokens, FunctionCall { value = statement; params = statements })
  | tokens -> (tokens, statement)

and parse_statement (tokens : Token.t list) =
  let tokens, statement =
    match tokens with
    | Identifier id :: tokens -> parse_identifier tokens id
    | Literal value :: tokens -> (tokens, Literal value)
    | ParenOpen :: tokens -> parse_function tokens
    | token :: _ -> invalid_token token
    | [] -> unexpected_eof ()
  in

  parse_suffix tokens statement

and parse_function (tokens : Token.t list) =
  let tokens, params = parse_parameters [] tokens in

  let tokens, return_type =
    match tokens with
    | Colon :: tokens -> parse_type tokens
    | _ -> (tokens, Type.Unit)
  in

  let tokens =
    match tokens with
    | BraceOpen :: tokens -> tokens
    | token :: _ -> invalid_token token
    | [] -> unexpected_eof ()
  in

  let tokens, body = parse_body [] tokens in
  (tokens, Function { params; return_type; body })

let rec parse_root_body body (tokens : Token.t list) =
  match tokens with
  | _ :: _ ->
      let tokens, statement = parse_statement tokens in
      parse_root_body (statement :: body) tokens
  | [] -> List.rev body

let parse tokens : Ast.root =
  let body = parse_root_body [] tokens in
  { body }
