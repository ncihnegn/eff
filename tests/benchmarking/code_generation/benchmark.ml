open Bechamel
open Toolkit
open Notty_unix
open Loop
open Queens
open Interp
open Range

let number_of_loops = 10

and number_of_queens = 8

and number_of_range = 10

let run_loop_pure = true

and run_loop_latent = false

and run_loop_incr = false

and run_loop_incr' = false

and run_loop_state = false

and run_queens_one = false

and run_queens_all = false

and run_interp = false

and run_range = false

open Bechamel
open Toolkit

let benchmark test =
  let ols =
    Analyze.ols ~bootstrap:0 ~r_square:true ~predictors:Measure.[| run |]
  in
  let instances =
    Instance.[ minor_allocated; major_allocated; monotonic_clock; promoted ]
  in
  let cfg =
    Benchmark.cfg ~limit:2000 ~quota:(Time.second 0.5) ~kde:(Some 1000) ()
  in
  let raw_results = Benchmark.all cfg instances test in
  let results =
    List.map (fun instance -> Analyze.all ols instance raw_results) instances
  in
  let results = Analyze.merge ols instances results in
  (results, raw_results)

let () =
  List.iter
    (fun v -> Bechamel_notty.Unit.add v (Measure.unit v))
    Instance.[ minor_allocated; major_allocated; monotonic_clock; promoted ]

let img (window, results) =
  Bechamel_notty.Multiple.image_of_ols_results ~rect:window
    ~predictor:Measure.run results

let run_and_show test =
  let window =
    match winsize Unix.stdout with
    | Some (w, h) -> { Bechamel_notty.w; h }
    | None -> { Bechamel_notty.w = 80; h = 1 }
  in
  let results, _ = benchmark test in
  img (window, results) |> eol |> output_image

let st = Staged.stage

let () =
  if run_loop_pure then (
    Printf.printf "LOOP PURE BENCHMARK (%d loops):\n" number_of_loops;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st (fun () -> LoopNoOpt._test_pure_11 number_of_loops));
           Test.make ~name:"Generated, optimized"
             (st (fun () -> LoopOpt._test_pure_11 number_of_loops));
           Test.make ~name:"Hand written"
             (st (fun () -> LoopHandWritten.test_pure number_of_loops));
           Test.make ~name:"Native"
             (st (fun () -> LoopNative.test_pure number_of_loops));
         ];
    Printf.printf "\n\n");
  if run_loop_latent then (
    Printf.printf "LOOP LATENT BENCHMARK (%d loops):\n" number_of_loops;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st (fun () -> LoopNoOpt._test_latent_22 number_of_loops));
           Test.make ~name:"Generated, optimized"
             (st (fun () -> LoopOpt._test_latent_22 number_of_loops));
           Test.make ~name:"Hand written"
             (st (fun () -> LoopHandWritten.test_latent number_of_loops));
           Test.make ~name:"Native"
             (st (fun () -> LoopNative.test_latent number_of_loops));
         ];
    Printf.printf "\n\n");
  if run_loop_incr then (
    Printf.printf "LOOP INCR BENCHMARK (%d loops):\n" number_of_loops;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> LoopNoOpt._test_incr_38 number_of_loops);
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> LoopOpt._test_incr_38 number_of_loops);
           Test.make ~name:"Hand written"
             (st @@ fun () -> LoopHandWritten.test_incr number_of_loops);
           Test.make ~name:"Native"
             (st @@ fun () -> LoopNative.test_incr number_of_loops);
         ];
    Printf.printf "\n\n");
  if run_loop_incr' then (
    let n = 100 in
    Printf.printf "LOOP INCR' BENCHMARK (%d loops):\n" n;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> LoopNoOpt._test_incr'_47 n);
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> LoopOpt._test_incr'_47 n);
           Test.make ~name:"Hand written"
             (st @@ fun () -> LoopHandWritten.test_incr' n);
           Test.make ~name:"Native" (st @@ fun () -> LoopNative.test_incr' n);
         ];
    Printf.printf "\n\n");
  if run_loop_incr' then (
    let n = 200 in
    Printf.printf "LOOP INCR' BENCHMARK (%d loops):\n" n;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> LoopNoOpt._test_incr'_47 n);
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> LoopOpt._test_incr'_47 n);
           Test.make ~name:"Hand written"
             (st @@ fun () -> LoopHandWritten.test_incr' n);
           Test.make ~name:"Native" (st @@ fun () -> LoopNative.test_incr' n);
         ];
    Printf.printf "\n\n");
  if run_loop_state then (
    Printf.printf "LOOP STATE BENCHMARK (%d loops):\n" number_of_loops;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> LoopNoOpt._test_state_68 number_of_loops);
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> LoopOpt._test_state_68 number_of_loops);
           Test.make ~name:"Hand written"
             (st @@ fun () -> LoopHandWritten.test_state number_of_loops);
           Test.make ~name:"Native"
             (st @@ fun () -> LoopNative.test_state number_of_loops);
         ];
    Printf.printf "\n\n");
  if run_queens_one then (
    Printf.printf "QUEENS ONE CPS BENCHMARK (%d queens):\n" number_of_queens;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> QueensNoOpt._queens_one_cps_96 number_of_queens);
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> QueensOpt._queens_one_cps_96 number_of_queens);
           Test.make ~name:"Hand written"
             (st @@ fun () -> QueensHandWritten.queens_one_cps number_of_queens);
           Test.make ~name:"Native - CPS"
             (st @@ fun () -> QueensNative.queens_one_cps number_of_queens);
           Test.make ~name:"Native - exceptions"
             ( st @@ fun () ->
               QueensNative.queens_one_exceptions number_of_queens );
         ];
    Printf.printf "\n\n");
  if run_queens_one then (
    Printf.printf "QUEENS ONE OPTION BENCHMARK (%d queens):\n" number_of_queens;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> QueensNoOpt._queens_one_option_94 number_of_queens);
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> QueensOpt._queens_one_option_94 number_of_queens);
           Test.make ~name:"Hand written"
             ( st @@ fun () ->
               QueensHandWritten.queens_one_option number_of_queens );
           Test.make ~name:"Native - option"
             (st @@ fun () -> QueensNative.queens_one_option number_of_queens);
           Test.make ~name:"Native - exceptions"
             ( st @@ fun () ->
               QueensNative.queens_one_exceptions number_of_queens );
         ];
    Printf.printf "\n\n");
  if run_queens_all then (
    Printf.printf "QUEENS ALL BENCHMARK (%d queens):\n" number_of_queens;
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> QueensNoOpt._queens_all_100 number_of_queens);
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> QueensOpt._queens_all_100 number_of_queens);
           Test.make ~name:"Hand written"
             (st @@ fun () -> QueensHandWritten.queens_all number_of_queens);
           Test.make ~name:"Native"
             (st @@ fun () -> QueensNative.queens_all number_of_queens);
         ];
    Printf.printf "\n\n");
  if run_interp then (
    Printf.printf "INTERPRETER BENCHMARK:\n";
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> InterpNoOpt._bigTest_38 ());
           Test.make ~name:"Generated, optimized"
             (st @@ fun () -> InterpOpt._bigTest_38 ());
           Test.make ~name:"Native" (st @@ fun () -> InterpNative.bigTest ());
         ];
    Printf.printf "\n\n");
  if run_range then (
    Printf.printf "RANGE BENCHMARKS:\n";
    run_and_show
    @@ Test.make_grouped ~name:"" ~fmt:"%s%s"
         [
           Test.make ~name:"Generated, not optimized"
             (st @@ fun () -> RangeNoOpt._test_222 number_of_range);
           Test.make ~name:"Generated, pure, optimized"
             (st @@ fun () -> RangeOpt._test_222 number_of_range);
           (* Test.make ~name:"Native" (st @@ ((fun () -> FlatNative.bigTest ()))); *)
         ];
    Printf.printf "\n\n")
