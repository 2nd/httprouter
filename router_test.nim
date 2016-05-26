import router, nhttp, unittest, uri, typetraits, tables

proc notFound(request: nhttp.Request, response: nhttp.Response) =
  request.body = "not found"

proc rootGetHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "root get success"

proc rootPostHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "root post success"

proc getUsersHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users success"

proc getUsersUsersHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users users success"

proc getUsersCommentsFuncHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get users comments func success"

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

  
