(* $Id: ansel.ml,v 4.0 2001-03-16 19:34:24 ddr Exp $ *)
(* Copyright (c) 2001 INRIA *)

value no_accent =
  fun
  [ '�' | '�' | '�' | '�' | '�' | '�' -> 'a'
  | '�' -> 'c'
  | '�' | '�' | '�' | '�' -> 'e'
  | '�' | '�' | '�' | '�' -> 'i'
  | '�' -> 'n'
  | '�' | '�' | '�' | '�' | '�' | '�' -> 'o'
  | '�' | '�' | '�' | '�' -> 'u'
  | '�' | '�' -> 'y'
  | '�' | '�' | '�' | '�' | '�' | '�' -> 'A'
  | '�' -> 'C'
  | '�' | '�' | '�' | '�' -> 'E'
  | '�' | '�' | '�' | '�' -> 'I'
  | '�' -> 'N'
  | '�' | '�' | '�' | '�' | '�' | '�' -> 'O'
  | '�' | '�' | '�' | '�' -> 'U'
  | '�' -> 'Y'
  | c -> c ]
;

value of_iso_8859_1 s =
  let len =
    loop 0 0 where rec loop i len =
      if i == String.length s then len
      else
        match s.[i] with
        [ '�'..'�' | '�'.. '�' | '�'..'�' | '�'..'�'
        | '�'..'�' | '�'.. '�' | '�'..'�' | '�'..'�' | '�' ->
            loop (i + 1) (len + 2)
        | _ -> loop (i + 1) (len + 1) ]
  in
  if len == String.length s then s
  else
    let s' = String.create len in
    loop 0 0 where rec loop i i' =
      if i == String.length s then s'
      else
        let i' =
          match s.[i] with
          [ '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' ->
              do s'.[i'] := Char.chr 225; s'.[i'+1] := no_accent s.[i];
              return i' + 1
          | '�' | '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' | '�' ->
              do s'.[i'] := Char.chr 226; s'.[i'+1] := no_accent s.[i];
              return i' + 1
          | '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' ->
              do s'.[i'] := Char.chr 227; s'.[i'+1] := no_accent s.[i];
              return i' + 1
          | '�' | '�' | '�' | '�' | '�' | '�' ->
              do s'.[i'] := Char.chr 228; s'.[i'+1] := no_accent s.[i];
              return i' + 1
          | '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' | '�' ->
              do s'.[i'] := Char.chr 232; s'.[i'+1] := no_accent s.[i];
              return i' + 1
          | '�' | '�' ->
              do s'.[i'] := Char.chr 234; s'.[i'+1] := no_accent s.[i];
              return i' + 1
          | '�' | '�' ->
              do s'.[i'] := Char.chr 240; s'.[i'+1] := no_accent s.[i];
              return i' + 1
          | c -> do s'.[i'] := c; return i' ]
        in
        loop (i + 1) (i' + 1)
;

value grave =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | x -> x ]
;

value acute =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'y' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | 'Y' -> '�'
  | x -> x ]
;

value circum =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | x -> x ]
;

value uml =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'y' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | x -> x ]
;

value circle =
  fun
  [ 'a' -> '�'
  | 'A' -> '�'
  | x -> x ]
;

value tilde =
  fun
  [ 'a' -> '�'
  | 'n' -> '�'
  | 'o' -> '�'
  | 'A' -> '�'
  | 'N' -> '�'
  | 'O' -> '�'
  | x -> x ]
;

value cedil =
  fun
  [ 'c' -> '�'
  | 'C' -> '�'
  | x -> x ]
;

value to_iso_8859_1 s =
  let len =
    loop 0 0 where rec loop i len =
      if i == String.length s then len
      else if i == String.length s - 1 then len + 1
      else
        match Char.code s.[i] with
        [ 225 | 226 | 227 | 228 | 232 | 234 | 240 -> loop (i + 1) len
        | _ -> loop (i + 1) (len + 1) ]
  in
  if len == String.length s then s
  else
    let s' = String.create len in
    loop 0 0 where rec loop i i' =
      if i == String.length s then s'
      else if i == String.length s - 1 then
        do s'.[i'] := s.[i]; return s'
      else
        let i =
          match Char.code s.[i] with
          [ 225 -> do s'.[i'] := grave s.[i+1]; return i + 1
          | 226 -> do s'.[i'] := acute s.[i+1]; return i + 1
          | 227 -> do s'.[i'] := circum s.[i+1]; return i + 1
          | 228 -> do s'.[i'] := tilde s.[i+1]; return i + 1
          | 232 -> do s'.[i'] := uml s.[i+1]; return i + 1
          | 234 -> do s'.[i'] := circle s.[i+1]; return i + 1
          | 240 -> do s'.[i'] := cedil s.[i+1]; return i + 1
          | _ -> do s'.[i'] := s.[i]; return i ]
        in
        loop (i + 1) (i' + 1)
;
