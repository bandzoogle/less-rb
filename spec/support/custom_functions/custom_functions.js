module.exports = {
	registerCustomFunctions: function (less, functionRegistry) {
		functionRegistry.add('double', function(value) {
			return new less.tree.Dimension(value.value * 2);
		});
	}
};
