// add the functions that functions.less test expects to be exposed, see runner-main-options.js
module.exports = {
  registerCustomFunctions: function (less, functionRegistry) {
    functionRegistry.addMultiple({
      add: function(a, b) {
        return new less.tree.Dimension(a.value + b.value);
      },

      increment: function(a) {
        return new less.tree.Dimension(a.value + 1);
      },

      _color: function(str) {
        if(str.value == 'evil red') {
          return new less.tree.Color('600')
        }
      }
    })
  }
};
