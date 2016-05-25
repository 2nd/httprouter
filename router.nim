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

proc getHandler(this: Router, currentNode: PathNode, routeComponents: seq[string]): Handler =
  if len(routeComponents) == 0:
    return currentNode.handler
  var currentComponent = routeComponents[0]
  if(currentNode.children.hasKey(currentComponent)):
    let slicedComponents = routeComponents[1..routeComponents.high()]
    let child = currentNode.children[currentComponent]
    return this.getHandler(child, slicedComponents)
  else:
    return this.notFound

proc initNode(value: string, handler: Handler): PathNode =
  result = PathNode(value: value, children: tables.initTable[string, PathNode](), handler: handler)

proc routeComponents(this: Router, methd: string, path: string): seq[string] =
  result = (methd.toLower() & path).split("/")

proc addRoute(this: Router, currentNode: var PathNode, routeComponents: seq[string], handler: Handler) =
  if len(routeComponents) == 0:
    return
  let currentComponent = routeComponents[0]
  if(currentNode.children.hasKey(currentComponent)):
    var child = currentNode.children[currentComponent]
    let slicedComponents = routeComponents[1..routeComponents.high()]
    this.addRoute(child, slicedComponents, handler)
  else:
    var newNode = initNode(currentComponent, handler)
    currentNode.children[currentComponent] = newNode
    this.addRoute(newNode, routeComponents[1..routeComponents.high()], handler)

proc handle*(this: Router, request: nhttp.Request, response: nhttp.Response) =
  let path = request.uri.path
  let methd = request.m
  let handler = this.getHandler(this.root, this.routeComponents(methd, path))
  handler(request, response)

proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  this.addRoute(this.root, this.routeComponents(methd, path), handler)

proc initRouter*(notFound: Handler): Router =
  var children = tables.initTable[string, PathNode]()
  result.root = PathNode(value: "root", children: children )
  result.notFound = notFound
