function render(source, options) {
	clearTimeout(compileTimer);
	var less = require('less-node/index');
	if(options.custom_functions) {
		var customFunctions = require(options.custom_functions);
		customFunctions.registerCustomFunctions(less, less.functions.functionRegistry);
	}
	try {
		less.render(source, options, callback)
	} catch(err) {
		callback(err);
	}
}

//
// Bit of a hack, our custom runner doesn't generate status until the callback is
// called, but ExecJS::ExternalRuntime calls `exec` when given a source to compile
// and that fails if no status is received.
//
// So we setup a timeout to call the callback in this scenario, which calls to render
// clear to ensure that both the `compile` & `call` work without modifications
// to ExecJS behaviour
//
var compileTimer = setTimeout(callback, 1);
