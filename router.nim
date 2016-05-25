import strutils, tables, nhttp, uri

type
  Router* = object
    root: PathNode
    notFound*: Handler

  PathNode = ref object
    children: Table[string, PathNode]
    value: string
    handler: Handler

  Handler* = proc(request: nhttp.Request, response: nhttp.Response)

  #Handler* = proc(req: nhttp.Request, res: nhttp.Response)

  # proc handle(this: Router, req: string, res: string) =
  #   echo "hi"

proc routeComponents(this: Router, methd: string, path: string): seq[string] =
  result = (methd.toLower() & path).split("/")

proc getHandler(this: Router, currentNode: PathNode, routeComponents: seq[string]): Handler =
  if len(routeComponents) == 0:
    return currentNode.handler
  var currentComponent = routeComponents[0]
  if(currentNode.children.hasKey(currentComponent)):
    return this.getHandler(currentNode.children[currentComponent], routeComponents[1..routeComponents.high()])
  else:
    return this.notFound

proc handle*(this: Router, request: nhttp.Request, response: nhttp.Response) =
  var path = request.uri.path
  var methd = request.m
  var handler = this.getHandler(this.root, this.routeComponents(methd, path))
  handler(request, response)

proc initNode(value: string, handler: Handler): PathNode =
  result = PathNode(value: value, children: tables.initTable[string, PathNode](), handler: handler)

proc addRoute(this: Router, currentNode: var PathNode, routeComponents: seq[string], handler: Handler) =
  if len(routeComponents) == 0:
    return
  var currentComponent = routeComponents[0]
  if(currentNode.children.hasKey(currentComponent)):
    this.addRoute(currentNode.children[currentComponent], routeComponents[1..routeComponents.high()], handler)
  else:
    var newNode = initNode(currentComponent, handler)
    currentNode.children[currentComponent] = newNode
    this.addRoute(newNode, routeComponents[1..routeComponents.high()], handler)

proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  this.addRoute(this.root, this.routeComponents(methd, path), handler)

proc blahblah(req: nhttp.Request, res: nhttp.Response) =
  echo "hithurr"

proc blahblahblah(request: nhttp.Request, response: nhttp.Response) =
  echo "heysw"

proc initRoutes(this: var Router) =
  this.add("get", "/posts/comments", blahblah)
  this.add("get", "/posts/tags", blahblahblah)

proc notFound(request: nhttp.Request, response: nhttp.Response) =
  echo "oh no! not found"

proc initRouter*(notFound: Handler): Router =
  result.root = PathNode(value: "root", children: tables.initTable[string, PathNode]())
  result.notFound = notFound
  #result.initRoutes()

var router = initRouter(notFound)
var dummy_request_uri = uri.parseUri("http://example.com/posts/tags")
var dummy_request = nhttp.Request(uri: dummy_request_uri, m: "GET" )
var dummy_response = nhttp.Response()
router.handle(dummy_request, dummy_response)
#router.root.children["get"].children["posts"].children["comments"]#.handler("hi", "you")
