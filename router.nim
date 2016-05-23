import strutils, tables, sets


#define types in single nested type
type
  Router* = ref object
    routes : tables.Table[string, PathNode]

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

proc traverseOrAdd(this: Router, httpAndRoute: string) =
  let components = strutils.split(httpAndroute, "/")
  

proc initRoute(this: Router, route: string, httpMethod: string) =
  this.traverseOrAdd(httpMethod & "/" & route)

proc initRoutes(this: Router) =
  this.initRoute("get", "/posts/comments/")
  this.initRoute("get", "/posts/comments/4")
  this.initRoute("post", "/posts")
  this.initRoute("get", "/posts/1")



proc parse(this: Router, path: string) =
  let components = strutils.split(path, "/")


proc handle(this: Router, req: string, res: string) =
  echo "hi"


var router = new(Router)
router.parse("hey/you")
