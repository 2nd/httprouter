import strutils, tables, sequtils

type
  Router = object
    root: PathNode

  PathNode = ref object
    children: Table[string, PathNode]
    value: string
    #handler: Handler


  #Handler* = proc(req: nhttp.Request, res: nhttp.Response)


proc handle(this: Router, req: string, res: string) =
  echo "hi"

proc addRoute(this: Router, currentNode: var PathNode, routeComponents: seq[string]) =
  if len(routeComponents) == 0:
    return
  var currentComponent = routeComponents[0]
  if(currentNode.children.hasKey(currentComponent)):
    this.addRoute(currentNode.children[currentComponent], routeComponents[1..routeComponents.high()])
  else:
    var newNode = PathNode(children: initTable[string, PathNode](), value: currentComponent)
    currentNode.children[currentComponent] = newNode
    this.addRoute(newNode, routeComponents[1..routeComponents.high()])


proc initRoute(this: var Router, action: string, path: string) =
  var pathComponents = path.split("/")
  pathComponents = pathComponents[1..pathComponents.high()]
  echo pathComponents
  this.addRoute(this.root, sequtils.concat(@[action], pathComponents))

proc initRoutes(this: var Router) =
  this.initRoute("get", "/posts/comments")
  this.initRoute("get", "/posts/tags")

proc initRouter(): Router =
  var router = Router()
  router.root = PathNode(value: "root", children: initTable[string, PathNode]())
  router.initRoutes()
  return router


var router = initRouter()
echo router.root.children["get"].children["posts"].children["comments"].value
echo router.root.children["get"].children["posts"].children.len()
