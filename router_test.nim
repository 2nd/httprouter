import router, nhttp, unittest, uri

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

var testRouter = router.initRouter(notFound)
let testResponse = nhttp.Response()

suite "router":

  test "adding and retrieving route":
    echo "hi"
    # testRouter.add("GET", "/users/comments", getUsersCommentsHandler)
    # testRouter.add("POST", "/users/comments", postUsersCommentsHandler)
    # testRouter.add("GET", "/users/comments/func", getUsersCommentsFuncHandler)
    # var testRequestURI = uri.parseUri("http://example.com/users/comments")
    # var testRequest = nhttp.Request(uri: testRequestURI, m: "GET" )
    # testRouter.handle(testRequest, testResponse)
    # check(testRequest.body == "get users comments success")
    # testRequest = nhttp.Request(uri: testRequestURI, m: "POST")
    # testRouter.handle(testRequest, testResponse)
    # check(testRequest.body == "post users comments success")
    # testRequestURI = uri.parseUri("http://example.com/users/comments/func")
    # testRequest = nhttp.Request(uri: testRequestURI, m: "GET")
    # testRouter.handle(testRequest, testResponse)
    # check(testRequest.body == "get users comments func success")

  test "adding and retrieving route with same words back to back":
    testRouter.add("GET", "/users/users", getUsersUsersHandler)
    testRouter.add("GET", "/users", getUsersHandler)
    # var testRequestURI = uri.parseURI("http://example.com/users")
    # var testRequest = nhttp.Request(uri: testRequestURI, m: "GET")
    # testRouter.handle(testRequest, testResponse)
    # check(testRequest.body == "get users success")

  test "adding a path without a slash returns an error":
    echo "hi"


  test "invoking not found for invalid routes":
    # var badTestRequestURI = uri.parseURI("http://example.com/posts/comment")
    # var badTestRequest = nhttp.Request(uri: badTestRequestURI, m: "GET")
    # testRouter.handle(badTestRequest, testResponse)
    # check(badTestRequest.body == "not found")
    # badTestRequestURI = uri.parseURI("http://example.com//")
    # badTestRequest = nhttp.Request(uri: badTestRequestURI, m: "GET")
    # testRouter.handle(badTestRequest, testResponse)
    # check(badTestRequest.body == "not found")
    var badTestRequestURI = uri.parseURI("http://example.com/")
    var badTestRequest = nhttp.Request(uri: badTestRequestURI, m: "GET")
    testRouter.handle(badTestRequest, testResponse)
    echo "++++++++"
    echo badTestRequest.body
    check(badTestRequest.body == "not found")

  test "adding and retrieving root route":
    echo "hi"
    # testrouter.add("get", "/", rootGetHandler)
    # testRouter.add("post", "/", rootPostHandler)
    # let rootRequestURI = uri.parseURI("http://example.com/")
    # var rootRequest = nhttp.Request(uri: rootRequestURI, m: "GET")
    # testRouter.handle(rootRequest, testResponse)
    # check(rootRequest.body == "root get success")
    # rootRequest = nhttp.Request(uri: rootRequestURI, m: "POST")
    # testRouter.handle(rootRequest, testResponse)
    # check(rootRequest.body == "root post success")
