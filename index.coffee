path = require 'path'
util = require 'util'
fs = require 'fs'
streamBuffers = require 'stream-buffers'

Resource = require path.normalize "#{require.main.paths[0]}/deployd/lib/resource"
ClientLib = require path.normalize "#{require.main.paths[0]}/deployd/lib/resources/client-lib"

client = null

process.server.on "listening", ->
  client = new ClientLib('dpdAmd.js', { config: { resources: process.server.resources }, server: process.server})

class AmdClientResource
  constructor: ->
    Resource.apply this, arguments
    return

util.inherits AmdClientResource, Resource
AmdClientResource.label = "Amd client"
AmdClientResource::clientGeneration = false

AmdClientResource::handle = (ctx, next) ->
  server = process.server
  resources = (resource.name for resource in server.resources)

  if ctx.method is "GET"
    writable = new streamBuffers.WritableStreamBuffer()

    client.generate writable, ->
      originalClib = writable.getContentsAsString("utf8")
      collectionMethods = originalClib.split("// automatically generated code")[1]
      writable.destroy()

      dpdLibPath = path.join(__dirname, './clib/dpd.js')
      fs.readFile dpdLibPath, 'utf-8', (err, data) ->
        clibParts = data.split "// generatedCodeMarker"
        [part1, part2] = clibParts
        amdClib = "#{part1}#{collectionMethods}#{part2}"
        ctx.res.setHeader('Content-Type', 'text/javascript')
        ctx.res.write("#{amdClib}");
        ctx.res.end();

  else
    next()
  return

module.exports = AmdClientResource
