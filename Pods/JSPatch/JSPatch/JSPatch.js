var global = this

;(function() { // 匿名函数立即执行

  var _ocCls = {}; // 通过类名存类方法和实例方法 key：className  value: (instMethods: {}, clsMethods: {},)
  var _jsCls = {};

  var _formatOCToJS = function(obj) { // 格式转换：
    if (obj === undefined || obj === null) return false
    if (typeof obj == "object") {
      if (obj.__obj) return obj
      if (obj.__isNil) return false
    }
    if (obj instanceof Array) {
      var ret = []
      obj.forEach(function(o) {
        ret.push(_formatOCToJS(o)) // 递归调用每个元素
      })
      return ret
    }
    if (obj instanceof Function) {
        return function() {
            var args = Array.prototype.slice.call(arguments) // 将参数转换为数组
            var formatedArgs = _OC_formatJSToOC(args)
            for (var i = 0; i < args.length; i++) {
                if (args[i] === null || args[i] === undefined || args[i] === false) {
                formatedArgs.splice(i, 1, undefined)
            } else if (args[i] == nsnull) {
                formatedArgs.splice(i, 1, null)
            }
        }
        return _OC_formatOCToJS(obj.apply(obj, formatedArgs))
      }
    }
    if (obj instanceof Object) {
      var ret = {}
      for (var key in obj) {
        ret[key] = _formatOCToJS(obj[key])
      }
      return ret
    }
    return obj
  }
  
  // 方法调用，通过调用oc方法调用方法，获取返回值
  var _methodFunc = function(instance, clsName, methodName, args, isSuper, isPerformSelector) {
    var selectorName = methodName
    if (!isPerformSelector) { // 如果不是performselector，用正则对selectorName进行字符替换：__ 替换 -，- 替换 _，有':', 在最后添加上':'
      methodName = methodName.replace(/__/g, "-") // __ 替换 -
      selectorName = methodName.replace(/_/g, ":").replace(/-/g, "_") // - 替换 _
      var marchArr = selectorName.match(/:/g) // 有':', 在最后添加上':'
      var numOfArgs = marchArr ? marchArr.length : 0
      if (args.length > numOfArgs) {
        selectorName += ":"
      }
    }
    var ret = instance ? _OC_callI(instance, selectorName, args, isSuper):
                         _OC_callC(clsName, selectorName, args) // 调用oc的生成方法：实例方法还是类方法
    return _formatOCToJS(ret)
  }

  var _customMethods = { // 字典对象，存 __c: function
    __c: function(methodName) {
      var slf = this

      if (slf instanceof Boolean) {
        return function() {
          return false
        }
      }
      if (slf[methodName]) {
        return slf[methodName].bind(slf);
      }

      if (!slf.__obj && !slf.__clsName) { // 未定义抛出异常
        throw new Error(slf + '.' + methodName + ' is undefined')
      }
      if (slf.__isSuper && slf.__clsName) { // 如果是调用父类方法
          slf.__clsName = _OC_superClsName(slf.__obj.__realClsName ? slf.__obj.__realClsName: slf.__clsName); // 通过调用oc的[cls superclass] 方法获取父类的名字
      }
      var clsName = slf.__clsName
      if (clsName && _ocCls[clsName]) { // 有缓存，返回缓存的方法
        var methodType = slf.__obj ? 'instMethods': 'clsMethods'  // 通过__obj判断是实例方法还是类方法
        if (_ocCls[clsName][methodType][methodName]) {
          slf.__isSuper = 0;
          return _ocCls[clsName][methodType][methodName].bind(slf) // 返回的是之前缓存的方法
        }
      }

      return function(){
        var args = Array.prototype.slice.call(arguments) // 转换成数组， arguments 方法调用的参数
        return _methodFunc(slf.__obj, slf.__clsName, methodName, args, slf.__isSuper) // 返回方法调用的结果
      }
    },

    super: function() {
      var slf = this
      if (slf.__obj) {
        slf.__obj.__realClsName = slf.__realClsName;
      }
      return {__obj: slf.__obj, __clsName: slf.__clsName, __isSuper: 1}
    },

    performSelectorInOC: function() {
      var slf = this
      var args = Array.prototype.slice.call(arguments)
      return {__isPerformInOC:1, obj:slf.__obj, clsName:slf.__clsName, sel: args[0], args: args[1], cb: args[2]}
    },

    performSelector: function() {
      var slf = this
      var args = Array.prototype.slice.call(arguments)
      return _methodFunc(slf.__obj, slf.__clsName, args[0], args.splice(1), slf.__isSuper, true)
    }
  }

  for (var method in _customMethods) { // __c
    if (_customMethods.hasOwnProperty(method)) {
      // Object.defineProperty() 方法会直接在一个对象上定义一个新属性，或者修改一个对象的现有属性， 并返回这个对象。
      // Object.prototype 属性表示 Object 的原型对象。
      Object.defineProperty(Object.prototype, method, {value: _customMethods[method], configurable:false, enumerable: false})
    }
  }

  var _require = function(clsName) { //global[clsName]： {__clsName: 类名}
    if (!global[clsName]) {
      global[clsName] = {
        __clsName: clsName
      }
    } 
    return global[clsName]
  }

  global.require = function() {
    var lastRequire
    for (var i = 0; i < arguments.length; i ++) {
      arguments[i].split(',').forEach(function(clsName) {
        lastRequire = _require(clsName.trim())
      })
    }
    return lastRequire
  }
  
  // 格式化类的方法（实例方法，类方法）
  var _formatDefineMethods = function(methods, newMethods, realClsName) {
    for (var methodName in methods) {
      if (!(methods[methodName] instanceof Function)) return; // 如果方法是Function类型直接返回
      (function(){
        var originMethod = methods[methodName]
        newMethods[methodName] = [originMethod.length, function() {
          try {
            var args = _formatOCToJS(Array.prototype.slice.call(arguments))
            var lastSelf = global.self
            global.self = args[0]
            if (global.self) global.self.__realClsName = realClsName
            args.splice(0,1) // 删除第一个元素
            var ret = originMethod.apply(originMethod, args)
            global.self = lastSelf
            return ret
          } catch(e) {
            _OC_catch(e.message, e.stack)
          }
        }]
      })()
    }
  }
  
  // 包装js func
  var _wrapLocalMethod = function(methodName, func, realClsName) {
    return function() {
      var lastSelf = global.self
      global.self = this
      this.__realClsName = realClsName
      var ret = func.apply(this, arguments)
      global.self = lastSelf
      return ret
    }
  }
  
  // 设置JS方法，将写的JS代码包装成
  /*
  function () {
  var lastSelf = global.self
  global.self = this
  this.__realClsName = realClsName
  var ret = func.apply(this, arguments)
  global.self = lastSelf
  return ret
  } = $9
  */
  var _setupJSMethod = function(className, methods, isInst, realClsName) {
    for (var name in methods) {
      var key = isInst ? 'instMethods': 'clsMethods',
          func = methods[name]
      _ocCls[className][key][name] = _wrapLocalMethod(name, func, realClsName)
    }
  }

  var _propertiesGetFun = function(name){ // 调用OC的set方法，使用的是Runtime的 关联对象方法
    return function(){
      var slf = this;
      if (!slf.__ocProps) {
        var props = _OC_getCustomProps(slf.__obj) // 使用的是OC中runtime 关联对象方法
        if (!props) {
          props = {}
          _OC_setCustomProps(slf.__obj, props) // 使用的是OC中runtime 关联对象方法
        }
        slf.__ocProps = props;
      }
      return slf.__ocProps[name];
    };
  }

  var _propertiesSetFun = function(name){ // 调用OC的get方法
    return function(jval){
      var slf = this;
      if (!slf.__ocProps) {
        var props = _OC_getCustomProps(slf.__obj)
        if (!props) {
          props = {}
          _OC_setCustomProps(slf.__obj, props)
        }
        slf.__ocProps = props;
      }
      slf.__ocProps[name] = jval;
    };
  }

  // JS 方法替换 入口函数：
  // declaration: 类名，父类，协议的描述，cls:supercls<protocol..>
  // properties: { 方法名：JS的方法实现 }
  // instMethods
  global.defineClass = function(declaration, properties, instMethods, clsMethods) {
    var newInstMethods = {}, newClsMethods = {}
    if (!(properties instanceof Array)) { // properties 不是数组，是字典类型： {方法名：方法体}，直接赋值给 instMethods，然后置空
      clsMethods = instMethods
      instMethods = properties
      properties = null
    }

    /*
     逻辑：如果是属性那么使用数组[property1,property2], 再动态获取set，get方法然后放到instMethods字典中，也就是instMethods中存的是{方法名：方法实现}
     */
    if (properties) { // 此时 properties 应该是数组，那么处理OC属性Property相关，
      properties.forEach(function(name){
        if (!instMethods[name]) {
          instMethods[name] = _propertiesGetFun(name); // 设置property的get方法
        }
        var nameOfSet = "set"+ name.substr(0,1).toUpperCase() + name.substr(1); // set方法
        if (!instMethods[nameOfSet]) {
          instMethods[nameOfSet] = _propertiesSetFun(name); // 设置property的set方法
        }
      });
    }
  
    // 获取真实的类名
    var realClsName = declaration.split(':')[0].trim()  // split 把一个字符串分割成字符串数组

  // 格式化 类方法，实例方法，将方法封装成数组 [1, function()]， 1 为 originMethod.length（var originMethod = methods[methodName] ）, function()方法对之前的方法进行了封装
    _formatDefineMethods(instMethods, newInstMethods, realClsName)
    _formatDefineMethods(clsMethods, newClsMethods, realClsName)

    var ret = _OC_defineClass(declaration, newInstMethods, newClsMethods) // oc构造类，返回类名，父类名 返回值：@{@"cls": className, @"superCls": superClassName};
    var className = ret['cls']
    var superCls = ret['superCls']

    _ocCls[className] = {
      instMethods: {},
      clsMethods: {},
    }

    if (superCls.length && _ocCls[superCls]) {
      for (var funcName in _ocCls[superCls]['instMethods']) { // 如果父类中有这个实例方法，直接赋值给当前类
        _ocCls[className]['instMethods'][funcName] = _ocCls[superCls]['instMethods'][funcName]
      }
      for (var funcName in _ocCls[superCls]['clsMethods']) {  // 如果父类中有这个类例方法，直接赋值给当前类
        _ocCls[className]['clsMethods'][funcName] = _ocCls[superCls]['clsMethods'][funcName]
      }
    }
  
    // className: OC定义的类名，instMethods：实例方法{方法名：方法实现}，instMethods:解析declaration获取的真实类名
    // 对js代码进行了一次包装，_wrapLocalMethod
    _setupJSMethod(className, instMethods, 1, realClsName)
    _setupJSMethod(className, clsMethods, 0, realClsName)

    return require(className) // 返回的是： {__clsName: 类名}
  }

  global.defineProtocol = function(declaration, instProtos , clsProtos) {
      var ret = _OC_defineProtocol(declaration, instProtos,clsProtos);
      return ret
  }

  global.block = function(args, cb) {
    var that = this
    var slf = global.self
    if (args instanceof Function) {
      cb = args
      args = ''
    }
    var callback = function() {
      var args = Array.prototype.slice.call(arguments)
      global.self = slf
      return cb.apply(that, _formatOCToJS(args))
    }
    var ret = {args: args, cb: callback, argCount: cb.length, __isBlock: 1}
    if (global.__genBlock) {
      ret['blockObj'] = global.__genBlock(args, cb)
    }
    return ret
  }
  
  if (global.console) {
    var jsLogger = console.log;
    global.console.log = function() {
      global._OC_log.apply(global, arguments);
      if (jsLogger) {
        jsLogger.apply(global.console, arguments);
      }
    }
  } else {
    global.console = {
      log: global._OC_log
    }
  }

  global.defineJSClass = function(declaration, instMethods, clsMethods) {
    var o = function() {},
        a = declaration.split(':'),
        clsName = a[0].trim(),
        superClsName = a[1] ? a[1].trim() : null
    o.prototype = {
      init: function() {
        if (this.super()) this.super().init()
        return this;
      },
      super: function() {
        return superClsName ? _jsCls[superClsName].prototype : null
      }
    }
    var cls = {
      alloc: function() {
        return new o;
      }
    }
    for (var methodName in instMethods) {
      o.prototype[methodName] = instMethods[methodName];
    }
    for (var methodName in clsMethods) {
      cls[methodName] = clsMethods[methodName];
    }
    global[clsName] = cls
    _jsCls[clsName] = o
  }
  
  global.YES = 1
  global.NO = 0
  global.nsnull = _OC_null
  global._formatOCToJS = _formatOCToJS
  
})()
