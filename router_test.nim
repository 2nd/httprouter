import router, nhttp, unittest, uri, typetraits, tables

proc notFound(request: nhttp.Request, response: nhttp.Response) =
  request.body = "not found"

proc rootGetHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "root get success"

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

suite "router":

  test "adding and retrieving single route":
    var testRouter = router.initRouter(notFound)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    var requestUri = uri.parseUri("http://example.com/users/comments")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var response = nhttp.Response()
    testRouter.handle(request, response)
    check(request.body == "get users comments success")

  test "adding and retrieving two routes with same initial path component":
    var testRouter = router.initRouter(notFound)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    testRouter.add("GET", "/users/photos", getUsersPhotosHandler)
    var requestUri = uri.parseUri("http://example.com/users/comments")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var response = nhttp.Response()
    testRouter.handle(request, response)
    check(request.body == "get users comments success")
    requestUri = uri.parseUri("http://example.com/users/photos")
    request = nhttp.Request(uri: requestUri, m: "GET")
    testRouter.handle(request, response)
    check(request.body == "get users photos success")

  test "adding and retrieving two routes with same path and different method":
    var testRouter = router.initRouter(notFound)
    testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    testRouter.add("POST", "/users/comments", postUsersCommentsHandler)
    var requestUri = uri.parseUri("http://example.com/users/comments")
    var request = nhttp.Request(uri: requestUri, m: "POST")
    var response = nhttp.Response()
    testRouter.handle(request, response)
    check(request.body == "post users comments success")
    requestUri = uri.parseUri("http://example.com/users/comments")
    request = nhttp.Request(uri: requestUri, m: "GET")
    testRouter.handle(request, response)
    check(request.body == "get users comments success")

  test "adding and retrieving two routes with same path names on different levels":
    var testRouter = router.initRouter(notFound)
    testRouter.add("GET", "/users", getUsersHandler)
    testRouter.add("GET", "/users/users", getUsersUsersHandler)
    var requestUri = uri.parseUri("http://example.com/users")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var response = nhttp.Response()
    testRouter.handle(request, response)
    check(request.body == "get users success")
    requestUri = uri.parseUri("http://example.com/users/users")
    request = nhttp.Request(uri: requestUri, m: "GET")
    testRouter.handle(request, response)
    check(request.body == "get users users success")

  test "adding and retrieving root route":
    var testRouter = router.initRouter(notFound)
    testRouter.add("GET", "/", rootGetHandler)
    var requestUri = uri.parseUri("http://example.com/")
    var request = nhttp.Request(uri: requestUri, m: "GET")
    var response = nhttp.Response()
    testRouter.handle(request, response)
    check(request.body == "root get success")
