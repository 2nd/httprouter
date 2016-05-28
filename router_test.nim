import router, nhttp, unittest, uri, tables, httpclient, strutils, strtabs, net

proc error(request: nhttp.Request, response: nhttp.Response) =
  request.body = "error"

proc handlerWithError(request: nhttp.Request, response: nhttp.Response) =
  var x = @[1, 2, 3]
  echo x[3]
  request.body = "handler with error failure"

proc notFound(request: nhttp.Request, response: nhttp.Response) =
  request.body = "not found"

proc rootGetHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "root get success"

proc getUsersParameterHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users parameter success"

proc getUsersHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users success"

proc getUsersPhotosHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users photos success"

proc getUsersUsersHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users users success"

proc getUsersCommentsHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users comments success"

proc postUsersCommentsHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "post users comments success"

var socket = new(net.Socket)
var response = newResponse(socket)

suite "router":

  test "adding and retrieving single route":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    var requestUri = uri.parseUri("http://example.com/users/comments")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "get users comments success")

  test "adding and retrieving two routes with same initial path component":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    testRouter.add("GET", "/users/photos", getUsersPhotosHandler)
    var requestUri = uri.parseUri("http://example.com/users/comments")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "get users comments success")
    requestUri = uri.parseUri("http://example.com/users/photos")
    request = nhttp.Request(uri: requestUri, m: "GET")
    testRouter.handle(request, response)
    check(request.body == "get users photos success")

  test "adding and retrieving two routes with same path and different method":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    testRouter.add("POST", "/users/comments", postUsersCommentsHandler)
    var requestUri = uri.parseUri("http://example.com/users/comments")
    var request = nhttp.Request(uri: requestUri, m: "POST")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "post users comments success")
    requestUri = uri.parseUri("http://example.com/users/comments")
    request = nhttp.Request(uri: requestUri, m: "GET")
    testRouter.handle(request, response)
    check(request.body == "get users comments success")

  test "adding and retrieving two routes with same path names on different levels":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/users", getUsersHandler)
    testRouter.add("GET", "/users/users", getUsersUsersHandler)
    var requestUri = uri.parseUri("http://example.com/users")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "get users success")
    requestUri = uri.parseUri("http://example.com/users/users")
    request = nhttp.Request(uri: requestUri, m: "GET")
    testRouter.handle(request, response)
    check(request.body == "get users users success")

  test "adding and retrieving root route":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/", rootGetHandler)
    var requestUri = uri.parseUri("http://example.com/")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "root get success")

  test "catching an error in handler and calling error handler":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/error", handlerWithError)
    var requestUri = uri.parseUri("http://example.com/error")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "error")

  test "adding and retrieving a route with a parameter":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/users/:id", getUsersParameterHandler)
    var requestUri = uri.parseUri("http://example.com/users/100")
    var request = nhttp.Request(uri: requestUri, m: "GET", parameters: strtabs.newStringTable(strtabs.modeCaseInsensitive))
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "get users parameter success")
    check(request.parameters[":id"] == "100")
    requestUri = uri.parseUri("http://example.com/users")
    request = nhttp.Request(uri: requestUri, m: "GET")
    testRouter.handle(request, response)
    check(request.body == "not found")

  test "retrieving not found if a route terminates on a node with no handler":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    var requestUri = uri.parseUri("http://example.com/users")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "not found")

  test "retrieving not found if a route is invalid":
    var testRouter = router.initRouter(notFound, error)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    var requestUri = uri.parseUri("http://example.com/users/commentss")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var socket = new(net.Socket)
    var response = newResponse(socket)
    testRouter.handle(request, response)
    check(request.body == "not found")
