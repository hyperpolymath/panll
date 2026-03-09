// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Json.res — Elm-style JSON decoders for type-safe data parsing.
//
// Usage:
//   let userDecoder = Tea_Json.map2(
//     (name, age) => {name, age},
//     Tea_Json.field("name", Tea_Json.string),
//     Tea_Json.field("age", Tea_Json.int),
//   )

/// Decoder error with path context
type rec error =
  | Field(string, error)
  | Index(int, error)
  | OneOf(array<error>)
  | Failure(string, JSON.t)

/// A decoder that transforms JSON.t into a result
type decoder<'a> = JSON.t => result<'a, error>

// Primitive decoders

let string: decoder<string> = json => {
  switch json {
  | String(s) => Ok(s)
  | _ => Error(Failure("Expected a string", json))
  }
}

let int: decoder<int> = json => {
  switch json {
  | Number(n) =>
    let i = Float.toInt(n)
    if Int.toFloat(i) === n {
      Ok(i)
    } else {
      Error(Failure("Expected an integer", json))
    }
  | _ => Error(Failure("Expected an integer", json))
  }
}

let float: decoder<float> = json => {
  switch json {
  | Number(n) => Ok(n)
  | _ => Error(Failure("Expected a number", json))
  }
}

let bool: decoder<bool> = json => {
  switch json {
  | Boolean(b) => Ok(b)
  | _ => Error(Failure("Expected a boolean", json))
  }
}

let null = (default: 'a): decoder<'a> => {
  json => {
    switch json {
    | Null => Ok(default)
    | _ => Error(Failure("Expected null", json))
    }
  }
}

// Object decoders

let field = (name: string, decoder: decoder<'a>): decoder<'a> => {
  json => {
    switch json {
    | Object(dict) =>
      switch Dict.get(dict, name) {
      | Some(value) =>
        switch decoder(value) {
        | Ok(v) => Ok(v)
        | Error(e) => Error(Field(name, e))
        }
      | None => Error(Field(name, Failure(`Field "${name}" not found`, json)))
      }
    | _ => Error(Failure("Expected an object", json))
    }
  }
}

let optionalField = (name: string, decoder: decoder<'a>): decoder<option<'a>> => {
  json => {
    switch json {
    | Object(dict) =>
      switch Dict.get(dict, name) {
      | Some(value) =>
        switch value {
        | Null => Ok(None)
        | _ =>
          switch decoder(value) {
          | Ok(v) => Ok(Some(v))
          | Error(e) => Error(Field(name, e))
          }
        }
      | None => Ok(None)
      }
    | _ => Error(Failure("Expected an object", json))
    }
  }
}

let at = (path: array<string>, decoder: decoder<'a>): decoder<'a> => {
  json => {
    let current = ref(json)
    let error = ref(None)
    Array.forEach(path, key => {
      if Option.isNone(error.contents) {
        switch current.contents {
        | Object(dict) =>
          switch Dict.get(dict, key) {
          | Some(v) => current := v
          | None => error := Some(Field(key, Failure(`Field "${key}" not found`, current.contents)))
          }
        | _ => error := Some(Failure("Expected an object", current.contents))
        }
      }
    })
    switch error.contents {
    | Some(e) => Error(e)
    | None => decoder(current.contents)
    }
  }
}

// Array decoders

let array = (decoder: decoder<'a>): decoder<array<'a>> => {
  json => {
    switch json {
    | Array(arr) => {
        let results: array<result<'a, error>> = Array.mapWithIndex(arr, (item, i) => {
          switch decoder(item) {
          | Ok(v) => Ok(v)
          | Error(e) => Error(Index(i, e))
          }
        })
        let firstError = Array.find(results, r => Result.isError(r))
        switch firstError {
        | Some(Error(e)) => Error(e)
        | _ => Ok(Array.filterMap(results, r => {
            switch r {
            | Ok(v) => Some(v)
            | Error(_) => None
            }
          }))
        }
      }
    | _ => Error(Failure("Expected an array", json))
    }
  }
}

let index = (i: int, decoder: decoder<'a>): decoder<'a> => {
  json => {
    switch json {
    | Array(arr) =>
      switch Array.get(arr, i) {
      | Some(value) =>
        switch decoder(value) {
        | Ok(v) => Ok(v)
        | Error(e) => Error(Index(i, e))
        }
      | None => Error(Index(i, Failure(`Index ${Int.toString(i)} out of bounds`, json)))
      }
    | _ => Error(Failure("Expected an array", json))
    }
  }
}

// Combinators

let map = (decoder: decoder<'a>, f: 'a => 'b): decoder<'b> => {
  json => {
    switch decoder(json) {
    | Ok(v) => Ok(f(v))
    | Error(e) => Error(e)
    }
  }
}

let map2 = (f: ('a, 'b) => 'c, d1: decoder<'a>, d2: decoder<'b>): decoder<'c> => {
  json => {
    switch (d1(json), d2(json)) {
    | (Ok(a), Ok(b)) => Ok(f(a, b))
    | (Error(e), _) => Error(e)
    | (_, Error(e)) => Error(e)
    }
  }
}

let map3 = (
  f: ('a, 'b, 'c) => 'd,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
): decoder<'d> => {
  json => {
    switch (d1(json), d2(json), d3(json)) {
    | (Ok(a), Ok(b), Ok(c)) => Ok(f(a, b, c))
    | (Error(e), _, _) => Error(e)
    | (_, Error(e), _) => Error(e)
    | (_, _, Error(e)) => Error(e)
    }
  }
}

let map4 = (
  f: ('a, 'b, 'c, 'd) => 'e,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
): decoder<'e> => {
  json => {
    switch (d1(json), d2(json), d3(json), d4(json)) {
    | (Ok(a), Ok(b), Ok(c), Ok(d)) => Ok(f(a, b, c, d))
    | (Error(e), _, _, _) => Error(e)
    | (_, Error(e), _, _) => Error(e)
    | (_, _, Error(e), _) => Error(e)
    | (_, _, _, Error(e)) => Error(e)
    }
  }
}

let map5 = (
  f: ('a, 'b, 'c, 'd, 'e) => 'f,
  d1: decoder<'a>,
  d2: decoder<'b>,
  d3: decoder<'c>,
  d4: decoder<'d>,
  d5: decoder<'e>,
): decoder<'f> => {
  json => {
    switch (d1(json), d2(json), d3(json), d4(json), d5(json)) {
    | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e)) => Ok(f(a, b, c, d, e))
    | (Error(e), _, _, _, _) => Error(e)
    | (_, Error(e), _, _, _) => Error(e)
    | (_, _, Error(e), _, _) => Error(e)
    | (_, _, _, Error(e), _) => Error(e)
    | (_, _, _, _, Error(e)) => Error(e)
    }
  }
}

let andThen = (decoder: decoder<'a>, f: 'a => decoder<'b>): decoder<'b> => {
  json => {
    switch decoder(json) {
    | Ok(a) => f(a)(json)
    | Error(e) => Error(e)
    }
  }
}

let oneOf = (decoders: array<decoder<'a>>): decoder<'a> => {
  json => {
    let errors = ref([])
    let result = ref(None)
    Array.forEach(decoders, decoder => {
      if Option.isNone(result.contents) {
        switch decoder(json) {
        | Ok(v) => result := Some(Ok(v))
        | Error(e) => errors := Array.concat(errors.contents, [e])
        }
      }
    })
    switch result.contents {
    | Some(r) => r
    | None => Error(OneOf(errors.contents))
    }
  }
}

let optional = (decoder: decoder<'a>): decoder<option<'a>> => {
  json => {
    switch decoder(json) {
    | Ok(v) => Ok(Some(v))
    | Error(_) => Ok(None)
    }
  }
}

let nullable = (decoder: decoder<'a>): decoder<option<'a>> => {
  json => {
    switch json {
    | Null => Ok(None)
    | _ =>
      switch decoder(json) {
      | Ok(v) => Ok(Some(v))
      | Error(e) => Error(e)
      }
    }
  }
}

let succeed = (value: 'a): decoder<'a> => {
  _json => Ok(value)
}

let fail = (message: string): decoder<'a> => {
  json => Error(Failure(message, json))
}

let value: decoder<JSON.t> = json => Ok(json)

// Decoding from string

let decodeString = (decoder: decoder<'a>, jsonString: string): result<'a, error> => {
  switch JSON.parseExn(jsonString) {
  | exception _ => Error(Failure("Invalid JSON", JSON.Encode.null))
  | json => decoder(json)
  }
}

// Error formatting

let rec errorToString = (error: error): string => {
  errorToStringHelp(error, [])
}

and errorToStringHelp = (error: error, context: array<string>): string => {
  switch error {
  | Failure(msg, _json) =>
    let path = Array.length(context) > 0
      ? Array.join(context, ".") ++ ": "
      : ""
    path ++ msg
  | Field(name, inner) =>
    errorToStringHelp(inner, Array.concat(context, [name]))
  | Index(i, inner) =>
    errorToStringHelp(inner, Array.concat(context, [`[${Int.toString(i)}]`]))
  | OneOf(errors) =>
    let details = Array.map(errors, e => errorToStringHelp(e, context))
    `None of the decoders matched: ${Array.join(details, "; ")}`
  }
}

/// Create a decoder function suitable for Tea_Http.expectJson
let toHttpDecoder = (decoder: decoder<'a>): (string => result<'a, string>) => {
  jsonString => {
    switch decodeString(decoder, jsonString) {
    | Ok(v) => Ok(v)
    | Error(e) => Error(errorToString(e))
    }
  }
}

/// Decode a JSON object as a Dict
let dict = (valueDecoder: decoder<'a>): decoder<Dict.t<'a>> => {
  json => {
    switch json {
    | Object(d) => {
        let result = Dict.make()
        let error = ref(None)
        Dict.forEachWithKey(d, (val, key) => {
          if Option.isNone(error.contents) {
            switch valueDecoder(val) {
            | Ok(v) => Dict.set(result, key, v)
            | Error(e) => error := Some(Field(key, e))
            }
          }
        })
        switch error.contents {
        | Some(e) => Error(e)
        | None => Ok(result)
        }
      }
    | _ => Error(Failure("Expected an object", json))
    }
  }
}
