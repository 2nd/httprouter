import router, nhttp, unittest, uri, tables, httpclient, strutils, strtabs, net

proc error(req: nhttp.Request, res: nhttp.Response) =
  req.body = "error"

proc handlerWithError(req: nhttp.Request, res: nhttp.Response) =
  var x = @[1, 2, 3]
  echo x[3]
  req.body = "handler with error failure"

proc notFound(req: nhttp.Request, res: nhttp.Response) =
  req.body = "not found"

proc rootGetHandler(req: nhttp.Request, res: nhttp.Response) =
  req.body = "root get success"

proc getUsersParameterHandler(req: nhttp.Request, res: nhttp.Response) =
  req.body = "get users parameter success"

proc getUsersHandler(req: nhttp.Request, res: nhttp.Response) =
  req.body = "get users success"

proc getUsersPhotosHandler(req: nhttp.Request, res: nhttp.Response) =
  req.body = "get users photos success"

proc getUsersUsersHandler(req: nhttp.Request, res: nhttp.Response) =
  req.body = "get users users success"

proc getUsersCommentsHandler(req: nhttp.Request, res: nhttp.Response) =
  req.body = "get users comments success"

proc postUsersCommentsHandler(req: nhttp.Request, res: nhttp.Response) =
  req.body = "post users comments success"

suite "router":

  var server = nhttp.Server()

  test "adding and retrieving single route":
    var testRouter = router.initRouter(server)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)

    let reqUri = uri.parseUri("http://secondspectrum.com/users/comments")
    let req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())

    check(req.body == "get users comments success")

  test "adding and retrieving two routes with same initial path component":
    var testRouter = router.initRouter(server)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    testRouter.add("GET", "/users/photos", getUsersPhotosHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users/comments")
    var req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())

    check(req.body == "get users comments success")
    reqUri = uri.parseUri("http://secondspectrum.com/users/photos")
    req = nhttp.Request(uri: reqUri, m: "GET")

    server.handler(req, nhttp.Response())
    check(req.body == "get users photos success")

  test "adding and retrieving two routes with same path and different method":
    var testRouter = router.initRouter(server)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    testRouter.add("POST", "/users/comments", postUsersCommentsHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users/comments")
    var req = nhttp.Request(uri: reqUri, m: "POST")
    server.handler(req, nhttp.Response())
    check(req.body == "post users comments success")

    reqUri = uri.parseUri("http://secondspectrum.com/users/comments")
    req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "get users comments success")

  test "adding and retrieving two routes with same path names on different levels":
    var testRouter = router.initRouter(server)
    testRouter.add("GET", "/users", getUsersHandler)
    testRouter.add("GET", "/users/users", getUsersUsersHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users")
    var req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "get users success")

    reqUri = uri.parseUri("http://secondspectrum.com/users/users")
    req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "get users users success")

  test "adding and retrieving root route":
    var testRouter = router.initRouter(server)
    testRouter.add("GET", "/", rootGetHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/")
    var req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "root get success")

  test "catching an error in handler and calling error handler":
    var testRouter = router.initRouter(server, error = error)
    testRouter.add("GET", "/error", handlerWithError)

    var reqUri = uri.parseUri("http://secondspectrum.com/error")
    var req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "error")

  test "adding and retrieving a route with a parameter":
    var testRouter = router.initRouter(server, notFound = notFound)
    testRouter.add("GET", "/users/:id", getUsersParameterHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users/100")
    var req = nhttp.Request(uri: reqUri, m: "GET", params: strtabs.newStringTable(strtabs.modeCaseInsensitive))
    server.handler(req, nhttp.Response())
    check(req.body == "get users parameter success")
    check(req.params[":id"] == "100")

    reqUri = uri.parseUri("http://secondspectrum.com/users")
    req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "not found")

  test "retrieving not found if a route terminates on a node with no handler":
    var testRouter = router.initRouter(server, notFound = notFound)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users")
    var req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "not found")

  test "retrieving not found if a route is invalid":
    var testRouter = router.initRouter(server, notFound = notFound)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users/commentss")
    var req = nhttp.Request(uri: reqUri, m: "GET")
    server.handler(req, nhttp.Response())
    check(req.body == "not found")

  test "adding and retrieving a route sz multiple parameters":
    var testRouter = router.initRouter(server)
    testRouter.add("GET", "/users/:id/:post", getUsersHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users/100/hey")
    var req = nhttp.Request(uri: reqUri, m: "GET", params: strtabs.newStringTable(strtabs.modeCaseInsensitive))
    server.handler(req, nhttp.Response())
    check(req.body == "get users success")
    check(req.params[":id"] == "100")
    check(req.params[":post"] == "hey")

  test "adding and retrieving a route with multiple parameters on same level":
    var testRouter = router.initRouter(server)
    testRouter.add("GET", "/users/:id/posts", getUsersHandler)
    testRouter.add("GET", "/users/:blah/posts/photos", getUsersPhotosHandler)

    var reqUri = uri.parseUri("http://secondspectrum.com/users/100/posts")
    var req = nhttp.Request(uri: reqUri, m: "GET", params: strtabs.newStringTable(strtabs.modeCaseInsensitive))
    server.handler(req, nhttp.Response())
    check(req.body == "get users success")
    check(req.params[":id"] == "100")

    reqUri = uri.parseUri("http://secondspectrum.com/users/100/posts/photos")
    req = nhttp.Request(uri: reqUri, m: "GET", params: strtabs.newStringTable(strtabs.modeCaseInsensitive))
    server.handler(req, nhttp.Response())
    check(req.body == "get users photos success")
    check(req.params[":blah"] == "100")
