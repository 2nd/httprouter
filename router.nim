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

proc getHandler(this: Router, routeComponents: seq[string]): Handler =
  var currentNode = this.root
  for i, routeComponent in routeComponents:
    if(i == routeComponents.len() - 1):
      return currentNode.handler
    else:
      currentNode = currentNode.children.getOrDefault(routeComponent)
      if(currentNode == nil):
        return this.notFound

proc initNode(value: string, handler: Handler): PathNode =
  var children = tables.initTable[string, PathNode]()
  result = PathNode(value: value, children: children, handler: handler )

proc routeComponents(this: Router, methd: string, path: string): seq[string] =
  result = (methd.toUpper() & path).split("/")

proc addRoute(this: Router, routeComponents: seq[string], handler: Handler) =
  # if len(routeComponents) == 0:
  #   return
  # let currentComponent = routeComponents[0]
  # var child = currentNode.children.getOrDefault(currentComponent)
  # if(child != nil):
  #   let slicedComponents = routeComponents[1..routeComponents.high()]
  #   this.addRoute(child, slicedComponents, handler)
  # else:
  #   var newNode = initNode(currentComponent, handler)
  #   currentNode.children[currentComponent] = newNode
  #   this.addRoute(newNode, routeComponents[1..routeComponents.high()], handler)
  var currentNode = this.root
  for i, routeComponent in routeComponents:
    echo "i: "
    echo i
    echo "route component: "
    echo routeComponent
    echo "current node: "
    echo currentNode.value
    if(i == routeComponents.len() - 1):
      echo "first if statement"
      echo "value of current node getting handler attached"
      echo currentNode.value
      currentNode.handler = handler
      return
    else:
      echo "checking current node's children"
      var childNode = currentNode.children.getOrDefault(routeComponent)
      if(childNode == nil):
        echo "2nd if statement (i.e. the new value was not yet in the tree)"
        echo "value of new node: "
        var newNode = initNode(routeComponent, nil)
        echo newNode.value
        echo "adding new node to current node's children"
        currentNode.children[routeComponent] = newNode
        echo "swapping current node for new node"
        echo "value of current node"
        currentNode = newNode
        echo currentNode.value
      else:
        currentNode = childNode



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
