import strutils, tables, sets


#define types in single nested type
type
  Router* = ref object
    root: PathNode

  PathNode = object #object or ref object. figure out children/handler
    children: tables.Table[string, PathNode] #TABLES ARE GENERIC
    value: string
    #handler: Handler

  #Handler* = proc(req: nhttp.Request, res: nhttp.Response)


# """proc initPathTree(this: Router) =
#   var commentIdNode = new PathNode(value: "4", children: nil)
#   var commentChildren = Set[PathNode*]
#   commentChildren.init(&commentIdNode)
#   var postsIdNode = new PathNode(value: "1", children: nil)
#   var commentsNode = new PathNode(value: "comments")
#   var postChildren =
#   var postsNode = new PathNode(value: "posts" children: )"""

# proc handle(this: Router, req: string, res: string) =
#   echo "hi"

proc addRoute(this: Router, currentNode: PathNode, route: string) =
  echo route

proc initRoute(this: Router, route: string) =
  this.addRoute(this.root, route)

proc initRoutes(this: Router) =
  this.initRoute("get/posts/comments/")

proc initRouter(): Router =
  var result = Router()
  result.root= PathNode(value: "root", children: initTable[string, PathNode]())
  result.initRoutes()

var router = initRouter()
