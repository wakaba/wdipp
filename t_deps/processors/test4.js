document.body.innerHTML = "こんにちは!<p>Hello!";
return {
  statusCode: 201,
  content: {type: "screenshot", targetElement: "p"},
  httpCache: {maxAge: 5331},
};
