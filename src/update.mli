(* $Id: update.mli,v 2.2 1999-03-17 14:11:26 ddr Exp $ *)
(* Copyright (c) 1999 INRIA *)

open Def;
open Config;

exception ModErr;

value find_free_occ : base -> string -> string -> int -> int;
value death_supposition : config -> option date -> death;
value print_same_name : config -> base -> base_person -> unit;

value insert_string : config -> base -> string -> Adef.istr;
value update_misc_names_of_family : base -> base_person -> unit;

value print_error : config -> base -> Gutil.base_error -> unit;
value print_warnings : config -> base -> list Gutil.base_warning -> unit;
value error : config -> base -> Gutil.base_error -> 'a;

value error_locked : config -> base -> unit;
value error_digest : config -> base -> 'a;

value digest_person : base_person -> Digest.t;
value digest_family : base_family -> Digest.t;

value reconstitute_date : config -> string -> option date;
value print_date :
  config -> base -> string -> string -> option date -> unit;

value print_src : config -> string -> string -> unit;

value print_someone : config -> base -> base_person -> unit;

value print : config -> base -> base_person -> unit;
