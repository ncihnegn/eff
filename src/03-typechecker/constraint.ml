open Utils
open Language

type omega_ct =
  | TyOmega of (Type.TyCoercionParam.t * Type.ct_ty)
  | DirtOmega of (Type.DirtCoercionParam.t * Type.ct_dirt)
  | SkelEq of Type.skeleton * Type.skeleton

(* A bag/list of constraints *)
type constraints = omega_ct list

let add_to_constraints con constraints = con :: constraints

let add_list_to_constraints new_constraints old_constraints =
  new_constraints @ old_constraints

type resolved = {
  ty_constraints :
    (Type.TyCoercionParam.t
    * CoreTypes.TyParam.t
    * CoreTypes.TyParam.t
    * Type.SkelParam.t)
    list;
  dirt_constraints : (Type.DirtCoercionParam.t * Type.ct_dirt) list;
}

let unresolve resolved =
  List.map
    (fun (omega, a, b, skel) ->
      TyOmega
        ( omega,
          ( Type.tyParam a (Type.SkelParam skel),
            Type.tyParam b (Type.SkelParam skel) ) ))
    resolved.ty_constraints
  @ List.map
      (fun (omega, ct) -> DirtOmega (omega, ct))
      resolved.dirt_constraints

let return_resolved resolved queue = unresolve resolved @ queue

let empty_resolved = { ty_constraints = []; dirt_constraints = [] }

let resolve_ty_constraint resolved omega ty1 ty2 skel =
  {
    resolved with
    ty_constraints = (omega, ty1, ty2, skel) :: resolved.ty_constraints;
  }

let resolve_dirt_constraint resolved omega ct =
  { resolved with dirt_constraints = (omega, ct) :: resolved.dirt_constraints }

let print_omega_ct ?max_level c ppf =
  let print ?at_level = Print.print ?max_level ?at_level ppf in
  match c with
  | TyOmega (p, (ty1, ty2)) ->
      print "%t: (%t ≤ %t)"
        (Type.TyCoercionParam.print p)
        (Type.print_ty ty1) (Type.print_ty ty2)
  | DirtOmega (p, (ty1, ty2)) ->
      print "%t: (%t ≤ %t)"
        (Type.DirtCoercionParam.print p)
        (Type.print_dirt ty1) (Type.print_dirt ty2)
  | SkelEq (sk1, sk2) ->
      print "%t ~ %t" (Type.print_skeleton sk1) (Type.print_skeleton sk2)

let print_constraints cs = Print.sequence ";" print_omega_ct cs

let fresh_ty_coer cons =
  let param = Type.TyCoercionParam.fresh () in
  ({ term = Coercion.TyCoercionVar param; ty = cons }, TyOmega (param, cons))

let fresh_dirt_coer cons =
  let param = Type.DirtCoercionParam.fresh () in
  ({ term = Coercion.DirtCoercionVar param; ty = cons }, DirtOmega (param, cons))

let fresh_dirty_coer ((ty1, drt1), (ty2, drt2)) =
  let ty_coer, ty_cons = fresh_ty_coer (ty1, ty2)
  and drt_coer, drt_cons = fresh_dirt_coer (drt1, drt2) in
  (Coercion.bangCoercion (ty_coer, drt_coer), [ ty_cons; drt_cons ])

(* ************************************************************************* *)
(*                        FREE PARAMETER COMPUTATION                         *)
(* ************************************************************************* *)

let free_params_constraint = function
  | TyOmega (_, ct) -> Type.free_params_ct_ty ct
  | DirtOmega (_, ct) -> Type.free_params_ct_dirt ct
  | SkelEq (sk1, sk2) ->
      Type.Params.union
        (Type.free_params_skeleton sk1)
        (Type.free_params_skeleton sk2)

let free_params_constraints = Type.Params.union_map free_params_constraint

let free_params_resolved (res : resolved) =
  let free_params_ty =
    Type.Params.union_map
      (fun (_, ty1, ty2, skel) ->
        Type.Params.union
          {
            Type.Params.empty with
            ty_params =
              Type.TyParamMap.of_seq
                (List.to_seq
                   [
                     (ty1, [ Type.SkelParam skel ]);
                     (ty2, [ Type.SkelParam skel ]);
                   ]);
          }
          (Type.Params.skel_singleton skel))
      res.ty_constraints
  and free_params_dirt =
    Type.Params.union_map
      (fun (_, dt) -> Type.free_params_ct_dirt dt)
      res.dirt_constraints
  in
  Type.Params.union free_params_ty free_params_dirt

let cast_expression e ty =
  let omega, cons = fresh_ty_coer (e.ty, ty) in
  (Term.castExp (e, omega), cons)

let cast_computation c dirty =
  let omega, cnstrs = fresh_dirty_coer (c.ty, dirty) in
  (Term.castComp (c, omega), cnstrs)

let cast_abstraction { term = pat, cmp; _ } dirty =
  let cmp', cnstrs = cast_computation cmp dirty in
  (Term.abstraction (pat, cmp'), cnstrs)

let full_cast_abstraction { term = pat, cmp; _ } ty_in dirty_out =
  let x_pat, x_var = Term.fresh_variable "x" ty_in in
  let exp', cnstrs1 = cast_expression x_var pat.ty in
  let cmp', cnstrs2 = cast_computation cmp dirty_out in
  ( Term.abstraction (x_pat, Term.letVal (exp', Term.abstraction (pat, cmp'))),
    cnstrs1 :: cnstrs2 )
