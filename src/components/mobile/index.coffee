'use strict'
import twemoji from 'twemoji'
import Utils from '@/assets/scripts/utils'

class SendWS
	constructor: (@ws, @socket, data) ->
		unless @send data
			@handle = setInterval (=> @send data), 20
	send: (data) ->
		return 0 unless @socket?.readyState is 1
		clearInterval @handle
		# 发送数据
		@ws.send.apply @ws, data
		@ws = null
		@socket = null
		return 1

# 解决安卓手机输入框被软键盘遮住的问题
if /Android [4-6]/.test navigator.appVersion
    window.addEventListener 'resize', ->
        if /^(INPUT|TEXTAREA)$/.test document.activeElement.tagName
            setTimeout ->
                document.activeElement.scrollIntoViewIfNeeded()
            , 0

export default
	data: ->
		reconnectCount: -1
		# tab-box 显示的内容
		name: '客服代表'
		# 是否主动关闭 WS
		closingActively: 0
		# 排队系统 前面排的人数
		queueNum: 0
		# 输入的文本
		inputText: ''
		# 是否准备输入（输入框是否获取焦点）
		isReadyToType: 0
		# 是否正在加载历史数据的状态
		isLoadingHistory: 0
		# 是否需要确认结束当前对话
		confirmToClose: 0
		# 是否无更多历史消息的状态
		noMoreHistory: 0
		# 首屏消息条数
		msgInitCount: 20
		# 非首屏消息条数
		msgAppendCount: 20
		# 新推送的未读消息 element 引用列表（顺序无所谓）
		newUnreadElList: []
		# 历史消息列表中第一条数据的timeStamp
		referTimeStamp: 0
		# 历史消息数据列表（新数据在后）
		chatHistoryList: []
		# Stomp 连接（WebSocket
		ws: null
		# 当前用户ID
		userId: null
		# 会话是否已关闭
		isClosed: false
		# 是否弹框
		popup: 0
		# 访客信息
		visitorInfo: []
		# 访客引导语
		visitorMsg: ''
		form:
			name: ''
			phone: ''

		twemoji: ALPHA.twemoji
		emojiPickerState: 0

	computed:
		# 新推送的未读消息条数
		newUnreadCount: -> @newUnreadElList.length

	filters:
		# 历史消息区 消息 class 类名（区分己方/对方）
		sideClass: (side) ->
			switch side
				when 1
					'msg-opposite'
				when 2
					'msg-self'

		# 计算未读消息个数（超过99，则显示99+）
		calcUnReadCount: (n) ->
			return "#{ n }" if n < 99
			'99+'
		# 消息时间线
		timeline: (stamp) ->
			date = new Date stamp
			today = new Date()
			M = date.getMonth() + 1
			M = if (M + '').length > 1 then M else '0' + M
			d = date.getDate()
			d = if (d + '').length > 1 then d else '0' + d
			H = date.getHours()
			H = if (H + '').length > 1 then H else '0' + H
			m = date.getMinutes()
			m = if (m + '').length > 1 then m else '0' + m
			s = date.getSeconds()
			s = if (s + '').length > 1 then s else '0' + s
			if today.getMonth() is date.getMonth() and today.getDate() is date.getDate()
				"#{ H }:#{ m }:#{ s }"
			else
				"#{ M }-#{ d } #{ H }:#{ m }:#{ s }"

	created: ->
		window.x = @
		# 来源地址
		origin = Utils.getUrlParams().origin
		if origin
			origin = decodeURIComponent origin
		else
			origin = ''

		# 初始化数据
		Utils.ajax ALPHA.API_PATH.user.init,
			method: 'POST'
			data:
				channel: 0
				origin: origin
		.then (res) =>
			data = res.data
			ALPHA.userId = @userId = data.userId
			@popup = popup = +data.popup
			unless popup
				# 创建 WebSocket 连接
				@connectWSLink()
				# 加载首屏历史消息数据
				@fetchHistory 1
			else
				@visitorMsg = data.msg
				@visitorInfo = data.info
				for item in @visitorInfo
					if item.filed is "name"
						item.maxLenth = 16
					if item.filed is "phone"
						item.maxLenth = 11


		# 如页面被关闭，关闭 WebSocket 连接
		window.addEventListener 'unload', =>
			@closingActively = 1
			@socket?.close()
			@ws?.disconnect()

	methods:
		# 建立 WebSocket 连接
		connectWSLink: ->
			@socket?.close()
			@ws?.disconnect()
			@socket = socket = new SockJS ALPHA.API_PATH.WS.url
			@ws = ws = Stomp.over socket
			# 断线重连机制
			socket.addEventListener 'close', =>
				if ++@data.reconnectCount > 10
					alert '网络连接失败，请刷新重试'
				else
					setTimeout =>
						@connectWSLink() unless @closingActively
					, 1000
			ws.connect {}, (frame) =>
				# 添加监听
				ws.subscribe ALPHA.API_PATH.WS.p2p, @monitorP2P

		###
		 # @params SEND_CODE <int> 发送消息类型。严禁直接传值，要用枚举：ALPHA.API_PATH.WS.SEND_CODE（备注：1: 发送消息，2: 客服接单，3: 消息已读
		 # @params message <JSON String> 消息体。只在 SEND_CODE 为 1 时存在
		###
		wsSend: (SEND_CODE, message) ->
			new SendWS @ws, @socket, [ALPHA.API_PATH.WS.send, {}, "#{ SEND_CODE }|#{ message or '' }"]

		# 监听 点对点
		monitorP2P: (res) ->
			body = res.body
			console.log 'RECEIVE: ', body
			# 消息类型
			type = +body.match(/^(\d+)\|/)[1]
			body = body.replace /^\d+\|/, ''
			switch type
				when ALPHA.API_PATH.WS.RECEIVE_CODE.p2p.MESSAGE
					## 1: 消息推送
					## 1|message Object|
					body = body.replace /\|$/, ''
					msg = body.toJSON()
					# 追加消息
					@addMessage msg
				when ALPHA.API_PATH.WS.RECEIVE_CODE.p2p.QUEUENUM
					## 4: 排队系统 前面排的人数
					## 4|num|
					body = body.replace /\|$/, ''
					@queueNum = +body
				when ALPHA.API_PATH.WS.RECEIVE_CODE.p2p.CLOSED
					## 5: 会话已结束
					## 5||
					@isClosed = true
					# 滚动到最底部
					@$nextTick => @scrollToBottom()

		# Event: 结束当前对话
		eventCloseTheChat: ->
			@confirmToClose = 1

		# 结束当前对话
		closingTheChat: ->
			if Utils.isApp()
				if Utils.isAndroid()
					javascript:js2android.closeTalking()
				else
					window.webkit.messageHandlers.closeTalking()
			else
				window.close()

		# 获取历史消息数据
		fetchHistory: (isReset) ->
			return if @isLoadingHistory
			# 更改是否正在加载历史数据的状态
			@isLoadingHistory = 1

			## 请求参数
			params = {}
			# 请求的消息条数
			if isReset
				params.size = @msgInitCount
			else
				params.size = @msgAppendCount
			# 目前最前面的那条消息的 timestamp（非首屏）
			params.timestamp = @referTimeStamp unless isReset

			# 发起请求
			promise = Utils.ajax ALPHA.API_PATH.user.history,
				params: params
			promise.then (data) =>
				list = data.data
				unless list.length
					## 无更多数据
					# 更改是否正在加载历史数据的状态
					@isLoadingHistory = 0
					# 无更多数据的状态
					@noMoreHistory = 1
					return

				# 新请求来的消息条数
				newMsgCount = list.length

				# 追加数据（包含首屏数据的情况）
				@chatHistoryList = [...list, ...@chatHistoryList]
				# 刷新 timeline 的数据
				@refreshTimeline()

				# 更改是否正在加载历史数据的状态
				@isLoadingHistory = 0
				if isReset
					## 首屏时，滚动到最底部
					@$nextTick =>
						# 滚动到最底部
						@scrollToBottom 0
				else
					## 非首屏时，保持当前窗口中的可视消息位置
					els = [].slice.apply @$refs.chatWrapper.children
					h = 0
					for i in [0..newMsgCount]
						el = els[i]
						break unless el
						h += el.offsetHeight
					@$refs.chatWindow.scrollTop = h

		# 刷新 timeline 的数据
		refreshTimeline: ->
			list = @chatHistoryList
			return unless list.length
			# 刷新 referTimeStamp
			@referTimeStamp = list[0].timeStamp
			multiple = 0
			for item, i in list
				unless i
					item.hasTimeline = 1
					continue
				# 5 为 5分钟
				tempMultiple = ~~( (item.timeStamp - @referTimeStamp) / (5 * 60 * 1000) )
				if tempMultiple > multiple
					item.hasTimeline = 1
					multiple = tempMultiple
				else
					item.hasTimeline = 0

		# 历史消息滚动到指定位置
		scrollTo: (targetY = 0, duration = 200) ->
			@$refs.chatWindow.velocity scrollTop: "#{ targetY }px", {duration: duration}

		# 历史消息滚动到最底部
		scrollToBottom: (duration = 200) ->
			# window element
			win = @$refs.chatWindow
			# window height
			winH = win.offsetHeight
			# content height
			conH = @$refs.chatWrapper.offsetHeight
			# difference value
			diff = conH - winH
			return if diff < 0
			win.velocity('finish').velocity scrollTop: "#{ diff + 20 }px", {duration: duration}

		# 历史消息区当前位置是否位于最底部
		isLocateBottom: ->
			# window element
			win = @$refs.chatWindow
			# window height
			winH = win.offsetHeight
			# content height
			conH = @$refs.chatWrapper.offsetHeight
			# difference value
			diff = conH - winH
			# 如果内容没满一屏
			return 1 if diff < 0

			# all chat element list
			allEls = [].slice.apply @$refs.chatWrapper.children
			# the last chat element
			el = allEls.last()

			# 备注：
			# 9:	.msg-self/.msg-opposite padding-top/padding-bottom
			# 34/2	.msg-bubble half height

			# window scrollTop
			sT = win.scrollTop
			# total height
			tH = @$refs.chatWrapper.offsetHeight

			return sT + winH > tH - 9 - 34 / 2

		# Event: 消息发送事件
		eventSend: ->
			return unless @inputText.trim()
			# 转义（防xss）
			text = @inputText.encodeHTML()
			# 发送消息体（messageType 1: 文字 2: 图片）
			sendBody = messageType: 1, message: text
			# 发送消息
			@wsSend ALPHA.API_PATH.WS.SEND_CODE.MESSAGE, JSON.stringify sendBody
			# 清空消息框
			@inputText = ''

		createEmoji: (emoji) ->
			emoji = String.fromCodePoint "0x#{ emoji }"
			twemoji.parse emoji, ALPHA.twemoji.params

		# 向输入框插入表情，并关闭表情选择面板
		insertEmoji: (emoji) ->
			# 向输入框追加表情
			@inputText += "[/#{ emoji }]" unless @isClosed
			# 关闭表情选择面板
			@emojiPickerState = 0
			# 使输入框获取焦点
			@$nextTick =>
				@$refs.input.focus()


		# Event: 历史消息列表滚动事件
		eventScrollHistory: ->
			return if @noMoreHistory

			# 频率控制器
			return if @winScrollState
			@winScrollState = 1
			setTimeout (=> @winScrollState = 0), 20

			# window element
			win = @$refs.chatWindow
			# 备注：
			# 12:	.chat-content padding-top
			# 14:	.time-line height
			# 9:	.msg-self/.msg-opposite padding-top
			# 34/2	.msg-bubble half height
			# 消息顶部距离文字中间的高度（不包含timeline）
			cH = 12 + 9 + 34 / 2
			# .time-line height
			tT = 14
			# window scrollTop
			sT = win.scrollTop

			## 处理 newUnreadElList
			@newUnreadElList = [] if @isLocateBottom()

			## 获取更多历史消息数据
			@fetchHistory() if sT < cH + tT

		# Event: 显示下面的未读消息点击事件
		eventShowLowerUnread: ->
			# 清空 新推送的未读消息
			@clearNewUnread()
			# 滚动到底部
			@scrollToBottom()

		# 清空 新推送的未读消息
		clearNewUnread: ->
			# 清空 新推送的未读消息 element 引用列表
			@newUnreadElList = []

		# 服务器推送来的消息（包括己方发送的消息）
		addMessage: (msg) ->
			list = @chatHistoryList
			# 刷新 timeline 的数据
			@refreshTimeline()
			@chatHistoryList = [...list, msg]
			if msg.sendType is 2
				# 己方消息，滚动到底部
				@$nextTick => @scrollToBottom 80
			else
				if @isLocateBottom()
					@$nextTick => @scrollToBottom()
				else
					# 对方消息，追加到 newUnreadElList
					@newUnreadElList.push msg

		# Event: 发送图片
		eventSendPic: (event) ->
			target = event.target
			file = target.files[0]

			# 限制图片大小 小于 10Mb
			if file.size / 1024 / 1024 > 10
				# 弹出提示
				vm.$notify
					type: 'warning'
					title: '图片发送失败'
					message: "图片大小不可超过10Mb"
				return

			###
			# 此段注释代码是不依赖网络，将图片直接显示在历史消息里，并方便加上 loading 状态的功能
			reader = new FileReader()
			reader.addEventListener 'load', (event) ->
				data = target.result
				image = new Image()
				# 加载图片获取图片的宽高
				image.addEventListener 'load', (event) ->
					w = image.width
					h = image.height
				image.src = data
			reader.readAsDataURL file
			###

			formData = new FormData()
			formData.append 'multipartFile', file
			# 发起请求
			@axios.post ALPHA.API_PATH.common.upload, formData, headers: 'Content-Type': 'multipart/form-data'
			.then (res) =>
				console.log res.data
				if res.msg is 'success'
					fileUrl = res.data.fileUrl

					# 发送消息体（messageType 1: 文字 2: 图片）
					sendBody = messageType: 2, message: fileUrl
					# 发送消息
					@wsSend ALPHA.API_PATH.WS.SEND_CODE.MESSAGE, JSON.stringify sendBody
			# 清空 value，否则重复上传同一个文件不会触发 change 事件
			target.value = ''
		# 渲染消息
		renderMessage: (msg) ->
			return '' unless msg and msg.message
			switch msg.messageType
				when 1
					# 文本消息
					text = msg.message
					text = text.replace /\n|\ /g, (char) ->
						switch char
							when '\n'
								'<br/>'
							when ' '
								'&nbsp;'
							else
								char
					# processing emoji
					text = text.replace /\[\/\w+\]/g, (face) ->
						emoji = String.fromCodePoint "0x#{ face.match(/\[\/(\w+)\]/)[1] }"
						twemoji.parse emoji
					text.encodeHTML()
				when 2
					# 图片
					"""
						<a href="/#{ msg.message.encodeHTML() }" target="_blank">
							<img src="/#{ msg.message.encodeHTML() }" />
						</a>
					"""

		# Event: 立即咨询点击事件
		eventStartChatting: ->
			Utils.ajax ALPHA.API_PATH.user.new,
				method: 'POST'
				data: @form
			.then (res) =>
				@popup = 0
				# 创建 WebSocket 连接
				@connectWSLink()
				# 加载首屏历史消息数据
				@fetchHistory 1

		# Event: 手机号 keydown
		eventKeydownPhoneNum: (event) ->
			keyCode = event.keyCode
			return if keyCode is 8
			event.preventDefault() unless keyCode in [48..57].concat [96..105]
			event.preventDefault() if @form.phone.length > 10
