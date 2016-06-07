import strutils, tables, nhttp, uri, strtabs

const PARAMETER_KEYWORD = "$"
const PATH_SEPARATOR = "/"
const ROOT_VALUE = "root"
const PARAMETER_PREFIX = ":"
const NOT_FOUND_CODE = 404
const ERROR_CODE = 500

type
  PathNode = ref object
    children: Table[string, PathNode]
    value: string
    handler: Handler
    parameterNames: seq[string]

  Router* = PathNode

  RouteInfo = object
    pathNode: PathNode
    parameterValues: seq[string]

  Handler* = proc(request: nhttp.Request, response: nhttp.Response)

#PRIVATE
proc getChild(this: PathNode, key: string): PathNode {.inline.} =
  this.children.getOrDefault(key)

proc initNode(value: string, handler: Handler = nil): PathNode =
  let children = tables.initTable[string, PathNode]()
  let parameterNames = newSeq[string]()
  PathNode(value: value, children: children, handler: handler, parameterNames: parameterNames)

proc isParameter(this: string): bool =
  this.startsWith(PARAMETER_PREFIX)

proc addRoute(this: Router, routeComponents: seq[string], handler: Handler) =
  var currentNode = this
  var parameterNames = newSeq[string]()
  var child: PathNode
  for i, routeComponent in routeComponents:
    child = currentNode.getChild(routeComponent)
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
    currentNode = child
  child.handler = handler
  child.parameterNames = parameterNames

proc hasHandler(this: PathNode): bool {.inline} =
  not this.handler.isNil()

proc getRouteInfo(this: Router, routeComponents: seq[string]): RouteInfo =
  var currentNode = this
  var parameterValues = newSeq[string]()
  var child: PathNode
  for i, routeComponent in routeComponents:
    child = currentNode.getChild(routeComponent)
    if child.isNil():
      child = currentNode.getChild(PARAMETER_KEYWORD)
      if child.isNil():
        return RouteInfo()
      parameterValues.add(routeComponent)
    currentNode = child
  if child.hasHandler():
    return RouteInfo(pathNode: child, parameterValues: parameterValues)
  return RouteInfo()

proc nthParameterName(this: RouteInfo, n: int): string =
  this.pathnode.parameterNames[n]

#PUBLIC
proc add*(this: var Router, methd: string, path: string, handler: Handler) =
  let routeComponents = (methd.toUpper() & path).split(PATH_SEPARATOR)
  this.addRoute(routeComponents, handler)

proc defaultError*(request: nhttp.Request, response: nhttp.Response) {.procvar.} =
  response.write(ERROR_CODE)

proc defaultNotFound*(request: nhttp.Request, response: nhttp.Response) {.procvar.} =
  response.write(NOT_FOUND_CODE)

proc initRouter*(server: var nhttp.Server, notFound: Handler = defaultNotFound, error: Handler = defaultError): Router =
  let router = PathNode(value: ROOT_VALUE, children: initTable[string, PathNode]())
  server.handler = proc (request: nhttp.Request, response: nhttp.Response) =
    try:
      let path = request.uri.path
      let methd = request.m
      let routeComponents = (methd & path).split(PATH_SEPARATOR)
      let routeInfo = router.getRouteInfo(routeComponents)
      if routeInfo.pathNode.isNil():
        notFound(request, response)
      else:
        for i, parameterValue in routeInfo.parameterValues:
          request.params[routeInfo.nthParameterName(i)] = parameterValue
        routeInfo.pathNode.handler(request, response)
    except:
      error(request, response)

  return router
