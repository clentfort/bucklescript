# 9 "hashmap.cppo.ml"
type key = int
type seed = int
external caml_hash_mix_int : seed -> int -> seed  = "caml_hash_mix_int"
external final_mix : seed -> seed = "caml_hash_final_mix"
let hash (s : key) = 
  final_mix (caml_hash_mix_int 0 s)

# 19
(***********************************************************************)
(*                                                                     *)
(*                                OCaml                                *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)
(**  Adapted by Authors of BuckleScript 2017                           *)
module N = Bs_internalBuckets
module C = Bs_internalBucketsType
type ('a, 'b,'id) t0 = ('a,'b) N.t0 

type 'b t = (key,'b,unit) t0


let rec insert_bucket  ~h_buckets ~ndata_tail h old_bucket = 
  match C.toOpt old_bucket with 
  | None -> ()
  | Some cell ->
    let nidx = hash (N.key cell) land (Array.length h_buckets - 1) in 
    let v = C.return cell in 
    begin match C.toOpt (Bs_Array.unsafe_get ndata_tail nidx) with
      | None -> 
        Bs_Array.unsafe_set h_buckets nidx  v
      | Some tail ->
        N.nextSet tail v  (* cell put at the end *)            
    end;          
    Bs_Array.unsafe_set ndata_tail nidx  v;
    insert_bucket  ~h_buckets ~ndata_tail h (N.next cell)


let resize  h =
  let odata = C.buckets h in
  let osize = Array.length odata in
  let nsize = osize * 2 in
  if nsize >= osize then begin (* no overflow *)
    let h_buckets = C.makeSize nsize  in
    let ndata_tail = C.makeSize nsize  in (* keep track of tail *)
    C.bucketsSet h  h_buckets;          (* so that indexfun sees the new bucket count *)
    for i = 0 to osize - 1 do
      insert_bucket  ~h_buckets ~ndata_tail h (Bs_Array.unsafe_get odata i)
    done;
    for i = 0 to nsize - 1 do
      match C.toOpt (Bs_Array.unsafe_get ndata_tail i) with
      | None -> ()
      | Some tail -> N.nextSet tail C.emptyOpt
    done
  end


let add  h key value =
  let h_buckets = C.buckets h in  
  let h_buckets_lenth = Array.length h_buckets in 
  let i =  hash key land (h_buckets_lenth - 1) in 
  let bucket = 
    N.bucket ~key ~value ~next:(Bs_Array.unsafe_get h_buckets i) in  
  Bs_Array.unsafe_set h_buckets i  (C.return bucket);
  let h_new_size = C.size h + 1 in 
  C.sizeSet h  h_new_size;
  if h_new_size > h_buckets_lenth lsl 1 then resize  h


let rec remove_bucket h h_buckets  i (key : key) prec buckets =
  match C.toOpt buckets with
  | None -> ()
  | Some cell  ->
    let cell_next = N.next cell in 
    if  N.key cell = key 
    then 
      begin
        (match C.toOpt prec with
         | None -> Bs_Array.unsafe_set h_buckets i  cell_next
         | Some c -> N.nextSet c cell_next);
        C.sizeSet h (C.size h - 1);        
      end
    else remove_bucket  h h_buckets i key buckets cell_next

let remove  h key =  
  let h_buckets = C.buckets h in 
  let i = hash key land (Array.length h_buckets - 1) in  
  remove_bucket  h h_buckets i key C.emptyOpt (Bs_Array.unsafe_get h_buckets i)

let rec removeAllBuckets h h_buckets  i (key : key) prec buckets =
  match C.toOpt buckets with
  | None -> ()
  | Some cell ->
    let cell_next = N.next cell in 
    if  N.key cell = key
    then 
      begin
        (match C.toOpt prec with
         | None -> Bs_Array.unsafe_set h_buckets i  cell_next
         | Some c -> N.nextSet c cell_next);
        C.sizeSet h (C.size h - 1);        
      end;
    removeAllBuckets h h_buckets i key buckets cell_next

let removeAll  h key =
  let h_buckets = C.buckets h in 
  let i = hash key  land (Array.length h_buckets - 1) in  
  removeAllBuckets h h_buckets i key C.emptyOpt (Bs_Array.unsafe_get h_buckets i)


(* TODO: add [removeAll] *)


let rec find_rec  (key : key) buckets = 
  match C.toOpt buckets with 
  | None ->
    None
  | Some cell ->
    if key = (N.key cell)  then Some (N.value cell) 
    else find_rec key  (N.next cell)

let findOpt  h (key : key) =
  let h_buckets = C.buckets h in 
  let nid = hash key  land (Array.length h_buckets - 1) in 
  match C.toOpt @@ Bs_Array.unsafe_get h_buckets nid with
  | None -> None
  | Some cell1 ->
    if key = (N.key cell1)  then Some (N.value cell1) else
      match C.toOpt (N.next cell1) with
      | None -> None
      | Some cell2 ->
        if  key = (N.key cell2)  then Some (N.value cell2) else
          match C.toOpt (N.next cell2) with
          | None -> None
          | Some cell3 ->
            if  key = (N.key cell3)  then Some (N.value cell3)
            else find_rec  key (N.next cell3)


let findAll  h (key : key) =
  let rec find_in_bucket buckets = 
    match C.toOpt buckets with 
    | None ->
      []
    | Some cell -> 
      if  (N.key cell) = key 
      then (N.value cell) :: find_in_bucket (N.next cell)
      else find_in_bucket (N.next cell) in
  let h_buckets = C.buckets h in     
  let nid = hash key land (Array.length h_buckets - 1) in 
  find_in_bucket (Bs_Array.unsafe_get h_buckets nid)

let rec replace_bucket  (key : key) info buckets = 
  match C.toOpt buckets with 
  | None ->
    true
  | Some cell ->
    if  (N.key cell) = key 
    then
      begin
        N.keySet cell key;
        N.valueSet cell info;
        false
      end
    else
      replace_bucket key info (N.next cell)

let replace  h (key : key) info =
  let h_buckets = C.buckets h in 
  let i = hash key land (Array.length h_buckets - 1) in 
  let l = Array.unsafe_get h_buckets i in  
  if replace_bucket  key info l then begin
    Bs_Array.unsafe_set h_buckets i (C.return 
                                       (N.bucket ~key ~value:info ~next:l));
    C.sizeSet h (C.size h + 1);
    if C.size h > Array.length (C.buckets h) lsl 1 then resize  h
  end 

let rec mem_in_bucket (key : key) buckets = 
  match C.toOpt buckets with 
  | None ->
    false
  | Some cell ->
    (N.key cell)  = key  || mem_in_bucket  key (N.next cell)
let mem  h key =
  let h_buckets = C.buckets h in 
  let nid = hash key land (Array.length h_buckets - 1) in 
  mem_in_bucket  key (Bs_Array.unsafe_get h_buckets nid)


let create = C.create0
let clear = C.clear0
let reset = C.reset0
let length = C.length0
let iter = N.iter0
let fold = N.fold0
let logStats = N.logStats0
let filterMapInplace = N.filterMapInplace0

