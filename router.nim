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

proc debug(this: PathNode, depth: int) =
  echo "  ".repeat(depth), this.value, " has handler: ", not this.handler.isNil
  for node in this.children.values:
    node.debug(depth + 1)

proc debug(this: Router) =
  echo "Router has not-found handler: ", not this.notFound.isNil
  this.root.debug(0)

proc getHandler(this: Router, routeComponents: seq[string]): Handler =
  var currentNode = this.root
  for i, routeComponent in routeComponents:
    var child = currentNode.children.getOrDefault(routeComponent)
    if child.isNil:
      return this.notFound
    if i == routeComponents.len() - 1:
      return child.handler
    currentNode = child

proc initNode(value: string, handler: Handler): PathNode =
  var children = tables.initTable[string, PathNode]()
  result = PathNode(value: value, children: children, handler: handler )

proc routeComponents(this: Router, methd: string, path: string): seq[string] =
  result = (methd.toUpper() & path).split("/")

proc addRoute(this: Router, routeComponents: seq[string], handler: Handler) =
  var currentNode = this.root
  for i, routeComponent in routecomponents:
    var child = currentNode.children.getOrDefault(routeComponent)
    if child.isNil:
      child = initNode(routeComponent, nil)
    if i == routeComponents.len() - 1:
      child.handler = handler
    currentNode.children[routeComponent] = child
    currentNode = child

proc handle*(this: Router, request: nhttp.Request, response: nhttp.Response) =
  let path = request.uri.path
  let methd = request.m
  let handler = this.getHandler(this.routeComponents(methd, path))
  handler(request, response)

proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  this.addRoute(this.routeComponents(methd, path), handler)

proc initRouter*(notFound: Handler): Router =
  var children = tables.initTable[string, PathNode]()
  result.root = PathNode(value: "root", children: children)
  result.notFound = notFound
