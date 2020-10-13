return {
  statusCode: 200,
  content: {type: "text", value: [typeof arguments[0], arguments[0]].join (",")},
};
