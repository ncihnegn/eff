  $ for f in codegen/*.eff
  > do
  >   echo "======================================================================"
  >   echo $f
  >   echo "----------------------------------------------------------------------"
  >   cat ocamlHeader.ml > $f.ml
  >   echo ";;" >> $f.ml
  >   ../eff.exe --no-stdlib --compile-plain-ocaml --no-header $f >> $f.ml
  >   ocaml $f.ml
  > done
  ======================================================================
  codegen/application_red.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/break-split.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/capability_benchmarks.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/compose.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/constant_folding_match.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/handle_match.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/handle_rec.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/handler_beta_reduction.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/ifthenelse.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/interp.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/is_relatively_pure.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/let_list_to_bind.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/loop.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/map.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/match_red.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/nested_handlers.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/norec.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/not-found.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/one_input.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/optimize_pattern_match.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/optimize_short_circuit.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/original.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/other-effect.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/parser.eff
  ----------------------------------------------------------------------
  Syntax error (file "codegen/parser.eff", line 25, char 11):
  parser error
  ======================================================================
  codegen/pm-1_fails.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/pm-2_passes.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/pm-3_passes.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/queens.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/range.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/rec1.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/rec2.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/redefine_local.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/substitution.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test-handle_effect_skip.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test1.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test10.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test11.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test12.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test13.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test14.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test15.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test16.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test17.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test18.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test19.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test2.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test20.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test21.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test3.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test4.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test5.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test6.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test7.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test8.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/test9.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/top-letrec_fails.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/tree.eff
  ----------------------------------------------------------------------
  ======================================================================
  codegen/two_inputs.eff
  ----------------------------------------------------------------------
-------------------------------------------------------------------------------
