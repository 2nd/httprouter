# An http router for use with the nhttp server

Allows for the attaching of handlers to routes.

# test

Typing `make t` in the console will run a test suite.

# usage

To initialize, call initRouter:

```nim
import router, nhttp


proc getUsersShowHandler(req: nhttp.Request, res: nhttp.Response) =
  res.write(200, "hello " & req.params["name"])

var server = nhttp.Server(reuse: true, readTimeout: 10000)
setControlCHook(proc() {.noconv.} = server.shutdown())

var router = initRouter(server)
router.add("GET", "users/:name", getUsersShowHandler)

server.listen(3003)
```

The first parameter is the method (GET, POST, DELETE, etc); the second is the
path, and the third is the handler to be invoked when the route is hit later on.
Handlers take an `nhttp.Request` and `nttp.Response` object.

Let's say that the route contained within the request was `GET /users/show`,
i.e. that the router has a route and a handler for this request. The router
will now call `getUsersShowHandler` on the request and response objects.

## errors

`initServer` can be passed a special `notFound` and/or `error` handler:

```
proc notFoundHandler(req: nhttp.Request, res: nhttp.Response) =
  # todo, handle requests with no matching router
  res.write(404, "not found")

proc errorHandler(req: nhttp.Request, res: nhttp.Response) =
  # todo, handle an uncaught exception
  res.write(500, "internal server error")

var r = initRouter(server, notFound = notFoundHandler, error = errorHandler)
...
```

## parameters

The router supports parameters, i.e. `users/:id/posts`. Indicate a parameter in
your route by appending a colon to the front. When a route with parameters is
later handled by the router, the parameter values will be written to the
request object. For example, if `users/100/posts` is handled by the router,
the appropriate handler for `users/:id/posts` will be called, and `id: 100` will
be written to the request's param table.

The router does NOT support multiple routes of the same number of components but
with different parameter names. There is no way for `users/:id/posts` and `users/:name/posts`
to be differentiated, and correct behavior is not guaranteed. "users/:id/posts" and
`users/:name/posts/:id`, however, is acceptable.
