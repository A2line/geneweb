(* $Id: sendImage.ml,v 5.7 2007-09-12 09:58:44 ddr Exp $ *)

open Config
open Def
open Gwdb
open Util

type image_type = JPEG | GIF | PNG
type image_kind = KeyImage | KeyDir

let image_types = [JPEG; GIF; PNG]

let extension_of_type =
  function
    JPEG -> ".jpg"
  | GIF -> ".gif"
  | PNG -> ".png"

let incorrect conf = Hutil.incorrect_request conf; raise Update.ModErr

let incorrect_content_type conf base p s =
  let title _ = Wserver.printf "%s" (capitale (transl conf "error")) in
  Hutil.rheader conf title;
  Hutil.print_link_to_welcome conf true;
  Wserver.printf "<p>\n";
  Wserver.printf "<em style=\"font-size:smaller\">";
  Wserver.printf "Error: incorrect image content type: %s" s;
  Wserver.printf "</em>\n";
  Wserver.printf "</p>\n";
  Wserver.printf "<ul>\n";
  Wserver.printf "<li>\n";
  Wserver.printf "%s" (referenced_person_title_text conf base p);
  Wserver.printf "</li>\n";
  Wserver.printf "</ul>\n";
  Hutil.trailer conf;
  raise Update.ModErr

let error_too_big_image conf base p len max_len =
  let title _ = Wserver.printf "%s" (capitale (transl conf "error")) in
  Hutil.rheader conf title;
  Hutil.print_link_to_welcome conf true;
  Wserver.printf "<p><em style=\"font-size:smaller\">";
  Wserver.printf "Error: this image is too big: %d bytes<br%s>\n" len
    conf.xhs;
  Wserver.printf "Maximum authorized in this database: %d bytes<br%s>\n"
    max_len conf.xhs;
  Wserver.printf "</em></p>\n";
  Wserver.printf "<ul>\n";
  Wserver.printf "<li>\n";
  Wserver.printf "%s" (referenced_person_title_text conf base p);
  Wserver.printf "</li>\n";
  Wserver.printf "</ul>\n";
  Hutil.trailer conf;
  raise Update.ModErr

let raw_get conf key =
  try List.assoc key conf.env with Not_found -> incorrect conf

(* print delete image link *)
let print_link_delete_image conf base digest p =
  let _ = Printf.eprintf "Print_link_delete\n" in
  let _ = flush stderr in
  if Util.has_image conf base p || Util.has_keydir conf base p then
    begin
      let title = (capitale (transl conf "suppress images")) in
      Wserver.printf "<h2>\n";
      Wserver.printf "%s\n" title;
      Wserver.printf "</h2>\n";
      Wserver.printf
        "<form method=\"post\" action=\"%s\" enctype=\"multipart/form-data\">\n"
        conf.command;
      Wserver.printf "<p>\n";
      Util.hidden_env conf;
      Wserver.printf
        "<input type=\"hidden\" name=\"m\" value=\"DEL_IMAGE\"%s>\n" conf.xhs;
      Wserver.printf "<input type=\"hidden\" name=\"i\" value=\"%d\"%s>\n"
        (Adef.int_of_iper (get_key_index p)) conf.xhs;
      Wserver.printf "<input type=\"hidden\" name=\"digest\" value=\"%s\"%s>\n"
        digest conf.xhs;
      Wserver.printf "%s%s\n" (capitale (transl conf "file")) (Util.transl conf ":");
      Wserver.printf "<input \
        type=\"file\" class=\"form-control\" name=\"file\" size=\"50\" \
        maxlength=\"250\" accept=\"image/*\"%s>\n" conf.xhs;
      Wserver.printf "</p>\n";
      Wserver.printf
        "<button type=\"submit\" class=\"btn btn-secondary btn-lg mt-2\">\n";
      Wserver.printf "%s" (capitale (transl_nth conf "validate/delete" 1));
      Wserver.printf "</button>\n";
      Wserver.printf
        "<input type=\"checkbox\" class=\"form-check-input btn-lg ml-2 mt-4\" \
        name=\"keydir\" id=\"keydir\">\n";
      Wserver.printf "<span class=\"text-nowrap ml-4\" >%s</span>"
        (capitale (transl_nth conf "from keydir" 0));
      Wserver.printf "</form>\n";
    end

(*      Wserver.printf "<p>\n";
      begin
        Wserver.printf "<a href=\"%sm=DEL_IMAGE&i=%d%s&file=%s\"%s>" (commd conf)
          (Adef.int_of_iper (get_key_index p))
          (if kind = KeyDir then "&keydir=on" else "") fname conf.xhs;
        Wserver.printf "%s %s" (capitale (transl conf "delete"))
          (transl_nth conf "image/images" 0);
        Wserver.printf "</a>"
      end;
      Wserver.printf "</p>\n"
*)

(* Send image form *)

let print_send_image conf base p kind =
  let title h =
    if kind = KeyImage then
      if Util.has_image conf base p then
        Wserver.printf "%s"
          (capitale
             (transl_decline conf "modify" (transl_nth conf "image/images" 0)))
      else
        Wserver.printf "%s"
          (capitale
             (transl_decline conf "add" (transl_nth conf "image/images" 0)))
    else
      if Util.has_keydir conf base p then
        Wserver.printf "%s"
          (capitale
             (transl_decline conf "add" (transl_nth conf "to keydir" 0)))
      else ();
    if h then ()
    else
      let fn = p_first_name base p in
      let sn = p_surname base p in
      Wserver.printf ": ";
      Wserver.printf "%s %s" fn sn;
      Util.print_reference conf fn (get_occ p) sn
  in
  let digest = Update.digest_person (UpdateInd.string_person_of base p) in
  Perso.interp_notempl_with_menu title "perso_header" conf base p;
  Wserver.printf "<h2>\n";
  title false;
  Wserver.printf "</h2>\n";
  Wserver.printf
    "<form method=\"post\" action=\"%s\" enctype=\"multipart/form-data\">\n"
    conf.command;
  Wserver.printf "<p>\n";
  Util.hidden_env conf;
  Wserver.printf
    "<input type=\"hidden\" name=\"m\" value=\"SND_IMAGE_OK\"%s>\n" conf.xhs;
  Wserver.printf "<input type=\"hidden\" name=\"i\" value=\"%d\"%s>\n"
    (Adef.int_of_iper (get_key_index p)) conf.xhs;
  Wserver.printf "<input type=\"hidden\" name=\"digest\" value=\"%s\"%s>\n"
    digest conf.xhs;
  Wserver.printf "%s%s\n" (capitale (transl conf "file")) (Util.transl conf ":");
  Wserver.printf "<input \
    type=\"file\" class=\"form-control\" name=\"file\" size=\"50\" maxlength=\"250\" accept=\"image/*\"%s>\n"
    conf.xhs;
  Wserver.printf "</p>\n";
  begin match p_getint conf.base_env "max_images_size" with
    Some len ->
      Wserver.printf "<p>\n";
      Wserver.printf "(maximum authorized size = %d bytes)\n" len;
      Wserver.printf "</p>\n"
  | None -> ()
  end;
  Wserver.printf
    "<button type=\"submit\" class=\"btn btn-secondary btn-lg mt-2\">\n";
  Wserver.printf "%s" (capitale (transl_nth conf "validate/delete" 0));
  Wserver.printf "</button>\n";
  Wserver.printf
    "<input type=\"checkbox\" class=\"form-check-input btn-lg ml-2 mt-4\" name=\"keydir\" id=\"keydir\">\n";
  Wserver.printf "<span class=\"text-nowrap ml-4\" >%s</span>" (capitale (transl_nth conf "send to keydir" 0));
  Wserver.printf "</form>\n";
  Wserver.printf "<p><hr><p>\n";
  let _ = Printf.eprintf "End print_send_image 1\n" in
  let _ = flush stderr in
  print_link_delete_image conf base digest p;
  let _ = Printf.eprintf "End print_send_image 2\n" in
  let _ = flush stderr in
  Hutil.trailer conf

let print conf base =
  let _ = Printf.eprintf "Print\n" in
  let _ =  List.iter
    (fun (k, v) ->
       Printf.eprintf "Env_var: %s, %s\n" k v)
    conf.env
  in
  let _ = flush stderr in
  let kind = try List.assoc "keydir" conf.env with Not_found -> "" in
  let kind = if kind = "on" then KeyDir else KeyImage in
  match p_getint conf.env "i" with
    Some ip ->
      let p = poi base (Adef.iper_of_int ip) in
      let fn = p_first_name base p in
      let sn = p_surname base p in
      if sou base (get_image p) <> "" || fn = "?" || sn = "?" then
        Hutil.incorrect_request conf
      else print_send_image conf base p kind
  | _ -> Hutil.incorrect_request conf

(* Delete image form *)

let print_delete_image conf base p =
  let keydir = default_image_name base p in
  let fname = try List.assoc "file_name" conf.env with Not_found -> "" in
  let fname = if fname = "" then keydir else fname in
  let kind = try List.assoc "keydir" conf.env with Not_found -> "" in
  let kind = if kind = "on" then KeyDir else KeyImage in
  let ffname = if kind = KeyDir then Filename.concat keydir fname else fname in

  let title h =
    Wserver.printf "%s%s%s"
      (capitale
         (transl_decline conf "delete" (transl_nth conf "image/images" 0)))
         (transl conf ":") ffname;
    if h then ()
    else ()
  in

  Hutil.header conf title;
  Wserver.printf "\n";
  Wserver.printf "<form method=\"post\" action=\"%s\"%s>\n"
    conf.command  conf.xhs;
  html_p conf;
  Util.hidden_env conf;
  Wserver.printf
    "<input type=\"hidden\" name=\"m\" value=\"DEL_IMAGE_OK\"%s>\n" conf.xhs;
  Wserver.printf
    "<input type=\"hidden\" name=\"file\" value=\"%s\"%s>\n"
      fname conf.xhs;
  Wserver.printf
    "<input type=\"hidden\" name=\"keydir\" value=\"%s\"%s>\n"
      (if kind = KeyDir then "on" else "") conf.xhs;
  Wserver.printf "<input type=\"hidden\" name=\"i\" value=\"%d\"%s>\n\n"
      (Adef.int_of_iper (get_key_index p)) conf.xhs;
  Wserver.printf "\n";
  html_p conf;
  Wserver.printf
    "<button type=\"submit\" class=\"btn btn-secondary btn-lg\"%s>\n" conf.xhs;
  Wserver.printf "%s" (capitale (transl_nth conf "validate/delete" 0));
  Wserver.printf "</button>\n";
  Wserver.printf "</form>\n";
  Wserver.printf "\n";
  Hutil.trailer conf

let print_del conf base =
  let _ = Printf.eprintf "Print_del\n" in
  let _ =  List.iter
    (fun (k, v) ->
       if k <> "file" then Printf.eprintf "Env_var: %s, %s\n" k v)
    conf.env
  in
  let _ = flush stderr in
  match p_getint conf.env "i" with
    Some ip ->
      let p = poi base (Adef.iper_of_int ip) in
      if sou base (get_image p) <> "" then Hutil.incorrect_request conf
      else
        begin match auto_image_file conf base p with
          Some _ -> print_delete_image conf base p
        | _ -> Hutil.incorrect_request conf
        end
  | _ -> Hutil.incorrect_request conf

(* Send image form validated *)

let print_sent conf base p =
  let title _ =
    Wserver.printf "%s" (capitale (transl conf "image received"))
  in
  Hutil.header conf title;
  Wserver.printf "<ul>\n";
  Wserver.printf "<li>";
  Wserver.printf "%s" (referenced_person_text conf base p);
  Wserver.printf "</li>";
  Wserver.printf "</ul>\n";
  Hutil.trailer conf

let write_file fname content =
  let oc = Secure.open_out_bin fname in
  output_string oc content; flush oc; close_out oc

(* Move fname to old_dir if it exists with some extension.
   Returns the number of moved files *)
let move_file_to_old conf fname bfname =
  List.fold_left
    (fun cnt typ ->
       let ext = extension_of_type typ in
       let new_file = fname ^ ext in
       if Sys.file_exists new_file then
         let old_dir = List.fold_right
           Filename.concat [Util.base_path conf.bname; "documents"; "portraits"] "old"
         in
         let old_file = Filename.concat old_dir bfname ^ ext in
         if Sys.file_exists old_file then
           (try Sys.remove old_file with Sys_error _ -> ());
         (try Unix.mkdir old_dir 0o777 with Unix.Unix_error (_, _, _) -> ());
         begin try Unix.rename new_file old_file with
           Unix.Unix_error (_, _, _) -> ()
         end;
         cnt + 1
       else cnt)
    0 image_types

let normal_image_type s =
  if String.length s > 10 && Char.code s.[0] = 0xff && Char.code s.[1] = 0xd8
  then
    Some JPEG
  else if String.length s > 4 && String.sub s 0 4 = "\137PNG" then Some PNG
  else if String.length s > 4 && String.sub s 0 4 = "GIF8" then Some GIF
  else None

let string_search s v =
  let rec loop i j =
    if j = String.length v then Some (i - String.length v)
    else if i = String.length s then None
    else if s.[i] = v.[j] then loop (i + 1) (j + 1)
    else loop (i + 1) 0
  in
  loop 0 0

(* get the image type, possibly removing spurious header *)

let image_type s =
  match normal_image_type s with
    Some t -> Some (t, s)
  | None ->
      match string_search s "JFIF" with
        Some i when i > 6 ->
          let s = String.sub s (i - 6) (String.length s - i + 6) in
          Some (JPEG, s)
      | _ ->
          match string_search s "\137PNG" with
            Some i ->
              let s = String.sub s i (String.length s - i) in Some (PNG, s)
          | _ ->
              match string_search s "GIF8" with
                Some i ->
                  let s = String.sub s i (String.length s - i) in
                  Some (GIF, s)
              | None -> None

let dump_bad_image conf s =
  match p_getenv conf.base_env "dump_bad_images" with
    Some "yes" ->
      begin try
        let oc = Secure.open_out_bin "bad-image" in
        output_string oc s; flush oc; close_out oc
      with Sys_error _ -> ()
      end
  | _ -> ()

let effective_send_ok conf base p file kind =
  let _ = Printf.eprintf "Effective_send_ok\n" in
  let _ =  List.iter
    (fun (k, v) ->
       Printf.eprintf "Env_var: %s, %s\n" k v)
    conf.env
  in
  let _ = flush stderr in
  let filename = raw_get conf ("file_name") in
  let strm = Stream.of_string file in
  let (request, content) = Wserver.get_request_and_content strm in
  let content =
    let s =
      let rec loop len (strm__ : _ Stream.t) =
        match Stream.peek strm__ with
          Some x -> Stream.junk strm__; loop (Buff.store len x) strm
        | _ -> Buff.get len
      in
      loop 0 strm
    in
    content ^ s
  in
  let (typ, content) =
    match image_type content with
      None ->
        let ct = Wserver.extract_param "content-type: " '\n' request in
        dump_bad_image conf content; incorrect_content_type conf base p ct
    | Some (typ, content) ->
        match p_getint conf.base_env "max_images_size" with
          Some len when String.length content > len ->
            error_too_big_image conf base p (String.length content) len
        | _ -> typ, content
  in
  let keyname = default_image_name base p in
  let bfname = if kind = KeyImage then keyname
    else Filename.remove_extension filename
  in
  let bfdir = List.fold_right
      Filename.concat [Util.base_path conf.bname; "documents"] "portraits"
  in
  let bfdir =
    if Sys.file_exists bfdir then bfdir
    else
      let d = Filename.concat (Util.base_path conf.bname) "documents" in
      let d1 = Filename.concat d conf.bname in
      (try Unix.mkdir d 0o777 with Unix.Unix_error (_, _, _) -> ());
      (try Unix.mkdir d1 0o777 with Unix.Unix_error (_, _, _) -> ());
      d1
  in
  let bfkdir = Filename.concat bfdir keyname in
  let bfdir =
    if kind = KeyDir && Sys.file_exists bfkdir then bfkdir
    else
      let d1 = bfkdir in
      (try Unix.mkdir d1 0o777 with Unix.Unix_error (_, _, _) -> ());
      d1
  in
  let fname = Filename.concat bfdir bfname in
  let _moved = move_file_to_old conf fname bfname in
  write_file (fname ^ extension_of_type typ) content;
  let changed =
    U_Send_image (Util.string_gen_person base (gen_person_of_person p))
  in
  History.record conf base changed
    (if kind = KeyImage then "si" else "ki"); print_sent conf base p

let print_send_ok conf base =
  try
    let ip =
      let s = raw_get conf "i" in
      try int_of_string s with Failure _ -> incorrect conf
    in
    let kind = raw_get conf "keydir" in
    let kind = if kind = "on" then KeyDir else KeyImage in
    let p = poi base (Adef.iper_of_int ip) in
    let digest = Update.digest_person (UpdateInd.string_person_of base p) in
    if digest = raw_get conf "digest" then
      let file = raw_get conf "file" in effective_send_ok conf base p file kind
    else Update.error_digest conf
  with Update.ModErr -> ()

(* Delete image form validated *)

let print_deleted conf base p =
  let title _ =
    Wserver.printf "%s" (capitale (transl conf "image deleted"))
  in
  Hutil.header conf title;
  Wserver.printf "<ul>\n";
  html_li conf;
  Wserver.printf "\n%s" (referenced_person_text conf base p);
  Wserver.printf "\n";
  Wserver.printf "</ul>\n";
  Hutil.trailer conf

let effective_delete_ok conf base p =
  let _ =  List.iter
    (fun (k, v) ->
       Printf.eprintf "Env_var: %s, %s\n" k v)
    conf.env
  in
  let _ = flush stderr in
  let name = try List.assoc "file" conf.env with Not_found -> "" in
  let kind = try List.assoc "keydir" conf.env with Not_found -> "" in
  let kind = if kind = "on" then KeyDir else KeyImage in
  let _ = Printf.eprintf "\nEffective_delete, name: %s\n" name in

  let keydir = default_image_name base p in
  let bfname = if kind = KeyDir then Filename.concat keydir name else name in
  let fname = List.fold_right
    Filename.concat [Util.base_path conf.bname; "documents"; "portraits"] bfname in
  let _ = Printf.eprintf "Effective_delete (mid 1) %s\n" fname in
  if kind = KeyImage && move_file_to_old conf fname bfname = 0 then incorrect conf
  else Sys.remove fname;
  let _ = Printf.eprintf "Effective_delete (mid 2)\n" in
  let _ = flush stderr in
  let changed =
    U_Delete_image (Util.string_gen_person base (gen_person_of_person p))
  in
  History.record conf base changed
    (if kind = KeyImage then "di" else "dk"); print_deleted conf base p;
  Printf.eprintf "Effective_delete (end)\n";
  flush stderr

let print_del_ok conf base =
  let _ = Printf.eprintf "Print_del_ok\n" in
  let _ =  List.iter
    (fun (k, v) ->
       Printf.eprintf "Env_var: %s, %s\n" k v)
    conf.env
  in
  let _ = flush stderr in
  (*let fname = Util.p_getenv env "name" in*)
  try
    match p_getint conf.env "i" with
      Some ip ->
        let p = poi base (Adef.iper_of_int ip) in
        effective_delete_ok conf base p
    | None -> incorrect conf
  with Update.ModErr -> ()
