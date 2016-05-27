import strutils, tables, nhttp, uri

type
  Router* = object
    root: PathNode
    notFound*: Handler
    error*: Handler

  PathNode = ref object
    children: Table[string, PathNode]
    value: string
    handler: Handler

  Handler* = proc(request: nhttp.Request, response: nhttp.Response)

proc defaultNotFound*(request: nhttp.Request, response: nhttp.Response) {.procvar.} =
  request.body = "404"

proc defaultError*(request: nhttp.Request, response: nhttp.Response) {.procvar.} =
  request.body = "500"

proc debug*(this: PathNode, depth: int) =
  echo "  ".repeat(depth), this.value, " has handler: ", not this.handler.isNil
  for node in this.children.values:
    node.debug(depth + 1)

proc debug*(this: Router) =
  echo "Router has not-found handler: ", not this.notFound.isNil
  echo "Router has error handler: ", not this.error.isNil
  this.root.debug(0)

proc findOrDefault(this: PathNode, condition: proc(s: string): bool): PathNode =
  for key, value in this.children.pairs:
    if condition(key):
      return value
  return nil

proc getHandler(this: Router, routeComponents: seq[string], request: nhttp.Request): Handler =
  var currentNode = this.root
  for i, routeComponent in routeComponents:
    var child = currentNode.children.getOrDefault(routeComponent)
    if child.isNil:
      child = currentNode.findOrDefault(proc(s: string): bool = s.startsWith(":"))
      if child.isNil:
        return this.notFound
    if i == routeComponents.len() - 1:
      if not child.handler.isNil:
        return child.handler
      return this.notFound
    currentNode = child

proc initNode(value: string, handler: Handler): PathNode =
  let children = tables.initTable[string, PathNode]()
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
  try:
    let path = request.uri.path
    let methd = request.m
    let handler = this.getHandler(this.routeComponents(methd, path), request)
    handler(request, response)
  except:
    this.error(request, response)

proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  this.addRoute(this.routeComponents(methd, path), handler)

# proc initRouter*(notFound: Handler = proc(request: nhttp.Request, response: nhttp.Response) =
#   request.body = "404", error: Handler = proc (request: nhttp.Request, response: nhttp.Response) =
#     request.body = "500"): Router =
proc initRouter*(notFound: Handler = defaultNotFound, error: Handler = defaultError): Router =
  let children = tables.initTable[string, PathNode]()
  result.root = PathNode(value: "root", children: children)
  result.notFound = notFound
  result.error = error
