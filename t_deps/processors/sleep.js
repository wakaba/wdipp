var [sleep, text] = arguments[0].split (/,/);
document.body.appendChild (document.createTextNode (text));
return new Promise (ok => setTimeout (ok, parseFloat (sleep)*1000)).then (() => {
  return {
    statusCode: 200,
    content: {type: "text", value: document.body.textContent},
  };
});
