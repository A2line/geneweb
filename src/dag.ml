(* $Id: dag.ml,v 3.25 2001-01-06 15:25:57 ddr Exp $ *)

open Dag2html;
open Def;
open Config;
open Gutil;
open Util;
open Printf;

module Pset = Set.Make (struct type t = iper; value compare = compare; end);

(* testing *)

value map_dag f d =
  let a =
    Array.map (fun d -> {pare = d.pare; valu = f d.valu; chil = d.chil}) d.dag
  in
  {dag = a}
;

value tag_dag d =
  let c = ref 'A' in
  map_dag
    (fun v ->
       let v = c.val in
       do c.val :=
            if c.val = 'Z' then 'a'
            else if c.val = 'z' then '1'
            else Char.chr (Char.code c.val + 1);
       return v)
    d
;

(* input dag *)

value get_dag_elems conf base =
  loop None Pset.empty 1 where rec loop prev_po set i =
    let s = string_of_int i in
    let po = Util.find_person_in_env conf base s in
    let po = match po with [ None -> prev_po | x -> x ] in
    let so = Util.p_getenv conf.env ("s" ^ s) in
    match (po, so) with
    [ (Some p, Some s) ->
        let set =
          match Util.branch_of_sosa base p.cle_index (Num.of_string s) with
          [ Some ipsl ->
              List.fold_left (fun set (ip, _) -> Pset.add ip set) set ipsl
          | None -> set ]
        in
        loop po set (i + 1)
    | _ -> set ]
;

type sum 'a 'b = [ Left of 'a | Right of 'b ];

value make_dag conf base list =
  let module O = struct type t = iper; value compare = compare; end in
  let module M = Map.Make O in
  let nodes = Array.of_list list in
  let map =
    loop M.empty 0 where rec loop map i =
      if i = Array.length nodes then map
      else loop (M.add nodes.(i) (idag_of_int i) map) (i + 1)
  in
  let nodes =
    Array.map
      (fun ip ->
(*
do Printf.eprintf "\no %s\n" (denomination base (poi base ip)); flush stderr; return
*)
(*
do let p = poi base ip in Printf.eprintf "\no %s%s\n" (Util.person_title_text conf base p) (Date.short_dates_text conf base p); flush stderr; return
*)
         let pare =
           match (aoi base ip).parents with
           [ Some ifam ->
               let c = coi base ifam in
               let l = try [M.find c.mother map] with [ Not_found -> [] ] in
               try [M.find c.father map :: l] with [ Not_found -> l ]
           | None -> [] ]
         in
(*
do Printf.eprintf "parents\n"; flush stderr; return
do List.iter (fun id -> Printf.eprintf "- %s\n" (denomination base (poi base nodes.(int_of_idag id)))) pare; flush stderr; return
*)
         let chil =
           let u = uoi base ip in
           Array.fold_left
             (fun chil ifam ->
                let des = doi base ifam in
                Array.fold_left
                  (fun chil ip ->
                     try [M.find ip map :: chil] with [ Not_found -> chil ])
                  chil des.children)
             [] u.family
         in
         let chil = List.rev chil in
(*
do Printf.eprintf "children\n"; flush stderr; return
do List.iter (fun id -> Printf.eprintf "- %s\n" (denomination base (poi base nodes.(int_of_idag id)))) chil; flush stderr; return
*)
(*
do List.iter (fun id -> let p = poi base nodes.(int_of_idag id) in Printf.eprintf "- %s%s\n" (Util.person_title_text conf base p) (Date.short_dates_text conf base p)) chil; flush stderr; return
*)
         {pare = pare; valu = Left ip; chil = chil})
      nodes
  in
  {dag = nodes}
;

value image_normal_txt conf base p fname width height =
  let image_txt = capitale (transl_nth conf "image/images" 0) in
  let s = Unix.stat fname in
  let b = acces conf base p in
  let k = default_image_name base p in
  sprintf "<a href=\"%sm=IM;%s;k=/%s\">" (commd conf) b k ^
  sprintf "\
<img src=\"%sm=IM;d=%d;%s;k=/%s\" width=%d height=%d border=0 alt=\"%s\">"
        (commd conf)
        (int_of_float (mod_float s.Unix.st_mtime (float_of_int max_int)))
        b k width height image_txt ^
  "</a>"
;

value image_url_txt conf base url height =
  let image_txt = capitale (transl_nth conf "image/images" 0) in
  sprintf "<a href=\"%s\">" url ^
  sprintf "<img src=\"%s\"\nheight=%d border=0 alt=\"%s\">" url
    height image_txt ^
  "</a>\n"
;

value image_txt conf base p =
  match p_getenv conf.env "image" with
  [ Some "on" ->
      match image_and_size conf base p (limited_image_size 100 75) with
      [ Some (f, Some (Some (wid, hei))) ->
          "<br>\n<center><table border=0><tr><td>\n" ^
          image_normal_txt conf base p f wid hei ^
          "</table></center>\n"
      | Some (url, None) ->
          "<br>\n<center><table border=0><tr><td>\n" ^
          image_url_txt conf base url 75 ^
          "</table></center>\n"
      | _ -> "" ]
  | _ -> "" ]
;

value print_table conf hts =
  do Wserver.wprint "<center><table border=%d" conf.border;
     Wserver.wprint " cellspacing=0 cellpadding=0>\n";
     for i = 0 to Array.length hts - 1 do
       Wserver.wprint "<tr>\n";
       for j = 0 to Array.length hts.(i) - 1 do
         let (colspan, align, td) = hts.(i).(j) in
         do Wserver.wprint "<td";
(*
            if colspan > 1 then Wserver.wprint " colspan=%d" colspan else ();
*)
if colspan=1 && (td=TDstring "&nbsp;" || td=TDhr CenterA) then ()
else Wserver.wprint " colspan=%d" colspan;
(**)
            match (align, td) with
            [ (LeftA, TDhr LeftA) -> Wserver.wprint " align=left"
            | (LeftA, _) -> ()
            | (CenterA, _) -> Wserver.wprint " align=center"
            | (RightA, _) -> Wserver.wprint " align=right" ];
            Wserver.wprint ">";
            match td with
            [ TDstring s -> Wserver.wprint "%s" s
            | TDhr align ->
                do Wserver.wprint "<hr noshade size=1";
                   match align with
                   [ LeftA -> Wserver.wprint " width=\"50%%\" align=left"
                   | RightA -> Wserver.wprint " width=\"50%%\" align=right"
                   | _ -> () ];
                   Wserver.wprint ">";
                return () ];
            Wserver.wprint "</td>\n";
         return ();
       done;
     done;
     Wserver.wprint "</table></center>\n";
  return () 
;

value displayed_length s =
  loop 0 0 where rec loop len i =
    if i = String.length s then len
    else
      match s.[i] with
      [ '<' ->
          loop1 (i + 1) where rec loop1 i =
            if i = String.length s then len
            else if s.[i] = '>' then loop len (i + 1)
            else loop1 (i + 1)
      | '&' ->
          let len = len + 1 in
          loop1 (i + 1) where rec loop1 i =
            if i = String.length s then len
            else
              match s.[i] with
              [ 'a'..'z' | 'A'..'Z' -> loop1 (i + 1)
              | ';' -> loop len (i + 1)
              | _ -> loop len i ]
      | '\n' | '\r' -> len
      | _ -> loop (len + 1) (i + 1) ]
;

value print_table_pre conf hts =
  let ncol =
    let hts0 = hts.(0) in
    loop 0 0 where rec loop ncol j =
      if j = Array.length hts0 then ncol
      else
        let (colspan, _, _) = hts0.(j) in
        loop (ncol + colspan) (j + 1)
  in
  let colsz = Array.make ncol 0 in
  do loop 1 where rec loop curr_colspan =
       let next_colspan = ref (ncol + 1) in
       do for i = 0 to Array.length hts - 1 do
            if i = Array.length hts then ()
            else
              loop 0 0 where rec loop col j =
                if j = Array.length hts.(i) then ()
                else
                  let (colspan, _, td) = hts.(i).(j) in
                  do match td with
                     [ TDstring s ->
                         if colspan = curr_colspan then
                           let len = displayed_length s in
                           let currsz =
                             loop 0 col colspan
                             where rec loop currsz col cnt =
                               if cnt = 0 then currsz
                               else
                                 let currsz = currsz + colsz.(col) in
                                 loop currsz (col + 1) (cnt - 1)
                           in
                           if currsz >= len then ()
                           else
                             loop 1 col colspan where rec loop n col cnt =
                               if cnt = 0 then ()
                               else
                                 let inc_sz =
                                   n * (len - currsz) / colspan -
                                   (n - 1) * (len - currsz) / colspan
                                 in
                                 do colsz.(col) := colsz.(col) + inc_sz;
                                 return loop (n + 1) (col + 1) (cnt - 1)
                         else if colspan > curr_colspan then
                           next_colspan.val := min colspan next_colspan.val
                         else ()
                     | TDhr _ -> () ];
                  return loop (col + colspan) (j + 1);
          done;
       return
       if next_colspan.val > ncol then () else loop next_colspan.val;
  return
  do Wserver.wprint "<pre>\n";
     for i = 0 to Array.length hts - 1 do
       loop 0 0 where rec loop col j =
         if j = Array.length hts.(i) then Wserver.wprint "\n"
         else
           let (colspan, align, td) = hts.(i).(j) in
           let sz =
             loop 0 colspan where rec loop sz k =
               if k = 0 then sz else loop (sz + colsz.(col + k - 1)) (k - 1)
           in
           do match td with
              [ TDstring s ->
                  let len = displayed_length s in
                  do for i = 1 to (sz - len) / 2 do
                       Wserver.wprint " ";
                     done;
                     Wserver.wprint "%s" s;
                     for i = (sz + len) / 2 + 1 to sz do
                       Wserver.wprint " ";
                     done;
                  return ()
              | TDhr LeftA ->
                  let len = (sz + 1) / 2 in
                  do for i = 1 to len do Wserver.wprint "-"; done;
                     for i = len + 1 to sz do Wserver.wprint " "; done;
                  return ()
              | TDhr RightA ->
                  let len = sz / 2 in
                  do for i = 1 to sz - len - 1 do Wserver.wprint " "; done;
                     for i = sz - len to sz do Wserver.wprint "-"; done;
                  return ()
              | TDhr CenterA ->
                  for i = 1 to sz do Wserver.wprint "-"; done ];
           return loop (col + colspan) (j + 1);
     done;
     Wserver.wprint "</pre>\n";
  return () 
;

(* main *)

value print_only_dag conf base elem_txt spouse_on invert set spl d =
  let t = table_of_dag False invert d in
  let indi_txt n =
    match n.valu with
    [ Left ip ->
        let p = poi base ip in
        let txt = elem_txt conf base p in
        let txt =
          let spouses =
            if (spouse_on && n.chil <> [] || n.pare = []) && not invert then
              List.fold_left
                (fun list id ->
                   match d.dag.(int_of_idag id).valu with
                   [ Left cip ->
                       match (aoi base cip).parents with
                       [ Some ifam ->
                           let cpl = coi base ifam in
                           if ip == cpl.father then
                             if List.mem_assoc cpl.mother list then list
                             else [(cpl.mother, Some ifam) :: list]
                           else if ip == cpl.mother then
                             if List.mem_assoc cpl.father list then list
                             else [(cpl.father, Some ifam) :: list]
                           else list
                       | None -> list ]
                   | Right _ -> list ])
                [] n.chil
            else if n.chil = [] then
              try [List.assq ip spl] with [ Not_found -> [] ]
            else []
          in
          List.fold_left
            (fun txt (ips, ifamo) ->
               if Pset.mem ips set then txt
               else
                 let ps = poi base ips in
                 let d =
                   match ifamo with
                   [ Some ifam ->
                       Date.short_marriage_date_text conf base (foi base ifam)
                         p ps
                   | None -> "" ]
                 in
                 txt ^ "<br>\n&amp;" ^ d ^ " " ^
                 Util.referenced_person_title_text conf base ps ^
                 Date.short_dates_text conf base ps)
            txt spouses
        in
        let txt = txt ^ image_txt conf base p in
        txt
    | Right _ -> "&nbsp;" ]
  in
  let bd =
    match Util.p_getint conf.env "bd" with
    [ Some x -> x
    | _ -> 0 ]
  in
  let td =
    match Util.p_getenv conf.env "td" with
    [ Some x -> " " ^ x
    | _ -> "" ]
  in
  let indi_txt n =
    let (bd, td) =
      match n.valu with
      [ Left ip -> (bd, td)
      | _ -> (0, "") ]
    in
    if bd > 0 || td <> "" then
      sprintf "<table border=%d><tr><td align=center%s>%s</table>" bd td
        (indi_txt n)
    else indi_txt n
  in
  let phony n =
    match n.valu with
    [ Left _ -> False
    | Right _ -> True ]
  in
  match Util.p_getenv conf.env "prev" with
  [ Some "on" ->
      let print_indi n = Wserver.wprint "%s" (indi_txt n) in
      print_html_table (fun x -> Wserver.wprint "%s" x) print_indi phony
        conf.border d t
  | _ ->
      let hts = html_table_struct indi_txt phony d t in
(*
      print_table conf hts
*)
      print_table_pre conf hts ]
;

value gen_print_dag conf base spouse_on invert set spl d =
  let title _ =
    Wserver.wprint "%s" (Util.capitale (Util.transl conf "tree"))
  in
  let elem_txt conf base p =
    Util.referenced_person_title_text conf base p ^
    Date.short_dates_text conf base p
  in
  do Util.header_no_page_title conf title;
     print_only_dag conf base elem_txt spouse_on invert set spl d;
     Util.trailer conf;
  return ()
;

value print_dag conf base set spl d =
  let spouse_on =
    match Util.p_getenv conf.env "spouse" with
    [ Some "on" -> True
    | _ -> False ]
  in
  let invert =
    match Util.p_getenv conf.env "invert" with
    [ Some "on" -> True
    | _ -> False ]
  in
  gen_print_dag conf base spouse_on invert set spl d
;

value print conf base =
  let set = get_dag_elems conf base in
  let d = make_dag conf base (Pset.elements set) in
  print_dag conf base set [] d
;
