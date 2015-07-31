path = require 'path'
util = require 'util'
fs = require 'fs'
_ = require 'lodash'
mkdirp = require 'mkdirp'


streamBuffers = require 'stream-buffers'
requirejs = require 'requirejs'

Resource = require path.normalize "#{require.main.paths[0]}/deployd/lib/resource"
ClientLib = require path.normalize "#{require.main.paths[0]}/deployd/lib/resources/client-lib"

client = null
resourcesOnStart = null

mkdirp path.normalize "#{__dirname}/clib/amd"

requireConfig =
  baseUrl: path.normalize "#{__dirname}/clib"
  name: "amd/dpd"
  out: path.normalize "#{__dirname}/clib/dpdAmd.js"
  # optimize: "none" #uncomment for debugging
  paths:
    "ayepromise": "ayepromise.min"
    "socket.io": "socket.io.min"

generatedAmdClient = (cb) ->
  server = process.server
  client = new ClientLib('dpdAmd.js', { config: { resources: server.resources }, server: server})
  resourcesOnStart = (resource.name for resource in server.resources)

  writable = new streamBuffers.WritableStreamBuffer()
  client.generate writable, ->
    originalClib = writable.getContentsAsString("utf8")
    collectionMethods = originalClib.split("// automatically generated code")[1]
    writable.destroy()

    dpdLibPath = path.join(__dirname, 'clib/dpdOriginal.js')
    fs.readFile dpdLibPath, 'utf-8', (err, data) ->
      clibParts = data.split "// generatedCodeMarker"
      [part1, part2] = clibParts
      amdClib = "#{part1}#{collectionMethods}#{part2}"
      fs.writeFileSync path.normalize("#{__dirname}/clib/amd/dpd.js"), amdClib
      requirejs.optimize requireConfig, (buildResponse) ->
        cb() if cb

process.server.on "listening", ->
  generatedAmdClient()

class AmdClientResource
  constructor: ->
    Resource.apply this, arguments
    return

util.inherits AmdClientResource, Resource
AmdClientResource.label = "Amd client"
AmdClientResource::clientGeneration = false

AmdClientResource::handle = (ctx, next) ->
  server = process.server

  sendAmdFile = ->
    stat = fs.statSync(requireConfig.out);
    ctx.res.setHeader('Content-Type', 'text/javascript')
    ctx.res.setHeader('Content-Length', stat.size)
    readStream = fs.createReadStream(requireConfig.out);
    readStream.pipe(ctx.res);

  if ctx.method is "GET"
    unless server and server.resources
      console.log "server.resources not defined"
      next()
      return

    resources = (resourceLoop.name for resourceLoop in server.resources)
    if _.isEqual resourcesOnStart, resources
      sendAmdFile()
    else
      generatedAmdClient sendAmdFile

  else
    next()
  return

module.exports = AmdClientResource
