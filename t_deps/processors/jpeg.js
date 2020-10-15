var q = parseFloat (arguments[0]);
document.body.innerHTML = "こんにちは!<p>Hello! " + q;
return {
  statusCode: 201,
  content: {type: "screenshot", targetElement: document.querySelector("p"),
            imageType: "jpeg",
            imageQuality: q},
};
