open OcamlHeader

type tree = Empty | Node of (tree * int * tree)

type (_, _) eff_internal_effect += Choose : (unit, bool) eff_internal_effect

let _tester_42 (_k_43 : int) =
  let _leaf_44 (_a_45 : int) = Node (Empty, _a_45 * _k_43, Empty) in
  let _bot_48 (_t_49 : tree) (_t2_50 : tree) =
    Node
      ( Node (Node (_t_49, 0, _t2_50), 2, _leaf_44 13),
        5,
        Node (_leaf_44 9, 7, Node (_t2_50, 3, Node (_leaf_44 3, 5, _t2_50))) )
  in
  _bot_48
    (Node
       (_bot_48 (_leaf_44 3) (_leaf_44 4), 10, _bot_48 (_leaf_44 1) (_leaf_44 3)))
    (_bot_48
       (Node
          ( _bot_48 (_leaf_44 3) (_leaf_44 4),
            10,
            _bot_48 (_leaf_44 1) (_leaf_44 3) ))
       (_leaf_44 10))

let tester = _tester_42

let _max_88 (_a_89 : int) (_b_90 : int) = if _a_89 > _b_90 then _a_89 else _b_90

let max = _max_88

let _effect_max_93 (_m_94 : int) =
  let rec _find_max_95 _x_115 =
    match _x_115 with
    | Empty -> Value 0
    | Node (Empty, _x_123, Empty) -> Value _x_123
    | Node (_left_126, _x_125, _right_124) ->
        Call
          ( Choose,
            (),
            fun (_y_127 : bool) ->
              (if _y_127 then _find_max_95 _left_126
              else _find_max_95 _right_124)
              >> fun _next_128 -> Value (_x_125 + _next_128) )
  in
  let rec _find_max_133 (_x_115, _k_135) =
    match _x_115 with
    | Empty -> _k_135 0
    | Node (Empty, _x_123, Empty) -> _k_135 _x_123
    | Node (_left_126, _x_125, _right_124) ->
        let _l_116 (_y_127 : bool) =
          if _y_127 then
            _find_max_133
              (_left_126, fun (_next_128 : int) -> _k_135 (_x_125 + _next_128))
          else
            _find_max_133
              (_right_124, fun (_next_128 : int) -> _k_135 (_x_125 + _next_128))
        in
        _max_88 (_l_116 true) (_l_116 false)
  in
  _find_max_133 (_tester_42 _m_94, fun (_x_110 : int) -> _x_110)

let effect_max = _effect_max_93

let _test_max_138 (_m_139 : int) = _effect_max_93 _m_139

let test_max = _test_max_138

let _op_140 (_x_141 : int) (_y_142 : int) = _x_141 - (3 * _y_142)

let op = _op_140

let _max_146 (_a_147 : int) (_b_148 : int) =
  if _a_147 > _b_148 then _a_147 else _b_148

let max = _max_146

type intlist = Nil | Cons of (int * intlist)

let rec _op_151 (* @ *) _x_158 (_ys_160 : intlist) =
  match _x_158 with
  | Nil -> _ys_160
  | Cons (_x_162, _xs_161) -> Cons (_x_162, _op_151 (* @ *) _xs_161 _ys_160)

let _op_151 (* @ *) = _op_151 (* @ *)

let _test_general_165 (_m_166 : int) =
  let rec _maxl_167 _x_197 (_x_232 : intlist) =
    match _x_232 with
    | Nil -> _x_197
    | Cons (_x_234, _xs_233) -> _maxl_167 (_max_146 _x_234 _x_197) _xs_233
  in
  let rec _explore_176 _x_200 =
    match _x_200 with
    | Empty -> Value 0
    | Node (_left_216, _x_215, _right_214) ->
        Call
          ( Choose,
            (),
            fun (_y_217 : bool) ->
              (if _y_217 then
               _explore_176 _left_216 >> fun _b_220 ->
               Value (_op_140 _x_215 _b_220)
              else
                _explore_176 _right_214 >> fun _b_222 ->
                Value (_op_140 _x_215 _b_222))
              >> fun _next_218 -> Value _next_218 )
  in
  _maxl_167 0
    (let rec _explore_226 (_x_200, _k_228) =
       match _x_200 with
       | Empty -> _k_228 0
       | Node (_left_216, _x_215, _right_214) ->
           let _l_201 (_y_217 : bool) =
             if _y_217 then
               _explore_226
                 ( _left_216,
                   fun (_b_220 : int) -> _k_228 (_op_140 _x_215 _b_220) )
             else
               _explore_226
                 ( _right_214,
                   fun (_b_222 : int) -> _k_228 (_op_140 _x_215 _b_222) )
           in
           _op_151 (* @ *) (_l_201 true) (_l_201 false)
     in
     _explore_226 (_tester_42 _m_166, fun (_x_192 : int) -> Cons (_x_192, Nil)))

let test_general = _test_general_165

type (_, _) eff_internal_effect += Get : (unit, int) eff_internal_effect

let _absurd_238 (_void_239 : float) = match _void_239 with _ -> assert false

let absurd = _absurd_238

let _test_leaf_state_240 (_m_241 : int) =
  let rec _maxl_242 _x_293 (_x_362 : intlist) =
    match _x_362 with
    | Nil -> _x_293
    | Cons (_x_364, _xs_363) -> _maxl_242 (_max_146 _x_364 _x_293) _xs_363
  in
  let rec _populate_leafs_250 _x_294 (_n_339 : int) =
    if _x_294 = _n_339 then Nil
    else Cons (_x_294 * 3, _populate_leafs_250 (_x_294 + 1) _n_339)
  in
  let rec _explore_264 _x_299 =
    match _x_299 with
    | Empty -> Call (Get, (), fun (_y_324 : int) -> Value _y_324)
    | Node (_left_327, _x_326, _right_325) ->
        Call
          ( Choose,
            (),
            fun (_y_328 : bool) ->
              _explore_264 (if _y_328 then _left_327 else _right_325)
              >> fun _b_331 -> Value (_op_140 _x_326 _b_331) )
  in
  _maxl_242 0
    ((let rec _explore_334 (_x_299, _k_336) =
        match _x_299 with
        | Empty -> Call (Get, (), fun (_y_324 : int) -> _k_336 _y_324)
        | Node (_left_327, _x_326, _right_325) ->
            let _l_300 (_y_328 : bool) =
              _explore_334
                ( (if _y_328 then _left_327 else _right_325),
                  fun (_b_331 : int) -> _k_336 (_op_140 _x_326 _b_331) )
            in
            _l_300 true >> fun _b_276 ->
            _l_300 false >> fun _b_277 -> Value (_op_151 (* @ *) _b_276 _b_277)
      in
      let rec _explore_348 (_x_299, _k_336) =
        match _x_299 with
        | Empty -> (
            fun (_s_350 : intlist) ->
              match _s_350 with
              | Cons (_x_352, _rest_351) ->
                  force_unsafe
                    ((handler
                        {
                          value_clause =
                            (fun (_x_355 : intlist) ->
                              Value (fun (_ : intlist) -> _x_355));
                          effect_clauses =
                            (fun (type a b) (eff : (a, b) eff_internal_effect) :
                                 (a -> (b -> _) -> _) ->
                              match eff with
                              | Get ->
                                  fun () _l_356 ->
                                    Value
                                      (fun (_s_357 : intlist) ->
                                        match _s_357 with
                                        | Cons (_x_359, _rest_358) ->
                                            coer_arrow coer_refl_ty force_unsafe
                                              _l_356 _x_359 _rest_358
                                        | Nil -> Nil)
                              | eff' -> fun arg k -> Call (eff', arg, k));
                        })
                       (_k_336 _x_352))
                    _rest_351
              | Nil -> Nil)
        | Node (_left_327, _x_326, _right_325) ->
            let _l_300 (_y_328 : bool) =
              _explore_334
                ( (if _y_328 then _left_327 else _right_325),
                  fun (_b_331 : int) -> _k_336 (_op_140 _x_326 _b_331) )
            in
            force_unsafe
              ((handler
                  {
                    value_clause =
                      (fun (_b_276 : intlist) ->
                        Value
                          (force_unsafe
                             ((handler
                                 {
                                   value_clause =
                                     (fun (_b_277 : intlist) ->
                                       Value
                                         (fun (_ : intlist) ->
                                           _op_151 (* @ *) _b_276 _b_277));
                                   effect_clauses =
                                     (fun (type a b)
                                          (eff : (a, b) eff_internal_effect) :
                                          (a -> (b -> _) -> _) ->
                                       match eff with
                                       | Get ->
                                           fun () _l_313 ->
                                             Value
                                               (fun (_s_314 : intlist) ->
                                                 match _s_314 with
                                                 | Cons (_x_316, _rest_315) ->
                                                     coer_arrow coer_refl_ty
                                                       force_unsafe _l_313
                                                       _x_316 _rest_315
                                                 | Nil -> Nil)
                                       | eff' -> fun arg k -> Call (eff', arg, k));
                                 })
                                (_l_300 false))));
                    effect_clauses =
                      (fun (type a b) (eff : (a, b) eff_internal_effect) :
                           (a -> (b -> _) -> _) ->
                        match eff with
                        | Get ->
                            fun () _l_313 ->
                              Value
                                (fun (_s_314 : intlist) ->
                                  match _s_314 with
                                  | Cons (_x_316, _rest_315) ->
                                      coer_arrow coer_refl_ty force_unsafe
                                        _l_313 _x_316 _rest_315
                                  | Nil -> Nil)
                        | eff' -> fun arg k -> Call (eff', arg, k));
                  })
                 (_l_300 true))
      in
      _explore_348
        (_tester_42 _m_241, fun (_x_278 : int) -> Value (Cons (_x_278, Nil))))
       (_populate_leafs_250 0 154))

let test_leaf_state = _test_leaf_state_240
