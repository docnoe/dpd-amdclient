# dpd-amdclient

Plugin for Deployd. If you don't use Deployd, go get it! (Or leave and never come back! ;))

### Installation

Install nodejs if you haven't done so, yet.

	npm i -S dpd-amdclient

### Usage

From your Deployd dashboard click the "+" to add a new collection and choose "Amd client".

In the frontend you can now require the new dpd.js from */amd/dpd.js*. So the path in your require configuration would look something like this:

	paths: [
		dpd: "amd/dpd"
	]

### Dependencies!

dpd.js depends on socket.io and ayepromise. Make sure to install and require these, too!