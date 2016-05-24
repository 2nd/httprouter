import strutils, tables, nhttp

type
  Router = object
    root: PathNode

  PathNode = ref object
    children: Table[string, PathNode]
    value: string
    handler: Handler

  Handler = proc(req: string, res: string)

  #Handler* = proc(req: nhttp.Request, res: nhttp.Response)

  # proc handle(this: Router, req: string, res: string) =
  #   echo "hi"

proc initNode(value: string, handler: Handler): PathNode =
  #KARL why doesn't this work --> result.value = value
  result = PathNode(value: value, children: initTable[string, PathNode](), handler: handler)

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

proc add(this: var Router, methd: string, path: string, handler: Handler) =
  this.addRoute(this.root, (methd & path).split("/"), handler)

proc blahblah(req: string, res: string) =
  echo req & res

proc initRoutes(this: var Router) =
  this.add("get", "/posts/comments", blahblah)
  this.add("get", "/posts/tags", blahblah)

proc initRouter(): Router =
  result.root = PathNode(value: "root", children: initTable[string, PathNode]())
  result.initRoutes()

var router = initRouter()
router.root.children["get"].children["posts"].children["comments"].handler("hi", "you")
