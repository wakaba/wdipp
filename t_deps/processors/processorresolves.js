return Promise.resolve ().then (() => {
  return {
    statusCode: 403,
    content: {
      type: 'text',
      value: "Response あいうえお",
    },
  };
});
