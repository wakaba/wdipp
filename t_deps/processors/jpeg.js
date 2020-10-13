var q = parseFloat (arguments[0]);
document.body.innerHTML = "こんにちは!<p>Hello! " + q;
return {
  statusCode: 201,
  content: {type: "screenshot", targetElement: "p", imageType: "jpeg",
            imageQuality: q},
};
