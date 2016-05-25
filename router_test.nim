import router, nhttp, unittest, uri

proc notFound(request: nhttp.Request, response: nhttp.Response) =
  request.body = "not found"

proc rootGetHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "root get success"

proc rootPostHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "root post success"

proc getUsersCommentsHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "get success"

proc postUsersCommentsHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "post success"

var testRouter = router.initRouter(notFound)
let testResponse = nhttp.Response()

suite "router":

  test "adding and retrieving route":
    testRouter.add("get", "/users/comments", getUsersCommentsHandler)
    testRouter.add("post", "/users/comments", postUsersCommentsHandler)
    let testRequestURI = uri.parseUri("http://example.com/users/comments")
    var testRequest = nhttp.Request(uri: testRequestURI, m: "GET" )
    testRouter.handle(testRequest, testResponse)
    check(testRequest.body == "get success")
    testRequest = nhttp.Request(uri: testRequestURI, m: "POST")
    testRouter.handle(testRequest, testResponse)
    check(testRequest.body == "post success")

  test "invoking not found for invalid routes":
    var badTestRequestURI = uri.parseURI("http://example.com/posts/comment")
    var badTestRequest = nhttp.Request(uri: badTestRequestURI, m: "GET")
    testRouter.handle(badTestRequest, testResponse)
    check(badTestRequest.body == "not found")
    badTestRequestURI = uri.parseURI("http://example.com//")
    badTestRequest = nhttp.Request(uri: badTestRequestURI, m: "GET")
    testRouter.handle(badTestRequest, testResponse)
    check(badTestRequest.body == "not found")
    badTestRequestURI = uri.parseURI("http://example.com/")
    badTestRequest = nhttp.Request(uri: badTestRequestURI, m: "GET")
    testRouter.handle(badTestRequest, testResponse)
    check(badTestRequest.body == "not found")

  test "adding and retrieving root route":
    testrouter.add("get", "/", rootGetHandler)
    testRouter.add("post", "/", rootPostHandler)
    let rootRequestURI = uri.parseURI("http://example.com/")
    var rootRequest = nhttp.Request(uri: rootRequestURI, m: "GET")
    testRouter.handle(rootRequest, testResponse)
    check(rootRequest.body == "root get success")
    rootRequest = nhttp.Request(uri: rootRequestURI, m: "POST")
    testRouter.handle(rootRequest, testResponse)
    check(rootRequest.body == "root post success")
