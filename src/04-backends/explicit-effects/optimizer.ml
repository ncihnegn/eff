open Utils

type state = {
  recursive_functions : (Term.variable, Term.abstraction) Assoc.t;
  fuel : int; (* Cache of already specialized functions *)
}

let initial_state =
  { recursive_functions = Assoc.empty; fuel = !Config.optimization_fuel }

let reduce_if_fuel reduce_term state term =
  if state.fuel > 0 then reduce_term { state with fuel = state.fuel - 1 } term
  else term

let add_recursive_function state x abs =
  {
    state with
    recursive_functions = Assoc.update x abs state.recursive_functions;
  }

(* Optimization functions *)

(* Reductions and inlining *)

type inlinability =
  (* Pattern does not occur in in an abstraction body *)
  | NotPresent
  (* Pattern occurs, and occurs at most once in an abstraction and there is no recursion *)
  | Inlinable
  (* Pattern occurs more than once in a body of abstraction or it occurs recursively *)
  | NotInlinable

let is_atomic = function Term.Var _ | Const _ -> true | _ -> false

let applicable_pattern p vars =
  let rec check_variables = function
    | [] -> NotPresent
    | x :: xs -> (
        let inside_occ, outside_occ = Term.occurrences x vars in
        if inside_occ > 0 || outside_occ > 1 then NotInlinable
        else
          match check_variables xs with
          | NotPresent -> if outside_occ = 0 then NotPresent else Inlinable
          | inlinability -> inlinability)
  in
  check_variables (Term.pattern_vars p)

let keep_used_letrec_bindings defs cmp =
  (* Do proper call graph analysis *)
  let free_vars_cmp_in, free_vars_cmp_out = Term.free_vars_comp cmp in
  let free_vars_defs =
    List.map (fun (_, a) -> fst (Term.free_vars_abs a)) defs
  in
  let free_vars =
    List.flatten (free_vars_cmp_in :: free_vars_cmp_out :: free_vars_defs)
  in
  List.filter (fun (x, _) -> List.mem x free_vars) defs

let rec extract_cast_value comp =
  match comp.term with
  | Term.Value exp -> Some exp
  | Term.CastComp (comp, { term = tcoer, _; _ }) ->
      Option.map
        (fun exp -> Term.castExp (exp, tcoer))
        (extract_cast_value comp)
  | _ -> None

let rec recast_computation hnd comp =
  match (comp.term, comp.ty) with
  | Term.CastComp (comp, { term = tcoer, _; _ }), _ ->
      Option.map
        (fun comp ->
          let _, drt = comp.ty in
          Term.castComp
            (comp, Constraint.bangCoercion (tcoer, Constraint.reflDirt drt)))
        (recast_computation hnd comp)
  | _, (ty, { Type.effect_set = effs; Type.row = EmptyRow }) ->
      let handled_effs =
        Type.EffectSet.of_list
          (List.map
             (fun ((eff, _), _) -> eff)
             (Assoc.to_list hnd.term.Term.effect_clauses.effect_part))
      in
      if Type.EffectSet.disjoint effs handled_effs then
        let _, (_, drt_out) = hnd.ty in
        let drt_diff =
          {
            Type.effect_set = Type.EffectSet.diff drt_out.Type.effect_set effs;
            Type.row = drt_out.Type.row;
          }
        in
        let ty_coer = Constraint.reflTy ty
        and drt_coer = Constraint.empty drt_diff in
        Some (Term.castComp (comp, Constraint.bangCoercion (ty_coer, drt_coer)))
      else None
  | _, _ -> None

let rec optimize_ty_coercion state (tcoer : Constraint.ty_coercion) =
  reduce_ty_coercion state
    { tcoer with term = optimize_ty_coercion' state tcoer.term }

and optimize_ty_coercion' state tcoer =
  match tcoer with
  | ReflTy _ -> tcoer
  | ArrowCoercion (tc, dc) ->
      ArrowCoercion
        (optimize_ty_coercion state tc, optimize_dirty_coercion state dc)
  | HandlerCoercion (dc1, dc2) ->
      HandlerCoercion
        (optimize_dirty_coercion state dc1, optimize_dirty_coercion state dc2)
  | TyCoercionVar _ -> tcoer
  | ApplyCoercion (v, lst) ->
      ApplyCoercion (v, List.map (optimize_ty_coercion state) lst)
  | TupleCoercion lst ->
      TupleCoercion (List.map (optimize_ty_coercion state) lst)
  | QualTyCoer (ct_ty, tc) -> QualTyCoer (ct_ty, optimize_ty_coercion state tc)
  | QualDirtCoer (ct_drt, tc) ->
      QualDirtCoer (ct_drt, optimize_ty_coercion state tc)

and optimize_dirt_coercion state (dcoer : Constraint.dirt_coercion) =
  reduce_dirt_coercion state
    { dcoer with term = optimize_dirt_coercion' state dcoer.term }

and optimize_dirt_coercion' state (dcoer : Constraint.dirt_coercion') =
  match dcoer with
  | ReflDirt _ | DirtCoercionVar _ | Empty _ -> dcoer
  | UnionDirt (s, dc) -> UnionDirt (s, optimize_dirt_coercion state dc)

and optimize_dirty_coercion state { term = tcoer, dcoer; _ } =
  Constraint.bangCoercion
    (optimize_ty_coercion state tcoer, optimize_dirt_coercion state dcoer)

and reduce_ty_coercion state ty_coer =
  { ty_coer with term = reduce_ty_coercion' state ty_coer.term }

and reduce_ty_coercion' _state = function
  (* TODO: Is it sufficient to just check if the input and output types match? *)
  | ArrowCoercion
      ( { term = ReflTy ty1; _ },
        { term = { term = ReflTy ty2; _ }, { term = ReflDirt drt; _ }; _ } ) ->
      ReflTy (Type.Arrow (ty1, (ty2, drt)))
  | tcoer -> tcoer

and reduce_dirt_coercion state drt_coer =
  { drt_coer with term = reduce_dirt_coercion' state drt_coer.term }

and reduce_dirt_coercion' _state = function
  | Empty drt when Type.is_empty_dirt drt -> ReflDirt drt
  | UnionDirt (effects, { term = ReflDirt drt; _ }) ->
      ReflDirt (Type.add_effects effects drt)
  | dcoer -> dcoer

let rec optimize_expression state exp =
  (* Print.debug "EXP: %t : %t" (Term.print_expression exp) (Type.print_ty exp.ty); *)
  let exp' = optimize_expression' state exp in
  (* Print.debug "EXP': %t : %t"
     (Term.print_expression exp')
     (Type.print_ty exp'.ty); *)
  assert (Type.equal_ty exp.ty exp'.ty);
  let exp'' = reduce_expression state exp' in
  (* Print.debug "EXP'': %t : %t"
     (Term.print_expression exp'')
     (Type.print_ty exp''.ty); *)
  assert (Type.equal_ty exp'.ty exp''.ty);
  exp''

and optimize_expression' state exp =
  match exp.term with
  | Term.Var _ | Term.Const _ -> exp
  | Term.Tuple exps -> Term.tuple (List.map (optimize_expression state) exps)
  | Term.Record flds -> Term.record (Assoc.map (optimize_expression state) flds)
  | Term.Variant (lbl, arg) ->
      Term.variant (lbl, Option.map (optimize_expression state) arg) exp.ty
  | Term.Lambda abs -> Term.lambda (optimize_abstraction state abs)
  | Term.Handler hnd -> Term.handler (optimize_handler state hnd)
  | Term.CastExp (exp, coer) ->
      Term.castExp
        (optimize_expression state exp, optimize_ty_coercion state coer)
  | Term.LambdaTyCoerVar (w, exp) ->
      Term.lambdaTyCoerVar (w, optimize_expression state exp)
  | Term.LambdaDirtCoerVar (d, exp) ->
      Term.lambdaDirtCoerVar (d, optimize_expression state exp)
  | Term.ApplyTyCoercion (exp, tcoer) ->
      Term.applyTyCoercion
        (optimize_expression state exp, optimize_ty_coercion state tcoer)
  | Term.ApplyDirtCoercion (exp, dcoer) ->
      Term.applyDirtCoercion
        (optimize_expression state exp, optimize_dirt_coercion state dcoer)

and optimize_computation state cmp =
  Print.debug "CMP: %t" (Term.print_computation cmp);
  let cmp' = optimize_computation' state cmp in
  Print.debug "CMP': %t" (Term.print_computation cmp');
  assert (Type.equal_dirty cmp.ty cmp'.ty);
  let cmp'' = reduce_computation state cmp' in
  Print.debug "CMP'': %t" (Term.print_computation cmp'');
  assert (Type.equal_dirty cmp'.ty cmp''.ty);
  cmp''

and optimize_computation' state cmp =
  match cmp.term with
  | Term.Value exp -> Term.value (optimize_expression state exp)
  | Term.LetVal (exp, abs) ->
      Term.letVal (optimize_expression state exp, optimize_abstraction state abs)
  | Term.LetRec (defs, cmp) -> Term.letRec (defs, optimize_computation state cmp)
  | Term.Match (exp, cases) ->
      Term.match_
        ( optimize_expression state exp,
          List.map (optimize_abstraction state) cases )
        cmp.ty
  | Term.Apply (exp1, exp2) ->
      Term.apply (optimize_expression state exp1, optimize_expression state exp2)
  | Term.Handle (exp, cmp) ->
      Term.handle (optimize_expression state exp, optimize_computation state cmp)
  | Term.Call (eff, exp, abs) ->
      Term.call
        (eff, optimize_expression state exp, optimize_abstraction state abs)
  | Term.Bind (cmp, abs) ->
      Term.bind (optimize_computation state cmp, optimize_abstraction state abs)
  | Term.CastComp (cmp, dtcoer) ->
      Term.castComp
        (optimize_computation state cmp, optimize_dirty_coercion state dtcoer)

and optimize_handler state hnd =
  {
    hnd with
    term =
      {
        Term.value_clause = optimize_abstraction state hnd.term.value_clause;
        Term.effect_clauses =
          {
            hnd.term.effect_clauses with
            effect_part =
              Assoc.map
                (optimize_abstraction2 state)
                hnd.term.effect_clauses.effect_part;
          };
      };
  }

and optimize_abstraction state abs =
  { abs with term = optimize_abstraction' state abs.term }

and optimize_abstraction' state (pat, cmp) =
  (pat, optimize_computation state cmp)

and optimize_abstraction2 state abs2 =
  { abs2 with term = optimize_abstraction2' state abs2.term }

and optimize_abstraction2' state (pat1, pat2, cmp) =
  (pat1, pat2, optimize_computation state cmp)

and cast_expression _state exp coer =
  match (exp.term, coer.term) with
  | _, _ when Constraint.is_trivial_ty_coercion coer -> exp
  | _, _ -> Term.castExp (exp, coer)

and cast_computation state comp coer =
  match (comp.term, coer.term) with
  | _, _ when Constraint.is_trivial_dirty_coercion coer -> comp
  | Term.Bind (cmp, abs), (_, dcoer) ->
      let ty1, _ = cmp.ty in
      let coer1 = Constraint.bangCoercion (Constraint.reflTy ty1, dcoer) in
      bind_computation state
        (cast_computation state cmp coer1)
        (cast_abstraction state abs coer)
  | Term.Call (eff, exp, abs), _ ->
      Term.call (eff, exp, cast_abstraction state abs coer)
  | _, _ -> Term.castComp (comp, coer)

and cast_abstraction state { term = pat, cmp; _ } coer =
  Term.abstraction (pat, cast_computation state cmp coer)

and bind_computation state comp bind =
  match comp.term with
  | Term.Bind (comp, abs) ->
      bind_computation state comp (bind_abstraction state abs bind)
  | Term.Call (eff, exp, abs) ->
      Term.call (eff, exp, bind_abstraction state abs bind)
  | _ -> (
      match extract_cast_value comp with
      | Some exp -> beta_reduce state bind exp
      | None -> Term.bind (comp, bind))

and bind_abstraction state { term = pat, cmp; _ } bind =
  Term.abstraction (pat, bind_computation state cmp bind)

and handle_computation state specialized hnd comp =
  match comp.term with
  | Term.Match (exp, cases) ->
      let _, drty_out = hnd.ty in
      Term.match_
        (exp, List.map (handle_abstraction state specialized hnd) cases)
        drty_out
      |> optimize_computation state
  | LetVal (exp, abs) ->
      Term.letVal (exp, handle_abstraction state specialized hnd abs)
      |> optimize_computation state
  | LetRec (defs, comp) ->
      Term.letRec (defs, handle_computation state specialized hnd comp)
      |> optimize_computation state
  | Call (eff, exp, abs) -> (
      let handled_abs = handle_abstraction state specialized hnd abs in
      match Assoc.lookup eff hnd.term.Term.effect_clauses.effect_part with
      | Some { term = p1, p2, comp; _ } ->
          (* TODO: Refresh abstraction? *)
          let comp' =
            beta_reduce state
              (Term.abstraction (p2, comp))
              (Term.lambda handled_abs)
          in
          beta_reduce state (Term.abstraction (p1, comp')) exp
      | None -> Term.call (eff, exp, handled_abs))
  | Apply ({ term = Var f; _ }, exp)
    when Option.is_some (Assoc.lookup f specialized) -> (
      match Assoc.lookup f specialized with
      | Some (f', ty') -> Term.apply (Term.var f' ty', exp)
      | None -> assert false)
  | Bind (cmp, abs) -> (
      match recast_computation hnd cmp with
      | Some comp' ->
          bind_computation state comp'
            (handle_abstraction state specialized hnd abs)
      | None ->
          let (_, drt_in), _ = hnd.ty in
          let hnd' =
            Term.handler_clauses
              (handle_abstraction state specialized hnd abs)
              hnd.term.Term.effect_clauses.effect_part drt_in
          in
          handle_computation state specialized hnd' cmp)
  | _ -> (
      match recast_computation hnd comp with
      | Some comp' -> bind_computation state comp' hnd.term.Term.value_clause
      | None -> Term.handle (Term.handler hnd, comp))

and handle_abstraction state specialized hnd { term = p, c; _ } =
  Term.abstraction (p, handle_computation state specialized hnd c)

and substitute_pattern_comp st c p exp =
  optimize_computation st (Term.subst_comp (Term.pattern_match p exp) c)

and substitute_pattern_expr st e p exp =
  optimize_expression st (Term.subst_expr (Term.pattern_match p exp) e)

and beta_reduce state ({ term = p, c; _ } as a) e =
  Print.debug "Beta reduce: %t; %t" (Term.print_abstraction a)
    (Term.print_expression e);
  match applicable_pattern p (Term.free_vars_comp c) with
  | Inlinable -> substitute_pattern_comp state c p e
  | NotPresent -> c
  | NotInlinable ->
      if is_atomic e.term then
        (* Inline constants and variables anyway *)
        substitute_pattern_comp state c p e
      else Term.letVal (e, a)

and reduce_expression state expr = reduce_if_fuel reduce_expression' state expr

and reduce_expression' state expr =
  match expr.term with
  | Term.CastExp (exp, tcoer) -> cast_expression state exp tcoer
  | _ -> expr

and reduce_computation state comp =
  reduce_if_fuel reduce_computation' state comp

and reduce_computation' state comp =
  match comp.term with
  (* TODO: matches of a constant *)
  | Term.CastComp (cmp, dtcoer) -> cast_computation state cmp dtcoer
  | Term.LetVal (e, abs) -> beta_reduce state abs e
  | Term.Apply ({ term = Term.Lambda a; _ }, e) -> beta_reduce state a e
  | Term.Apply
      ( {
          term =
            Term.CastExp
              (exp, { term = Constraint.ArrowCoercion (ty_coer, drty_coer); _ });
          _;
        },
        e ) ->
      cast_computation state
        (optimize_computation state
           (Term.apply (exp, cast_expression state e ty_coer)))
        drty_coer
  | Term.LetRec (defs, c) -> (
      let state' =
        List.fold_right
          (fun (v, abs) state -> add_recursive_function state v abs)
          defs state
      in
      let c' = reduce_computation state' c in
      match keep_used_letrec_bindings defs c' with
      | [] -> c'
      | defs' -> Term.letRec (defs', c'))
  | Term.Bind (cmp, abs) -> bind_computation state cmp abs
  | Term.Handle ({ term = Term.Handler hnd; _ }, cmp) -> (
      let specialized =
        state.recursive_functions
        |> Assoc.kmap (fun (f, abs) ->
               let f' = Language.CoreTypes.Variable.refresh f in
               let (ty_in, _), (_, drty_out) = (abs.ty, hnd.ty) in
               let ty' = Type.Arrow (ty_in, drty_out) in
               (f, (f', ty')))
      in
      let cmp' = handle_computation state specialized hnd cmp in
      let defs =
        Assoc.kmap
          (fun (f, abs) ->
            match Assoc.lookup f specialized with
            | Some (f', _) -> (f', handle_abstraction state specialized hnd abs)
            | None -> assert false)
          state.recursive_functions
      in
      match Assoc.to_list defs with
      | [] -> cmp'
      | defs' -> Term.letRec (defs', cmp'))
  | Term.Handle
      ( {
          term =
            Term.CastExp
              ( exp,
                {
                  term = Constraint.HandlerCoercion (drty_coer1, drty_coer2);
                  _;
                } );
          _;
        },
        cmp ) ->
      cast_computation state
        (optimize_computation state
           (Term.handle (exp, cast_computation state cmp drty_coer1)))
        drty_coer2
  | _ -> comp
