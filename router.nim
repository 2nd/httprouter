import strutils, tables

type
  Router = object
    root: PathNode

  PathNode = ref object
    children: Table[string, PathNode]
    value: string
    #handler: Handler


  #Handler* = proc(req: nhttp.Request, res: nhttp.Response)

  # proc handle(this: Router, req: string, res: string) =
  #   echo "hi"

#ask karl about this
proc initNode(value: string): PathNode =
  result = PathNode(value: value, children: initTable[string, PathNode]())

proc addRoute(this: Router, currentNode: var PathNode, routeComponents: seq[string]) =
  if len(routeComponents) == 0:
    return
  var currentComponent = routeComponents[0]
  if(currentNode.children.hasKey(currentComponent)):
    this.addRoute(currentNode.children[currentComponent], routeComponents[1..routeComponents.high()])
  else:
    var newNode = initNode(currentComponent)
    currentNode.children[currentComponent] = newNode
    this.addRoute(newNode, routeComponents[1..routeComponents.high()])

proc add(this: var Router, methd: string, path: string) =
  this.addRoute(this.root, (methd & path).split("/"))

proc initRoutes(this: var Router) =
  this.add("get", "/posts/comments")
  this.add("get", "/posts/tags")

proc initRouter(): Router =
  result.root = PathNode(value: "root", children: initTable[string, PathNode]())
  result.initRoutes()

var router = initRouter()
echo router.root.children["get"].children["posts"].children["comments"].value
echo router.root.children["get"].children["posts"].children.len()
