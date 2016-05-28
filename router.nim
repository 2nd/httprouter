import strutils, tables, nhttp, uri, strtabs

type
  Router* = object
    root: PathNode
    notFound*: Handler
    error*: Handler

  PathNode = ref object
    children: Table[string, PathNode]
    value: string
    handler: Handler
    parameters: seq[string]

  RouteInfo = object
    pathNode: PathNode
    parameters: seq[string]

  Handler* = proc(request: nhttp.Request, response: nhttp.Response)

proc defaultNotFound*(request: nhttp.Request, response: nhttp.Response) {.procvar.} =
  response.write(404)

proc defaultError*(request: nhttp.Request, response: nhttp.Response) {.procvar.} =
  response.write(500)

proc debug*(this: PathNode, depth: int) =
  echo "-------------"
  echo "  ".repeat(depth), this.value, " has handler: ", not this.handler.isNil
  echo "  ".repeat(depth), this.value, " parameters: "
  for parameter in this.parameters:
    echo "  ".repeat(depth + 1), parameter
  for node in this.children.values:
    node.debug(depth + 1)

proc debug*(this: Router) =
  echo "-------------"
  echo "Router has not-found handler: ", not this.notFound.isNil
  echo "Router has error handler: ", not this.error.isNil
  this.root.debug(1)

# proc findOrDefault(this: PathNode, condition: proc(s: string): bool): PathNode =
#   for key, value in this.children.pairs:
#     if condition(key):
#       return value
#   return nil

proc getRouteInfo(this: Router, routeComponents: seq[string], request: nhttp.Request): RouteInfo =
  var currentNode = this.root
  var parameters = newSeq[string]()
  for i, routeComponent in routeComponents:
    var child = currentNode.children.getOrDefault(routeComponent)
    if child.isNil:
      child = currentNode.children.getOrDefault("parameter")
      if child.isNil:
        return RouteInfo()
      parameters.add(routeComponent)
    if i == routeComponents.len() - 1:
      if not child.handler.isNil:
        return RouteInfo(pathNode: child, parameters: parameters)
      return RouteInfo()
    currentNode = child

    #
    #   child = currentNode.findOrDefault(proc(s: string): bool = s.startsWith(":"))
    #   if child.isNil:
    #     return this.notFound
    # if i == routeComponents.len() - 1:
    #   if not child.handler.isNil:
    #     return child.handler
    #   return this.notFound
    # currentNode = child

proc initNode(value: string, handler: Handler): PathNode =
  let children = tables.initTable[string, PathNode]()
  let parameters = newSeq[string]()
  result = PathNode(value: value, children: children, handler: handler, parameters: parameters)

proc routeComponents(this: Router, methd: string, path: string): seq[string] =
  result = (methd.toUpper() & path).split("/")

proc addRoute(this: Router, routeComponents: seq[string], handler: Handler) =
  var currentNode = this.root
  var parameters = newSeq[string]()
  for i, routeComponent in routeComponents:
    var child = currentNode.children.getOrDefault(routeComponent)
    if child.isNil:
      if routeComponent.startsWith(":"):
        parameters.add(routeComponent)
        child = currentNode.children.getOrDefault("parameter")
        if child.isNil:
          child = initNode("parameter", nil)
          currentNode.children["parameter"] = child
      else:
        child = initNode(routeComponent, nil)
        currentNode.children[routeComponent] = child
    if i == routeComponents.len() - 1:
      child.handler = handler
      child.parameters = parameters
    currentNode = child

proc handle*(this: Router, request: nhttp.Request, response: nhttp.Response) =
  try:
    let path = request.uri.path
    let methd = request.m
    let routeInfo = this.getRouteInfo(this.routeComponents(methd, path), request)
    if routeInfo.pathNode.isNil:
      this.notFound(request, response)
    else:
      for i, parameter in routeInfo.parameters:
        request.parameters[routeInfo.pathNode.parameters[i]] = parameter
      routeInfo.pathNode.handler(request, response)
  except:
    this.error(request, response)

proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  this.addRoute(this.routeComponents(methd, path), handler)

proc initRouter*(notFound: Handler = defaultNotFound, error: Handler = defaultError): Router =
  let children = tables.initTable[string, PathNode]()
  result.root = PathNode(value: "root", children: children)
  result.notFound = notFound
  result.error = error
