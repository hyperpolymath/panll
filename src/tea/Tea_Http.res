// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Http.res — Type-safe HTTP client for the TEA architecture.
//
// Usage:
//   let cmd = Tea_Http.get(
//     ~url="/api/data",
//     ~expect=Tea_Http.expectString(GotData),
//   )

/// HTTP error types
type error =
  | BadUrl(string)
  | Timeout
  | NetworkError
  | BadStatus(int, string)
  | BadBody(string)

/// HTTP header
type header = {name: string, value: string}

/// Create a header
let header = (name: string, value: string): header => {name, value}

/// Format an error to a human-readable string
let errorToString = (err: error): string => {
  switch err {
  | BadUrl(url) => `Bad URL: ${url}`
  | Timeout => "Request timed out"
  | NetworkError => "Network error"
  | BadStatus(status, body) =>
    `Bad status ${Int.toString(status)}: ${String.slice(body, ~start=0, ~end=200)}`
  | BadBody(reason) => `Bad body: ${reason}`
  }
}

// Internal: execute a fetch request and dispatch the result
let sendFetch = (
  ~method: string,
  ~url: string,
  ~headers: array<header>,
  ~body: option<string>,
  ~timeout: option<int>,
  ~onResponse: (int, string) => 'msg,
  ~onError: string => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let _url = url
    let _method = method
    let _headers = headers
    let _body = body
    let _timeout = timeout
    let _onResponse = onResponse
    let _onError = onError
    let _enqueue = callbacks.enqueue

    ignore(%raw(`
      (function() {
        var init = { method: _method, headers: {} };
        for (var i = 0; i < _headers.length; i++) {
          init.headers[_headers[i].name] = _headers[i].value;
        }
        if (_body !== undefined) init.body = _body;

        var controller = new AbortController();
        init.signal = controller.signal;

        var timeoutId;
        if (_timeout !== undefined) {
          timeoutId = setTimeout(function() {
            controller.abort();
            _enqueue(_onError("timeout"));
          }, _timeout);
        }

        fetch(_url, init)
          .then(function(response) {
            if (timeoutId) clearTimeout(timeoutId);
            return response.text().then(function(text) {
              _enqueue(_onResponse(response.status, text));
            });
          })
          .catch(function(err) {
            if (timeoutId) clearTimeout(timeoutId);
            if (err.name !== 'AbortError') {
              _enqueue(_onError("network"));
            }
          });
      })()
    `))
  })
}

/// Build a GET request expecting a string response
let getString = (
  ~url: string,
  ~headers: array<header>=[],
  ~timeout: option<int>=?,
  ~toMsg: result<string, error> => 'msg,
): Tea_Cmd.t<'msg> => {
  sendFetch(
    ~method="GET",
    ~url,
    ~headers,
    ~body=None,
    ~timeout,
    ~onResponse=(status, body) => {
      if status >= 200 && status < 300 {
        toMsg(Ok(body))
      } else {
        toMsg(Error(BadStatus(status, body)))
      }
    },
    ~onError=err => {
      toMsg(Error(err === "timeout" ? Timeout : NetworkError))
    },
  )
}

/// Build a GET request expecting a JSON response decoded by a function
let getJson = (
  ~url: string,
  ~headers: array<header>=[],
  ~timeout: option<int>=?,
  ~decoder: string => result<'a, string>,
  ~toMsg: result<'a, error> => 'msg,
): Tea_Cmd.t<'msg> => {
  sendFetch(
    ~method="GET",
    ~url,
    ~headers,
    ~body=None,
    ~timeout,
    ~onResponse=(status, body) => {
      if status >= 200 && status < 300 {
        switch decoder(body) {
        | Ok(value) => toMsg(Ok(value))
        | Error(reason) => toMsg(Error(BadBody(reason)))
        }
      } else {
        toMsg(Error(BadStatus(status, body)))
      }
    },
    ~onError=err => {
      toMsg(Error(err === "timeout" ? Timeout : NetworkError))
    },
  )
}

/// Build a POST request with a JSON body
let postJson = (
  ~url: string,
  ~headers: array<header>=[],
  ~body: string,
  ~timeout: option<int>=?,
  ~decoder: string => result<'a, string>,
  ~toMsg: result<'a, error> => 'msg,
): Tea_Cmd.t<'msg> => {
  sendFetch(
    ~method="POST",
    ~url,
    ~headers=Array.concat(headers, [{name: "Content-Type", value: "application/json"}]),
    ~body=Some(body),
    ~timeout,
    ~onResponse=(status, responseBody) => {
      if status >= 200 && status < 300 {
        switch decoder(responseBody) {
        | Ok(value) => toMsg(Ok(value))
        | Error(reason) => toMsg(Error(BadBody(reason)))
        }
      } else {
        toMsg(Error(BadStatus(status, responseBody)))
      }
    },
    ~onError=err => {
      toMsg(Error(err === "timeout" ? Timeout : NetworkError))
    },
  )
}

/// Build a PUT request
let putJson = (
  ~url: string,
  ~headers: array<header>=[],
  ~body: string,
  ~timeout: option<int>=?,
  ~decoder: string => result<'a, string>,
  ~toMsg: result<'a, error> => 'msg,
): Tea_Cmd.t<'msg> => {
  sendFetch(
    ~method="PUT",
    ~url,
    ~headers=Array.concat(headers, [{name: "Content-Type", value: "application/json"}]),
    ~body=Some(body),
    ~timeout,
    ~onResponse=(status, responseBody) => {
      if status >= 200 && status < 300 {
        switch decoder(responseBody) {
        | Ok(value) => toMsg(Ok(value))
        | Error(reason) => toMsg(Error(BadBody(reason)))
        }
      } else {
        toMsg(Error(BadStatus(status, responseBody)))
      }
    },
    ~onError=err => {
      toMsg(Error(err === "timeout" ? Timeout : NetworkError))
    },
  )
}

/// Build a DELETE request
let delete = (
  ~url: string,
  ~headers: array<header>=[],
  ~timeout: option<int>=?,
  ~toMsg: result<string, error> => 'msg,
): Tea_Cmd.t<'msg> => {
  sendFetch(
    ~method="DELETE",
    ~url,
    ~headers,
    ~body=None,
    ~timeout,
    ~onResponse=(status, body) => {
      if status >= 200 && status < 300 {
        toMsg(Ok(body))
      } else {
        toMsg(Error(BadStatus(status, body)))
      }
    },
    ~onError=err => {
      toMsg(Error(err === "timeout" ? Timeout : NetworkError))
    },
  )
}

/// Build a PATCH request
let patchJson = (
  ~url: string,
  ~headers: array<header>=[],
  ~body: string,
  ~timeout: option<int>=?,
  ~decoder: string => result<'a, string>,
  ~toMsg: result<'a, error> => 'msg,
): Tea_Cmd.t<'msg> => {
  sendFetch(
    ~method="PATCH",
    ~url,
    ~headers=Array.concat(headers, [{name: "Content-Type", value: "application/json"}]),
    ~body=Some(body),
    ~timeout,
    ~onResponse=(status, responseBody) => {
      if status >= 200 && status < 300 {
        switch decoder(responseBody) {
        | Ok(value) => toMsg(Ok(value))
        | Error(reason) => toMsg(Error(BadBody(reason)))
        }
      } else {
        toMsg(Error(BadStatus(status, responseBody)))
      }
    },
    ~onError=err => {
      toMsg(Error(err === "timeout" ? Timeout : NetworkError))
    },
  )
}
