// Generated by CoffeeScript 1.9.0
var AmdClientResource, ClientLib, Resource, client, fs, path, streamBuffers, util;

path = require('path');

util = require('util');

fs = require('fs');

streamBuffers = require('stream-buffers');

Resource = require(path.normalize(require.main.paths[0] + "/deployd/lib/resource"));

ClientLib = require(path.normalize(require.main.paths[0] + "/deployd/lib/resources/client-lib"));

client = null;

process.server.on("listening", function() {
  return client = new ClientLib('dpdAmd.js', {
    config: {
      resources: process.server.resources
    },
    server: process.server
  });
});

AmdClientResource = (function() {
  function AmdClientResource() {
    Resource.apply(this, arguments);
    return;
  }

  return AmdClientResource;

})();

util.inherits(AmdClientResource, Resource);

AmdClientResource.label = "Amd client";

AmdClientResource.prototype.clientGeneration = false;

AmdClientResource.prototype.handle = function(ctx, next) {
  var resource, resources, server, writable;
  server = process.server;
  resources = (function() {
    var _i, _len, _ref, _results;
    _ref = server.resources;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      resource = _ref[_i];
      _results.push(resource.name);
    }
    return _results;
  })();
  if (ctx.method === "GET") {
    writable = new streamBuffers.WritableStreamBuffer();
    client.generate(writable, function() {
      var collectionMethods, dpdLibPath, originalClib;
      originalClib = writable.getContentsAsString("utf8");
      collectionMethods = originalClib.split("// automatically generated code")[1];
      writable.destroy();
      dpdLibPath = path.join(__dirname, './clib/dpd.js');
      return fs.readFile(dpdLibPath, 'utf-8', function(err, data) {
        var amdClib, clibParts, part1, part2;
        clibParts = data.split("// generatedCodeMarker");
        part1 = clibParts[0], part2 = clibParts[1];
        amdClib = "" + part1 + collectionMethods + part2;
        ctx.res.setHeader('Content-Type', 'text/javascript');
        ctx.res.write("" + amdClib);
        return ctx.res.end();
      });
    });
  } else {
    next();
  }
};

module.exports = AmdClientResource;
