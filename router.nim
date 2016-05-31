import strutils, tables, nhttp, uri, strtabs

const PARAMETER_KEYWORD = "parameter"
const PATH_SEPARATOR = "/"
const ROOT_VALUE = "root"
const PARAMETER_PREFIX = ":"
const NOT_FOUND_CODE = 404
const ERROR_CODE = 500

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

proc debug*(this: PathNode, depth: int) =
  echo "-------------"
  echo "  ".repeat(depth), this.value, " has handler: ", not this.handler.isNil()
  echo "  ".repeat(depth), this.value, " parameters: "
  for parameter in this.parameters:
    echo "  ".repeat(depth + 1), parameter
  for node in this.children.values:
    node.debug(depth + 1)

proc debug*(this: Router) =
  echo "-------------"
  echo "Router has not-found handler: ", not this.notFound.isNil()
  echo "Router has error handler: ", not this.error.isNil()
  this.root.debug(1)

proc defaultNotFound*(request: nhttp.Request, response: nhttp.Response)
                    {.procvar.} =
  response.write(NOT_FOUND_CODE)

proc defaultError*(request: nhttp.Request, response: nhttp.Response)
                  {.procvar.} =
  response.write(ERROR_CODE)

proc getChild(this: PathNode, key: string): PathNode =
  result = this.children.getOrDefault(key)

proc isLast(this: seq[string], i: int): bool =
  result = i == this.len() - 1

proc hasHandler(this: PathNode): bool =
  result = not this.handler.isNil()

proc getRouteInfo(this: Router, routeComponents: seq[string],
                  request: nhttp.Request): RouteInfo =
  var currentNode = this.root
  var parameters = newSeq[string]()
  for i, routeComponent in routeComponents:
    var child = currentNode.getChild(routeComponent)
    if child.isNil():
      child = currentNode.getChild(PARAMETER_KEYWORD)
      if child.isNil():
        return RouteInfo()
      parameters.add(routeComponent)
    if routeComponents.isLast(i):
      if child.hasHandler():
        return RouteInfo(pathNode: child, parameters: parameters)
      return RouteInfo()
    currentNode = child

proc initNode(value: string, handler: Handler): PathNode =
  let children = tables.initTable[string, PathNode]()
  let parameters = newSeq[string]()
  result = PathNode(value: value, children: children, handler: handler,
                    parameters: parameters)

proc isParameter(this: string): bool =
  result = this.startsWith(PARAMETER_PREFIX)

proc addRoute(this: Router, routeComponents: seq[string], handler: Handler) =
  var currentNode = this.root
  var parameters = newSeq[string]()
  for i, routeComponent in routeComponents:
    var child = currentNode.getChild(routeComponent)
    if child.isNil():
      if routeComponent.isParameter:
        parameters.add(routeComponent)
        child = currentNode.getChild(PARAMETER_KEYWORD)
        if child.isNil():
          child = initNode(PARAMETER_KEYWORD, nil)
          currentNode.children[PARAMETER_KEYWORD] = child
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
    let routeComponents = (methd & path).split(PATH_SEPARATOR)
    let routeInfo = this.getRouteInfo(routeComponents, request)
    if routeInfo.pathNode.isNil():
      this.notFound(request, response)
    else:
      for i, parameter in routeInfo.parameters:
        request.parameters[routeInfo.pathNode.parameters[i]] = parameter
      routeInfo.pathNode.handler(request, response)
  except:
    this.error(request, response)

proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  let routeComponents = (methd.toUpper() & path).split(PATH_SEPARATOR)
  this.addRoute(routeComponents, handler)

proc initRouter*(notFound: Handler = defaultNotFound,
                error: Handler = defaultError): Router =
  let children = tables.initTable[string, PathNode]()
  result.root = PathNode(value: ROOT_VALUE, children: children)
  result.notFound = notFound
  result.error = error
