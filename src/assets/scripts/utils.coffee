import md5 from 'md5'
class Utils
	'use strict'
	###
	 # clone 对象
	 # @param obj [Object] 必填。将要 clone 的对象
	###
	@clone: (obj, isDeep = 0) ->
		return obj unless typeof obj is 'object' and obj?
		if obj instanceof Date
			re	= new Date()
			re.setTime obj.getTime()
			return re
		re	= if obj instanceof Array then [] else {}
		for own o, val of obj
			if isDeep and typeof val is 'object'
				re[o]	= @clone val
			else
				re[o]	= val
		re

	###
	 # 获取 url 参数
	###
	@getUrlParams: ->
		data = {}
		params = location.search
		return data unless params
		params = location.search.slice(1).split '&'
		for item in params
			temp = item.split '='
			data[temp[0]] = temp[1]
		data

	@isApp: -> Utils.getUrlParams().hasOwnProperty 'isApp'

	@isAndroid: -> /Android|Linux/.test navigator.userAgent

	###
	 # 封装的 axios
	 #
	 # 调用方式：
	 # Utils.ajax <api-path>
	 # 注：当前函数已在 main 里修改上下文环境，调用时不需要再使用 call
	 #
	 # 可通过调用返回值（即 Promise 实例）下的 abort 函数来 abort 当前请求
	 # e.g.:
	 # promise = Utils.ajax '/xxx'
	 # promise.abort()	# abort 当前请求
	###
	@ajax: (api, data) ->
		abort = null
		config =
			cancelToken: new @axios.CancelToken (fun) => abort = fun
		Object.assign config, data
		# 签名（非 /common 或 /user 开头的接口
		unless /^(\/api)?\/(common|user)/.test api
			key = 'data'
			key = 'params' if not config.method or new RegExp(/GET|DELETE/, 'i').test config.method

			timestamp = +ALPHA.serverTime
			config.headers =
				timestamp: timestamp
		# 发起请求
		promise = @axios api, config
		# 注册 abort 函数到当前 Promise 实例上
		promise.abort = abort
		# 返回当前 Promise 实例
		promise

	# 计算 element offset top
	@calcOffsetTop = (element) =>
		actualTop = 0
		loop
			actualTop += element.offsetTop
			break unless element = element.offsetParent
		actualTop

#****************************** 内部函数 ******************************#

###
 # 获得指定日期、时间规范格式<yyyy-MM-dd>|<HH:mm:ss>|<yyyy-MM-dd HH:mm:ss>的字符串
 # @param param [Object] 选填。JSON对象。
 # @param param - date [Date] 选填。欲格式化的Date类型的数据。如为空，则默认当前日期。
 # @param param - hasDate [Boolean] 选填。返回的规范化字符串带有“日期”。
 # @param param - hasTime [Boolean] 选填。返回的规范化字符串带有“时间”。
 # @param param - forward [Number] 选填。提前的天数。支持0和负整数。如果调用时带有此参数，将返回一个包含两个元素的数组，第一个日期早于第二个日期。
 # 注：此函数是用来追加到Date prototype的，不能直接调用。
###
_formatDate = (param) ->
	date = param['date'] or @
	y	 = date.getFullYear()
	M	 = date.getMonth() + 1
	M	 = if (M + '').length > 1 then M else '0' + M
	d	 = date.getDate()
	d	 = if (d + '').length > 1 then d else '0' + d
	H	 = date.getHours()
	H	 = if (H + '').length > 1 then H else '0' + H
	m	 = date.getMinutes()
	m	 = if (m + '').length > 1 then m else '0' + m
	s	 = date.getSeconds()
	s	 = if (s + '').length > 1 then s else '0' + s
	hD	 = param.hasDate
	hT	 = param.hasTime
	rD	 = if hD then (y + '-' + M + '-' + d) else ''
	rT	 = if hT then (H + ':' + m + ':' + s) else ''
	re	 = "#{ rD }#{ if hD and hT then ' ' else '' }#{ rT }"
	date = undefined
	re

###
 # 获得指定月份第一天的规范格式<yyyy-MM-dd>的字符串
 # @param date [Date/String] 必填。指定月份的Date对象或可以转换成Date对象的字符串
###
_firstDayOfMonth = (date) ->
	date = new Date date if typeof date is 'string'
	new Date date.setDate(1)
	
###
 # 获得指定月份最后一天的规范格式<yyyy-MM-dd>的字符串
 # @param date [Date/String] 必填。指定月份的Date对象或可以转换成Date对象的字符串
###
_lastDayOfMonth = (date) ->
	date = new Date date if typeof date is 'string'
	date = new Date date.setDate(1)
	re	 = date.setMonth(date.getMonth() + 1) - 1 * 24 * 60 * 60 * 1000
	new Date re

#****************************** 修改原型 ******************************#

###
 # 获取格式化日期：2000-01-01
###
Date::getFormatDate = (date = @) ->
	_formatDate.call @, {date: date, hasDate: 1}

###
 # 获取格式化时间：00:00:00
###
Date::getFormatTime = (date = @) ->
	_formatDate.call @, {date: date, hasTime: 1}

###
 # 获取格式化日期+时间：2000-01-01 00:00:00
###
Date::getFormatDateAndTime = (date = @) ->
	_formatDate.call @, {date: date, hasDate: 1, hasTime: 1}

###
 # 获取指定月份第一天的格式化日期：2000-01-01
 # @param date [Date/String]
###
Date::firstDayOfMonth = (date = @) ->
	_firstDayOfMonth.call @, date

###
 # 获取指定月份最后一天的格式化日期：2000-01-31
 # @param date [Date/String]
###
Date::lastDayOfMonth = (date = @) ->
	_lastDayOfMonth.call @, date

###
 # 获取 n 天前的日期（n 可为负）
###
Date::beforeDays = (n, date = @) ->
	new Date date.getTime() - n * 1000 * 60 * 60 * 24

###
 # 获取 n 天后的日期（n 可为负）
###
Date::afterDays = (n, date = @) ->
	new Date date.getTime() + n * 1000 * 60 * 60 * 24

###
 # 获取 n 个月前的日期（n 可为负）
###
Date::beforeMonths = (n, date = @) ->
	new Date date.setMonth date.getMonth() - n

###
 # 获取 n 天后的日期（n 可为负）
###
Date::afterMonths = (n, date = @) ->
	new Date date.setMonth date.getMonth() + n

###
 # String: String 转 JSON Object
###
String::toJSON = -> JSON.parse @

###
 # String: 去前后空格
###
String::trim = -> @replace /(^\s*)|(\s*$)/g, ''

###
 # 处理md5库
###
String::md5 = -> md5.apply null, [@].concat [].slice.apply arguments

###
 # 将 $、<、>、"、'，与 / 转义成 HTML 字符
 # 用于防 xss 攻击
###
String::encodeHTML = (encodeAll) ->
	return @ unless @
	encodeHTMLRules =
		"&": "&#38;"
		"<": "&#60;"
		">": "&#62;"
		'"': '&#34;'
		"'": '&#39;'
		"/": '&#47;'
	unless encodeAll
		matchHTML = /<\/?\s*(script|iframe)[\s\S]*?>/gi
		str	= @replace matchHTML, (m) ->
			switch true
				when /script/i.test m
					s	= 'script'
				when /iframe/i.test m
					s	= 'iframe'
				else
					s	= ''
			"#{ encodeHTMLRules['<'] }#{ if -1 is m.indexOf '/' then '' else encodeHTMLRules['/'] }#{ s }#{ encodeHTMLRules['>'] }"
		return str.replace /on[\w]+\s*=/gi, ''
	else
		matchHTML = /&(?!#?\w+;)|<|>|"|'|\//g
		return @replace matchHTML, (m) -> encodeHTMLRules[m] or m

###
 # Array: 判断当前 array 中是否存在指定元素
###
Array::has = (obj) -> @indexOf(obj) isnt -1

###
 # Array: 获取最后一个元素
###
Array::last = -> @[@length - 1]
###
 # Array: 移除参数中的元素
###
Array::remove = (obj) ->
	i	= @.indexOf obj
	return null if i is -1
	@.splice(i, 1)[0]
	return @length

window.Utils = Utils
export default Utils