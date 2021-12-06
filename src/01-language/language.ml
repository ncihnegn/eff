module Coercion = Coercion
module Const = Const
module Primitives = Primitives
module Substitution = Substitution
module Term = Term
module Type = Type
module UntypedSyntax = UntypedSyntax

module type Backend = sig
  type state

  val initial_state : state

  val process_computation : state -> Term.computation -> state

  val process_type_of : state -> Term.computation -> state

  val process_def_effect : state -> Term.effect -> state

  val process_top_let :
    state ->
    (Term.variable * Type.Params.t * Type.Constraints.t * Term.expression) list ->
    state

  val process_top_let_rec : state -> Term.top_rec_definitions -> state

  val load_primitive_value :
    state -> Term.variable -> Primitives.primitive_value -> state

  val load_primitive_effect :
    state -> Term.effect -> Primitives.primitive_effect -> state

  val process_tydef :
    state -> (Type.TyName.t, Type.type_data) Utils.Assoc.t -> state

  val finalize : state -> unit
end
