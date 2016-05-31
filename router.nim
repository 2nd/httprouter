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
    parameterNames: seq[string]

  RouteInfo = object
    pathNode: PathNode
    parameterValues: seq[string]

  Handler* = proc(request: nhttp.Request, response: nhttp.Response)

#PRIVATE
proc getChild(this: PathNode, key: string): PathNode {.inline} =
  result = this.children.getOrDefault(key)

proc initNode(value: string, handler: Handler = nil): PathNode =
  let children = tables.initTable[string, PathNode]()
  let parameterNames = newSeq[string]()
  result = PathNode(value: value, children: children, handler: handler,
                    parameterNames: parameterNames)

proc isLast(this: seq[string], i: int): bool {.inline} =
  result = i == this.len() - 1

proc isParameter(this: string): bool =
  result = this.startsWith(PARAMETER_PREFIX)

proc addRoute(this: Router, routeComponents: seq[string], handler: Handler) =
  var currentNode = this.root
  var parameterNames = newSeq[string]()
  for i, routeComponent in routeComponents:
    var child = currentNode.getChild(routeComponent)
    if child.isNil():
      if routeComponent.isParameter():
        parameterNames.add(routeComponent)
        child = currentNode.getChild(PARAMETER_KEYWORD)
        if child.isNil():
          child = initNode(PARAMETER_KEYWORD)
          currentNode.children[PARAMETER_KEYWORD] = child
      else:
        child = initNode(routeComponent)
        currentNode.children[routeComponent] = child
    if routeComponents.isLast(i):
      child.handler = handler
      child.parameterNames = parameterNames
    currentNode = child

proc hasHandler(this: PathNode): bool {.inline} =
  result = not this.handler.isNil()

proc getRouteInfo(this: Router, routeComponents: seq[string],
                  request: nhttp.Request): RouteInfo =
  var currentNode = this.root
  var parameterValues = newSeq[string]()
  for i, routeComponent in routeComponents:
    var child = currentNode.getChild(routeComponent)
    if child.isNil():
      child = currentNode.getChild(PARAMETER_KEYWORD)
      if child.isNil():
        return RouteInfo()
      parameterValues.add(routeComponent)
    if routeComponents.isLast(i):
      if child.hasHandler():
        return RouteInfo(pathNode: child, parameterValues: parameterValues)
      return RouteInfo()
    currentNode = child

proc nthParameterName(this: RouteInfo, n: int): string =
  result = this.pathnode.parameterNames[n]

#PUBLIC
proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  let routeComponents = (methd.toUpper() & path).split(PATH_SEPARATOR)
  this.addRoute(routeComponents, handler)

proc debug*(this: PathNode, depth: int) =
  echo "-------------"
  echo "  ".repeat(depth), this.value, " has handler: ", not this.handler.isNil()
  echo "  ".repeat(depth), this.value, " parameters: "
  for parameterName in this.parameterNames:
    echo "  ".repeat(depth + 1), parameterName
  for node in this.children.values:
    node.debug(depth + 1)

proc debug*(this: Router) =
  echo "-------------"
  echo "Router has not-found handler: ", not this.notFound.isNil()
  echo "Router has error handler: ", not this.error.isNil()
  this.root.debug(1)

proc defaultError*(request: nhttp.Request, response: nhttp.Response)
                  {.procvar.} =
  response.write(ERROR_CODE)

proc defaultNotFound*(request: nhttp.Request, response: nhttp.Response)
                    {.procvar.} =
  response.write(NOT_FOUND_CODE)

proc handle*(this: Router, request: nhttp.Request, response: nhttp.Response) =
  try:
    let path = request.uri.path
    let methd = request.m
    let routeComponents = (methd & path).split(PATH_SEPARATOR)
    let routeInfo = this.getRouteInfo(routeComponents, request)
    if routeInfo.pathNode.isNil():
      this.notFound(request, response)
    else:
      for i, parameterValue in routeInfo.parameterValues:
        request.parameters[routeInfo.nthParameterName(i)] = parameterValue
      routeInfo.pathNode.handler(request, response)
  except:
    this.error(request, response)

proc initRouter*(notFound: Handler = defaultNotFound,
                error: Handler = defaultError): Router =
  let children = tables.initTable[string, PathNode]()
  result.root = PathNode(value: ROOT_VALUE, children: children)
  result.notFound = notFound
  result.error = error
