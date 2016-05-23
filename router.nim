import strutils, tables, sets


#define types in single nested type
type
  Router* = object
    root: PathNode

  PathNode = object #object or ref object. figure out children/handler
    children: Table[string, PathNode] #TABLES ARE GENERIC
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
    this.addRoute(currentNode.children[currentComponent], routeComponents[1..(routeComponents.len - 1)])
  else:
    var newNode = PathNode(children: initTable[string, PathNode](), value: currentComponent)
    currentNode.children[currentComponent] = newNode
    echo this.root
    #echo currentNode
    this.addRoute(newNode, routeComponents[1..(routeComponents.len - 1)])


proc initRoute(this: var Router, route: string) =
  var routeComponents = route.split("/")
  this.addRoute(this.root, routeComponents)

proc initRoutes(this: var Router) =
  this.initRoute("get/posts/comments")

proc initRouter(): Router =
  var router = Router()
  router.root = PathNode(value: "root", children: initTable[string, PathNode]())
  router.initRoutes()
  return router

var router = initRouter()
