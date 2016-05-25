import router, nhttp, unittest, uri

proc notFound(request: nhttp.Request, response: nhttp.Response) =
  echo "oh no! not found"

proc postsCommentsHandler(request: nhttp.Request, response: nhttp.Response) =
  request.body = "hieverybody"

proc postsTagsHandler(request: nhttp.Request, response: nhttp.Response) =
  echo "whatap"

var test_router = router.initRouter(notFound)

var testRequestURI = uri.parseUri("http://example.com/posts/comments")
var testRequest = nhttp.Request(uri: testRequestURI, m: "GET" )
var testResponse = nhttp.Response()

suite "router":

  test "adding route":
    test_router.add("get", "/posts/comments", postsCommentsHandler)
    test_router.handle(testRequest, testResponse)
    check(testRequest.body == "hieverybody")

  test "handling route":
    echo "hi"
