return new Promise (ok => setTimeout (ok, 10*1000)).then (() => {
  return {
    statusCode: 200,
    content: {type: "text", value: [typeof arguments[0], arguments[0]].join (",")},
  };
});
