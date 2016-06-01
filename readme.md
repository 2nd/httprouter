# An http router for use with the nhttp server

Allows for the attaching of handlers to routes.

#to test

Typing "Make t" in the console will run a test suite.

#to use

To initialize, call initRouter. You can pass in your own handlers to be used
on 404 and 500 errors, or you can simply call initRouter() and use the defaults.

Add a route using router.add. Example:
var router = initRouter()
router.add("GET", "users/show", getUsersShowHandler)

The first parameter is the method (GET, POST, DELETE, etc); the second is the
path, and the third is the handler to be invoked when the route is hit later on.
Handlers take an nhttp response object and an nhttp request object.

After you have initialized the router, you can handle requests with router.handle.
Call:
router.handle(request, response).

Let's say that the route contained within the request was "GET", "users/show",
i.e. that the router has a route and a handler for this request. The router
will now call getUsersShowHandler on the request and response objects.

#parameters

The router supports parameters, i.e. "users/:id/posts". Indicate a parameter in
your route by appending a colon to the front. When a route with parameters is
later handled by the router, the parameter values will be written to the
request object. For example, if "users/100/posts" is handled by the router,
the appropriate handler for "users/:id/posts" will be called, and :id => 100 will
be written to the request parameters table. 

The router does NOT support multiple routes of the same number of components but
with different parameter names. There is no way for "users/:id/posts" and "users/:name/posts"
to be differentiated, and correct behavior is not guaranteed. "users/:id/posts" and
"users/:name/posts/:id", however, is acceptable.
